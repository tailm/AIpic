# Stable Diffusion WebUI LoRA 模型使用指南

## 📋 已安装的 LoRA 模型
- **模型名称**: `lora_sd3.5m_4steps.safetensors`
- **文件位置**: `models/Lora/lora_sd3.5m_4steps.safetensors`
- **文件大小**: 112.23 MB
- **模型类型**: Stable Diffusion 3.5 Medium Turbo LoRA 适配器

## 🎯 在 WebUI 中使用 LoRA 模型的步骤

### 步骤 1: 访问 WebUI
1. 打开浏览器访问: http://localhost:7860
2. 确保服务正在运行（右上角显示语言切换按钮 🌐 EN）

### 步骤 2: 找到额外网络面板
1. 在 **txt2img** 或 **img2img** 标签页中
2. 在提示词输入框下方，找到 **"Generate"** 按钮
3. 在 **"Generate"** 按钮旁边，寻找以下图标之一：
   - **红色箭头图标** (▶️) - 点击展开额外网络面板
   - **"Show/hide extra networks"** 按钮
   - **"Extra networks"** 选项卡

### 步骤 3: 访问 LoRA 标签页
1. 展开额外网络面板后，您会看到多个标签页：
   - **Checkpoints** - 基础模型
   - **Lora** - LoRA 模型 ⭐
   - **Hypernetworks** - 超网络
   - **Embeddings** - 文本嵌入
   - **其他扩展**

2. 点击 **"Lora"** 标签页

### 步骤 4: 选择 LoRA 模型
1. 在 LoRA 标签页中，您应该能看到：
   - `lora_sd3.5m_4steps` - 我们下载的模型
   - 可能还有其他 LoRA 模型（如果有的话）

2. 点击 **`lora_sd3.5m_4steps`** 模型

### 步骤 5: 调整 LoRA 权重
LoRA 权重调节有几种方式：

#### 方式 1: 点击模型时自动添加
- 点击 LoRA 模型名称后，会在提示词中自动添加：
  ```
  <lora:lora_sd3.5m_4steps:1.0>
  ```
- 最后的 `1.0` 是默认权重

#### 方式 2: 手动调整权重
1. 在提示词中找到 LoRA 标签：
   ```
   <lora:lora_sd3.5m_4steps:1.0>
   ```

2. 修改最后的数字来调整权重：
   - `:0.5` - 较低强度（50%）
   - `:0.8` - 中等强度（80%）
   - `:1.0` - 默认强度（100%）
   - `:1.2` - 较高强度（120%）
   - `:1.5` - 高强度（150%）

   示例：`<lora:lora_sd3.5m_4steps:0.7>`

#### 方式 3: 在设置中修改默认权重
1. 点击右上角的 **"Settings"**（设置）按钮
2. 在左侧菜单中找到 **"Additional Networks"** 或 **"Extra Networks"**
3. 查找 **"Multiplier for extra networks"** 选项
4. 调整滑块（范围：0.0 - 1.0，步长：0.01）
5. 点击 **"Apply settings"**（应用设置）
6. 点击 **"Reload UI"**（重新加载界面）

### 步骤 6: 使用 LoRA 生成图像
1. 在提示词中输入您想要的内容
2. 确保 LoRA 标签在提示词中（如：`<lora:lora_sd3.5m_4steps:0.8>`）
3. 调整其他参数（采样步数、CFG 尺度等）
4. 点击 **"Generate"**（生成）按钮

## 🔧 故障排除

### 问题 1: 看不到 LoRA 标签页
**解决方案**:
1. 确保 LoRA 扩展已启用（默认已启用）
2. 重启 WebUI 服务
3. 检查控制台是否有错误信息

### 问题 2: LoRA 模型不显示
**解决方案**:
1. 确认模型文件位置正确：`models/Lora/lora_sd3.5m_4steps.safetensors`
2. 在额外网络面板点击 **"Refresh"**（刷新）按钮
3. 重启 WebUI 服务

### 问题 3: 权重调节无效
**解决方案**:
1. 确保 LoRA 标签格式正确：`<lora:模型名称:权重>`
2. 权重值应在 0.0-2.0 之间（建议 0.5-1.5）
3. 检查设置中的默认权重值

## ⚙️ 高级用法

### 同时使用多个 LoRA
您可以在提示词中添加多个 LoRA 标签：
```
<lora:模型1:0.8>, <lora:模型2:0.5>, <lora:模型3:1.0>
```

### 负向提示词中的 LoRA
LoRA 也可以用在负向提示词中：
```
Negative prompt: <lora:模型名称:0.3>
```

### 权重实验建议
- **肖像/人物**: 0.7-1.0
- **风景/建筑**: 0.5-0.8
- **艺术风格**: 0.8-1.2
- **细节增强**: 1.0-1.5

## 📊 LoRA 权重效果参考
- **0.3-0.5**: 轻微影响，保持原模型大部分特征
- **0.6-0.8**: 适中影响，平衡原模型和 LoRA 特征
- **0.9-1.2**: 较强影响，LoRA 特征明显
- **1.3-2.0**: 强烈影响，可能产生过度风格化

## 🔄 刷新模型列表
如果看不到 LoRA 模型：
1. 在额外网络面板点击 **"Refresh"** 按钮
2. 或重启 WebUI 服务

## 💡 提示
1. LoRA 权重不是线性的，需要实验找到最佳值
2. 不同 LoRA 模型的最佳权重可能不同
3. 可以保存包含 LoRA 权重的提示词预设
4. 使用 XYZ 图表功能测试不同权重效果

现在您可以在 Stable Diffusion WebUI 中使用 Stable Diffusion 3.5 Medium Turbo LoRA 模型了！