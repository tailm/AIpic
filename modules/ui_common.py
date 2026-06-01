import json
import html
import os
import platform
import sys

import gradio as gr
import subprocess as sp

from modules import call_queue, shared
from modules.generation_parameters_copypaste import image_from_url_text
import modules.images

folder_symbol = '\U0001f4c2'  # 📂
delete_symbol = '\U0001f5d1'  # 🗑️


def update_generation_info(generation_info, html_info, img_index):
    try:
        generation_info = json.loads(generation_info)
        if img_index < 0 or img_index >= len(generation_info["infotexts"]):
            return html_info, gr.update()
        return plaintext_to_html(generation_info["infotexts"][img_index]), gr.update()
    except Exception:
        pass
    # if the json parse or anything else fails, just return the old html_info
    return html_info, gr.update()


def plaintext_to_html(text):
    text = "<p>" + "<br>\n".join([f"{html.escape(x)}" for x in text.split('\n')]) + "</p>"
    return text


def save_files(js_data, images, do_make_zip, index):
    import csv
    filenames = []
    fullfns = []

    #quick dictionary to class object conversion. Its necessary due apply_filename_pattern requiring it
    class MyObject:
        def __init__(self, d=None):
            if d is not None:
                for key, value in d.items():
                    setattr(self, key, value)

    data = json.loads(js_data)

    p = MyObject(data)
    path = shared.opts.outdir_save
    save_to_dirs = shared.opts.use_save_to_dirs_for_ui
    extension: str = shared.opts.samples_format
    start_index = 0

    if index > -1 and shared.opts.save_selected_only and (index >= data["index_of_first_image"]):  # ensures we are looking at a specific non-grid picture, and we have save_selected_only

        images = [images[index]]
        start_index = index

    os.makedirs(shared.opts.outdir_save, exist_ok=True)

    with open(os.path.join(shared.opts.outdir_save, "log.csv"), "a", encoding="utf8", newline='') as file:
        at_start = file.tell() == 0
        writer = csv.writer(file)
        if at_start:
            writer.writerow(["prompt", "seed", "width", "height", "sampler", "cfgs", "steps", "filename", "negative_prompt"])

        for image_index, filedata in enumerate(images, start_index):
            image = image_from_url_text(filedata)

            is_grid = image_index < p.index_of_first_image
            i = 0 if is_grid else (image_index - p.index_of_first_image)

            fullfn, txt_fullfn = modules.images.save_image(image, path, "", seed=p.all_seeds[i], prompt=p.all_prompts[i], extension=extension, info=p.infotexts[image_index], grid=is_grid, p=p, save_to_dirs=save_to_dirs)

            filename = os.path.relpath(fullfn, path)
            filenames.append(filename)
            fullfns.append(fullfn)
            if txt_fullfn:
                filenames.append(os.path.basename(txt_fullfn))
                fullfns.append(txt_fullfn)

        writer.writerow([data["prompt"], data["seed"], data["width"], data["height"], data["sampler_name"], data["cfg_scale"], data["steps"], filenames[0], data["negative_prompt"]])

    # Make Zip
    if do_make_zip:
        zip_filepath = os.path.join(path, "images.zip")

        from zipfile import ZipFile
        with ZipFile(zip_filepath, "w") as zip_file:
            for i in range(len(fullfns)):
                with open(fullfns[i], mode="rb") as f:
                    zip_file.writestr(filenames[i], f.read())
        fullfns.insert(0, zip_filepath)

    return gr.File.update(value=fullfns, visible=True), plaintext_to_html(f"Saved: {filenames[0]}")


def create_output_panel(tabname, outdir):
    from modules import shared
    import modules.generation_parameters_copypaste as parameters_copypaste

    def open_folder(f):
        if not os.path.exists(f):
            print(f'Folder "{f}" does not exist. After you create an image, the folder will be created.')
            return
        elif not os.path.isdir(f):
            print(f"""
WARNING
An open_folder request was made with an argument that is not a folder.
This could be an error or a malicious attempt to run code on your computer.
Requested path was: {f}
""", file=sys.stderr)
            return

        if not shared.cmd_opts.hide_ui_dir_config:
            path = os.path.normpath(f)
            if platform.system() == "Windows":
                os.startfile(path)
            elif platform.system() == "Darwin":
                sp.Popen(["open", path])
            elif "microsoft-standard-WSL2" in platform.uname().release:
                sp.Popen(["wsl-open", path])
            else:
                sp.Popen(["xdg-open", path])

    with gr.Column(variant='panel', elem_id=f"{tabname}_results"):
        with gr.Group(elem_id=f"{tabname}_gallery_container"):
            result_gallery = gr.Gallery(label='Output', show_label=False, elem_id=f"{tabname}_gallery").style(grid=4)

        generation_info = None
        with gr.Column():
            with gr.Row(elem_id=f"image_buttons_{tabname}"):
                open_folder_button = gr.Button(folder_symbol, elem_id="hidden_element" if shared.cmd_opts.hide_ui_dir_config else f'open_folder_{tabname}')

                if tabname != "extras":
                    save = gr.Button('Save', elem_id=f'save_{tabname}')
                    save_zip = gr.Button('Zip', elem_id=f'save_zip_{tabname}')
                    delete_button = gr.Button(delete_symbol, elem_id=f'delete_{tabname}', variant='secondary')

                buttons = parameters_copypaste.create_buttons(["img2img", "inpaint", "extras"])

            open_folder_button.click(
                fn=lambda: open_folder(shared.opts.outdir_samples or outdir),
                inputs=[],
                outputs=[],
            )

            if tabname != "extras":
                with gr.Row():
                    download_files = gr.File(None, file_count="multiple", interactive=False, show_label=False, visible=False, elem_id=f'download_files_{tabname}')

                with gr.Group():
                    html_info = gr.HTML(elem_id=f'html_info_{tabname}')
                    html_log = gr.HTML(elem_id=f'html_log_{tabname}')

                    generation_info = gr.Textbox(visible=False, elem_id=f'generation_info_{tabname}')
                    if tabname == 'txt2img' or tabname == 'img2img':
                        generation_info_button = gr.Button(visible=False, elem_id=f"{tabname}_generation_info_button")
                        generation_info_button.click(
                            fn=update_generation_info,
                            _js="function(x, y, z){ return [x, y, selected_gallery_index()] }",
                            inputs=[generation_info, html_info, html_info],
                            outputs=[html_info, html_info],
                        )

                    save.click(
                        fn=call_queue.wrap_gradio_call(save_files),
                        _js="(x, y, z, w) => [x, y, false, selected_gallery_index()]",
                        inputs=[
                            generation_info,
                            result_gallery,
                            html_info,
                            html_info,
                        ],
                        outputs=[
                            download_files,
                            html_log,
                        ],
                        show_progress=False,
                    )

                    save_zip.click(
                        fn=call_queue.wrap_gradio_call(save_files),
                        _js="(x, y, z, w) => [x, y, true, selected_gallery_index()]",
                        inputs=[
                            generation_info,
                            result_gallery,
                            html_info,
                            html_info,
                        ],
                        outputs=[
                            download_files,
                            html_log,
                        ]
                    )

                    # 添加删除按钮点击事件
                    delete_button.click(
                        fn=call_queue.wrap_gradio_call(delete_image),
                        _js="(x, y, z, w) => [x, y, selected_gallery_index(), arguments[3], arguments[4]]",
                        inputs=[
                            generation_info,
                            result_gallery,
                            html_info,
                            gr.Textbox(tabname, visible=False),
                            gr.Textbox(outdir, visible=False),
                        ],
                        outputs=[
                            result_gallery,
                            html_log,
                        ]
                    )

            else:
                html_info_x = gr.HTML(elem_id=f'html_info_x_{tabname}')
                html_info = gr.HTML(elem_id=f'html_info_{tabname}')
                html_log = gr.HTML(elem_id=f'html_log_{tabname}')

            paste_field_names = []
            if tabname == "txt2img":
                paste_field_names = modules.scripts.scripts_txt2img.paste_field_names
            elif tabname == "img2img":
                paste_field_names = modules.scripts.scripts_img2img.paste_field_names

            for paste_tabname, paste_button in buttons.items():
                parameters_copypaste.register_paste_params_button(parameters_copypaste.ParamBinding(
                    paste_button=paste_button, tabname=paste_tabname, source_tabname="txt2img" if tabname == "txt2img" else None, source_image_component=result_gallery,
                    paste_field_names=paste_field_names
                ))

            return result_gallery, generation_info if tabname != "extras" else html_info_x, html_info, html_log


def delete_image(js_data, images, index, tabname, outdir):
    """删除图片函数 - 从页面和文件夹中删除图片"""
    import json
    import os
    
    try:
        # 解析 JSON 数据
        data = json.loads(js_data)
        
        # 获取选中的图片索引
        if index < 0:
            return images, "请先选择一张图片"
        
        # 检查索引是否有效
        if index >= len(images):
            return images, f"无效的图片索引: {index}"
        
        # 获取图片数据
        image_data = images[index]
        
        # 从页面删除图片
        new_images = list(images)
        new_images.pop(index)
        
        # 尝试从文件夹中删除图片文件
        file_deleted = False
        file_path = ""
        
        # 解析图片数据获取文件名
        if isinstance(image_data, dict) and 'name' in image_data:
            # 如果是文件对象
            file_path = image_data['name']
        elif isinstance(image_data, str):
            # 如果是 base64 数据，尝试从保存的目录中查找
            # 这里需要根据 tabname 确定输出目录
            if tabname == "txt2img":
                output_dir = shared.opts.outdir_txt2img_samples
            elif tabname == "img2img":
                output_dir = shared.opts.outdir_img2img_samples
            else:
                output_dir = outdir
            
            # 从生成信息中获取文件名
            if 'infotexts' in data and index < len(data['infotexts']):
                infotext = data['infotexts'][index]
                # 从 infotext 中提取文件名
                import re
                match = re.search(r'Filename: ([^\n]+)', infotext)
                if match:
                    filename = match.group(1)
                    file_path = os.path.join(output_dir, filename)
        
        # 如果找到了文件路径，尝试删除文件
        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
                file_deleted = True
                # 同时删除对应的文本文件（如果有）
                txt_file = os.path.splitext(file_path)[0] + '.txt'
                if os.path.exists(txt_file):
                    os.remove(txt_file)
            except Exception as e:
                print(f"删除文件失败: {e}")
        
        # 返回结果
        message = "图片已从页面删除"
        if file_deleted:
            message += "，文件已从文件夹中删除"
        elif file_path:
            message += "，但无法从文件夹中删除文件"
        else:
            message += "，未找到对应的文件"
        
        return new_images, message
        
    except Exception as e:
        print(f"删除图片时出错: {e}")
        return images, f"删除失败: {str(e)}"
