// 语言切换功能 - 无需重启页面
(function() {
    // 当前语言
    let currentLanguage = localStorage.getItem('sd-webui-language') || 'None';
    
    // 语言映射
    const languageMap = {
        'None': 'EN',
        'zh_CN': '中文'
    };
    
    // 语言数据缓存
    let languageData = {
        'None': {},
        'zh_CN': {}
    };
    
    // 加载语言数据
    async function loadLanguageData(lang) {
        console.log('loadLanguageData called for language:', lang);
        
        if (languageData[lang] && Object.keys(languageData[lang]).length > 0) {
            console.log('Using cached language data for:', lang);
            return languageData[lang];
        }
        
        try {
            const url = `/file=localizations/${lang}.json?t=${Date.now()}`;
            console.log('Fetching language data from:', url);
            
            const response = await fetch(url);
            console.log('Fetch response status:', response.status, response.statusText);
            
            if (response.ok) {
                const data = await response.json();
                console.log('Successfully loaded language data for:', lang, 'entries:', Object.keys(data).length);
                languageData[lang] = data;
                return data;
            } else {
                console.warn(`Failed to load language data for ${lang}: HTTP ${response.status}`);
            }
        } catch (error) {
            console.error(`Failed to load language data for ${lang}:`, error);
        }
        
        console.log('Returning empty language data for:', lang);
        return {};
    }
    
    // 切换语言
    async function switchLanguage(lang) {
        if (currentLanguage === lang) return;
        
        console.log('Switching language to:', lang);
        currentLanguage = lang;
        
        // 保存到本地存储
        localStorage.setItem('sd-webui-language', lang);
        
        // 更新按钮文本
        updateButtonText();
        
        // 加载并应用语言数据
        const data = await loadLanguageData(lang);
        applyLanguage(data);
        
        // 更新设置中的语言选项
        updateSettingsLanguage(lang);
        
        // 显示提示
        showNotification(lang === 'zh_CN' ? '已切换到中文' : 'Switched to English');
    }
    
    // 显示通知
    function showNotification(message) {
        // 创建通知元素
        const notification = document.createElement('div');
        notification.style.position = 'fixed';
        notification.style.top = '20px';
        notification.style.right = '20px';
        notification.style.backgroundColor = '#4CAF50';
        notification.style.color = 'white';
        notification.style.padding = '12px 20px';
        notification.style.borderRadius = '4px';
        notification.style.zIndex = '9999';
        notification.style.boxShadow = '0 2px 10px rgba(0,0,0,0.2)';
        notification.textContent = message;
        
        document.body.appendChild(notification);
        
        // 3秒后自动移除
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transition = 'opacity 0.5s';
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 500);
        }, 3000);
    }
    
    // 更新按钮文本和图标
    function updateButtonText() {
        const button = document.getElementById('language_switcher_button');
        if (button) {
            const displayName = languageMap[currentLanguage] || currentLanguage;
            // 使用地球仪图标 + 文字
            const icon = '🌐'; // 地球仪图标
            button.innerHTML = `${icon} ${displayName}`;
            button.title = currentLanguage === 'zh_CN' ? 
                `当前语言: 中文 (点击切换到英文)` : 
                `Current language: English (点击切换到中文)`;
        }
    }
    
    // 应用语言
    function applyLanguage(data) {
        console.log('applyLanguage called with data:', data ? 'has data' : 'no data');
        
        if (!data || Object.keys(data).length === 0) {
            console.log('No translation data available');
            return;
        }
        
        console.log('Applying language data:', Object.keys(data).length, 'translations');
        console.log('Sample translations:', Object.keys(data).slice(0, 5).map(key => `${key} -> ${data[key]}`));
        
        // 首先尝试使用现有的 localization.js 功能
        if (typeof window.processNode === 'function') {
            console.log('Using localization.js processNode function');
            
            try {
                // 更新全局 localization 对象
                window.localization = data;
                
                // 重新处理整个界面
                const gradioApp = document.querySelector('gradio-app');
                if (gradioApp) {
                    const root = gradioApp.shadowRoot || gradioApp;
                    
                    // 先清除现有的翻译
                    if (window.original_lines) {
                        window.original_lines = {};
                        window.translated_lines = {};
                    }
                    
                    // 应用新翻译
                    window.processNode(root);
                    console.log('Language applied successfully using processNode');
                    
                    // 触发 UI 更新
                    if (window.onUiUpdate && window.uiUpdateCallbacks && Array.isArray(window.uiUpdateCallbacks) && window.uiUpdateCallbacks.length > 0) {
                        console.log('Triggering UI update callbacks');
                        window.uiUpdateCallbacks.forEach(callback => {
                            try {
                                if (typeof callback === 'function') {
                                    callback([]);
                                }
                            } catch (e) {
                                console.error('Error in UI update callback:', e);
                            }
                        });
                    } else {
                        console.log('No UI update callbacks to trigger');
                    }
                    
                    return; // 成功应用，直接返回
                } else {
                    console.warn('Gradio app not found, falling back to basic translation');
                }
            } catch (e) {
                console.error('Error applying language with processNode:', e);
                console.log('Falling back to basic translation');
            }
        } else {
            console.warn('Localization functions not available, falling back to basic translation');
        }
        
        // 如果上面的方法失败，使用基本翻译
        console.log('Using basic translation method');
        applyBasicTranslation(data);
    }
    
    // 基本翻译功能（如果 localization.js 不可用）
    function applyBasicTranslation(data) {
        console.log('Applying basic translation with', Object.keys(data).length, 'translations');
        
        // 获取 Gradio 应用的根元素
        const gradioApp = document.querySelector('gradio-app');
        const root = gradioApp ? (gradioApp.shadowRoot || gradioApp) : document;
        
        // 翻译函数 - 更智能的匹配
        function translateElement(element) {
            if (!element || !element.nodeType || element.nodeType !== 1) return;
            
            // 翻译文本内容（包括子节点的文本）
            if (element.childNodes && element.childNodes.length > 0) {
                // 使用 for 循环而不是 forEach，更安全
                for (let i = 0; i < element.childNodes.length; i++) {
                    const child = element.childNodes[i];
                    if (child.nodeType === 3 && child.textContent && child.textContent.trim()) {
                        const text = child.textContent.trim();
                        if (data[text]) {
                            child.textContent = data[text];
                            console.log('Translated text:', text, '->', data[text]);
                        }
                    }
                }
            }
            
            // 翻译占位符
            if (element.placeholder && data[element.placeholder]) {
                element.placeholder = data[element.placeholder];
                console.log('Translated placeholder:', element.placeholder, '->', data[element.placeholder]);
            }
            
            // 翻译标题
            if (element.title && data[element.title]) {
                element.title = data[element.title];
                console.log('Translated title:', element.title, '->', data[element.title]);
            }
            
            // 翻译值（对于输入框和按钮）
            if (element.value && data[element.value]) {
                element.value = data[element.value];
                console.log('Translated value:', element.value, '->', data[element.value]);
            }
            
            // 翻译标签文本
            if (element.tagName === 'LABEL' && element.textContent && data[element.textContent.trim()]) {
                const text = element.textContent.trim();
                element.textContent = data[text];
                console.log('Translated label:', text, '->', data[text]);
            }
            
            // 翻译按钮文本
            if ((element.tagName === 'BUTTON' || element.type === 'button') && element.textContent && data[element.textContent.trim()]) {
                const text = element.textContent.trim();
                element.textContent = data[text];
                console.log('Translated button:', text, '->', data[text]);
            }
        }
        
        // 翻译常见界面元素
        console.log('Starting basic translation...');
        
        // 1. 翻译所有文本节点
        const walker = document.createTreeWalker(
            root,
            NodeFilter.SHOW_TEXT,
            null,
            false
        );
        
        let node;
        let translatedCount = 0;
        while (node = walker.nextNode()) {
            if (node.textContent && node.textContent.trim()) {
                const text = node.textContent.trim();
                if (data[text] && text.length > 1) { // 只翻译长度大于1的文本
                    node.textContent = data[text];
                    translatedCount++;
                }
            }
        }
        
        console.log(`Translated ${translatedCount} text nodes`);
        
        // 2. 翻译特定元素
        const selectors = [
            'button', 
            'input[type="button"]', 
            'input[type="submit"]',
            'label',
            'span',
            'div',
            'p',
            'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
            'textarea',
            'input[type="text"]',
            'input[type="search"]',
            'option',
            'legend',
            'caption',
            'th',
            'td'
        ];
        
        // 2. 翻译特定元素 - 使用更安全的方式
        for (let i = 0; i < selectors.length; i++) {
            const selector = selectors[i];
            try {
                const elements = root.querySelectorAll(selector);
                if (elements && elements.length > 0) {
                    // 使用 for 循环而不是 forEach，更安全
                    for (let j = 0; j < elements.length; j++) {
                        translateElement(elements[j]);
                    }
                    console.log(`Processed ${elements.length} ${selector} elements`);
                }
            } catch (e) {
                console.warn(`Error processing selector ${selector}:`, e);
                // 忽略选择器错误
            }
        }
        
        // 3. 翻译所有具有特定属性的元素 - 使用更安全的方式
        const attributes = ['placeholder', 'title', 'aria-label', 'alt'];
        for (let i = 0; i < attributes.length; i++) {
            const attr = attributes[i];
            try {
                const elements = root.querySelectorAll(`[${attr}]`);
                if (elements && elements.length > 0) {
                    // 使用 for 循环而不是 forEach
                    for (let j = 0; j < elements.length; j++) {
                        const element = elements[j];
                        const value = element.getAttribute(attr);
                        if (value && data[value]) {
                            element.setAttribute(attr, data[value]);
                            console.log(`Translated ${attr}:`, value, '->', data[value]);
                        }
                    }
                }
            } catch (e) {
                console.warn(`Error processing attribute ${attr}:`, e);
                // 忽略错误
            }
        }
        
        console.log('Basic translation completed');
    }
    
    // 更新设置中的语言选项
    function updateSettingsLanguage(lang) {
        const settingElement = document.getElementById('setting_localization');
        if (settingElement && settingElement.tagName === 'SELECT') {
            settingElement.value = lang;
            
            // 触发 change 事件以保存设置
            const event = new Event('change', { bubbles: true });
            settingElement.dispatchEvent(event);
            
            // 模拟点击保存设置按钮
            setTimeout(() => {
                const saveButton = document.querySelector('button[aria-label="Apply settings"]');
                if (saveButton) {
                    saveButton.click();
                }
            }, 100);
        }
    }
    
    // 创建语言切换按钮
    function createLanguageButton() {
        // 检查是否已存在按钮
        if (document.getElementById('language_switcher_button')) {
            return document.getElementById('language_switcher_button');
        }
        
        // 查找快速设置区域
        const quicksettings = document.getElementById('quicksettings');
        if (!quicksettings) {
            console.warn('Quick settings area not found');
            return null;
        }
        
        // 创建按钮容器
        const container = document.createElement('div');
        container.style.marginLeft = 'auto';
        container.style.display = 'flex';
        container.style.alignItems = 'center';
        container.style.gap = '5px';
        
        // 创建按钮
        const button = document.createElement('button');
        button.id = 'language_switcher_button';
        button.className = 'gr-button gr-button-lg gr-button-secondary';
        button.style.padding = '6px 12px';
        button.style.fontSize = '13px';
        button.style.minWidth = '70px';
        button.style.height = '32px';
        button.style.cursor = 'pointer';
        button.style.display = 'flex';
        button.style.alignItems = 'center';
        button.style.justifyContent = 'center';
        button.style.gap = '6px';
        button.style.borderRadius = '4px';
        button.style.border = '1px solid #6b7280';
        button.style.backgroundColor = '#374151';
        button.style.color = '#f9fafb';
        button.style.transition = 'all 0.2s ease';
        
        // 添加悬停效果
        button.addEventListener('mouseenter', function() {
            this.style.backgroundColor = '#4b5563';
            this.style.borderColor = '#9ca3af';
        });
        
        button.addEventListener('mouseleave', function() {
            this.style.backgroundColor = '#374151';
            this.style.borderColor = '#6b7280';
        });
        
        // 设置按钮文本
        updateButtonText();
        
        // 添加点击事件
        button.addEventListener('click', async function() {
            console.log('Language button clicked!');
            console.log('Current language:', currentLanguage);
            
            // 切换语言
            const nextLang = currentLanguage === 'None' ? 'zh_CN' : 'None';
            console.log('Switching to language:', nextLang);
            
            await switchLanguage(nextLang);
        });
        
        // 添加到容器
        container.appendChild(button);
        
        // 添加到快速设置区域
        quicksettings.appendChild(container);
        
        console.log('Language switcher button created');
        return button;
    }
    
    // 初始化语言
    async function initLanguage() {
        try {
            console.log('Initializing language switcher...');
            
            // 创建按钮
            const button = createLanguageButton();
            if (!button) {
                console.warn('Language button creation failed');
                return;
            }
            
            console.log('Language button created successfully');
            
            // 如果当前是中文，应用翻译
            if (currentLanguage === 'zh_CN') {
                console.log('Current language is Chinese, loading translation data...');
                const data = await loadLanguageData('zh_CN');
                if (Object.keys(data).length > 0) {
                    console.log('Applying Chinese translation...');
                    setTimeout(() => {
                        try {
                            applyLanguage(data);
                        } catch (e) {
                            console.error('Error applying language:', e);
                        }
                    }, 1000);
                }
            }
        } catch (error) {
            console.error('Error in initLanguage:', error);
        }
    }
    
    // 安全初始化函数 - 使用更保守的方式
    function safeInit() {
        try {
            console.log('safeInit: Starting language switcher initialization...');
            
            // 检查必要的全局对象
            if (typeof window === 'undefined' || typeof document === 'undefined') {
                console.warn('Window or document not available, retrying in 500ms...');
                setTimeout(safeInit, 500);
                return;
            }
            
            // 等待更长时间确保所有资源加载完成
            setTimeout(() => {
                try {
                    // 检查 Gradio 应用是否完全加载
                    const gradioApp = document.querySelector('gradio-app');
                    if (!gradioApp) {
                        console.warn('Gradio app not found, retrying in 1s...');
                        setTimeout(safeInit, 1000);
                        return;
                    }
                    
                    // 检查 Gradio 是否完全初始化（通过检查内部元素）
                    const gradioLoaded = gradioApp.shadowRoot || 
                                        gradioApp.querySelector('#txt2img_prompt') || 
                                        gradioApp.querySelector('#quicksettings');
                    
                    if (!gradioLoaded) {
                        console.warn('Gradio not fully loaded, retrying in 1s...');
                        setTimeout(safeInit, 1000);
                        return;
                    }
                    
                    console.log('Gradio app fully loaded, initializing language switcher...');
                    
                    // 再等待一小段时间确保完全稳定
                    setTimeout(() => {
                        try {
                            initLanguage();
                        } catch (e) {
                            console.error('Error in initLanguage after delay:', e);
                        }
                    }, 500);
                    
                } catch (error) {
                    console.error('Error checking Gradio status:', error);
                    // 重试
                    setTimeout(safeInit, 1000);
                }
            }, 2000); // 初始等待 2 秒
        } catch (error) {
            console.error('Error in safeInit:', error);
            // 最终重试
            setTimeout(safeInit, 2000);
        }
    }
    
    // 等待页面加载完成
    function waitForPageLoad() {
        try {
            console.log('waitForPageLoad: Checking document ready state...');
            
            if (document.readyState === 'loading') {
                console.log('Document still loading, waiting for DOMContentLoaded...');
                document.addEventListener('DOMContentLoaded', () => {
                    console.log('DOMContentLoaded event fired, starting safeInit in 1s...');
                    setTimeout(safeInit, 1000);
                });
            } else {
                console.log('Document already loaded, starting safeInit in 2s...');
                setTimeout(safeInit, 2000);
            }
        } catch (error) {
            console.error('Error in waitForPageLoad:', error);
            // 最后尝试
            setTimeout(safeInit, 3000);
        }
    }
    
    // 启动 - 使用更安全的方式，避免与 Gradio 初始化冲突
    if (typeof window !== 'undefined') {
        console.log('Language switcher script loaded, starting initialization...');
        
        // 使用更长的延迟，确保 Gradio 先初始化
        setTimeout(() => {
            console.log('Starting waitForPageLoad after initial delay...');
            waitForPageLoad();
        }, 3000); // 初始延迟 3 秒
    } else {
        console.warn('Window object not available, language switcher cannot initialize');
    }
    
    // 导出函数供其他脚本使用
    window.switchLanguage = switchLanguage;
    window.getCurrentLanguage = () => currentLanguage;
    
})();