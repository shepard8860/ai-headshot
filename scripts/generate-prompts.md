# 模板底图生成 Prompt 手册

> 本文档为 `design/templates/` 下 28 个职业照模板的手写优化英文 Prompt，可直接粘贴到 **Midjourney** / **Stable Diffusion WebUI** / **ComfyUI** / **Replicate** 等平台使用。
>
> **重要说明：**所有 Prompt 均特意强调 **无人脸**（face turned away / no facial features visible），因为底图的人脸部分将在后续流程中通过用户自拍融合上去。

---

## 通用质量后缀（可根据平台选择性添加）

```
Professional studio photography, 8k uhd, sharp focus, clean composition, 
magazine editorial quality, high-end retouching, solid or gradient background, 
face completely turned away from camera, NO eyes nose or mouth visible, 
smooth blank skin where face would be, head facing backward or in profile away from lens
```

**Midjourney 参数建议**
```
--ar 2:3 --style raw --s 250 --q 2
```

**Stable Diffusion 参数建议**
```
Steps: 30, Sampler: DPM++ 2M Karras, CFG scale: 7, Size: 1024x1536
Negative prompt: face, facial features, eyes, nose, mouth, lips, teeth, eyebrows, 
portrait of a person with visible face, head facing camera, ugly, deformed, blurry, low quality
```

---

## 一、商务正装 (Business Formal)

### 1. business_linkedin_001 — 标准 LinkedIn 形象照

```
Professional corporate headshot composition, upper body portrait, 
confident and approachable body posture, natural relaxed shoulders, 
classic business suit in navy blue or charcoal gray with white dress shirt, 
subtle tie or no tie, well-fitted professional attire, 
solid light gray off-white studio backdrop, seamless and evenly lit, minimal corporate background, 
soft diffused studio lighting, Rembrandt butterfly lighting setup, even skin tone on neck and hands, 
neutral and professional cool blue-gray tones with natural skin color balance, 
face completely turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, magazine-quality corporate photography, 8k uhd, sharp focus
```

### 2. business_finance_male_001 — 金融精英形象照（男）

```
Premium finance executive portrait composition, authoritative masculine posture, 
upper body portrait, tailored dark navy pinstripe suit, crisp white shirt, 
silk tie in burgundy or navy, polished leather shoes visible at bottom, 
deep navy charcoal gradient backdrop, subtle city skyline silhouette, premium corporate environment, 
dramatic but polished studio lighting, slight rim light for dimension, professional key light from 45 degrees, 
rich deep blues and charcoal, warm skin tones on neck and hands, high contrast professional color grading, 
face turned completely away from camera, NO eyes nose mouth visible, smooth blank skin where face should be, 
head facing backward, editorial quality, 8k uhd
```

### 3. business_finance_female_001 — 金融精英形象照（女）

```
Elegant female finance executive portrait, poised confident feminine posture, 
upper body portrait, tailored women's blazer in charcoal or navy, 
silk blouse in ivory or light blue, minimal pearl or gold jewelry, structured silhouette, 
soft gradient from warm gray to cream backdrop, subtle premium texture, high-end office ambiance, 
soft beauty lighting with gentle fill, flattering for neck and collarbone, professional studio setup, 
warm neutrals with sophisticated cream and navy accents, natural glowing skin tones on visible skin, 
face completely turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward or in profile away, premium editorial quality, 8k uhd
```

### 4. business_manager_male_001 — 大厂管理层形象照（男）

```
Modern tech leadership portrait, relaxed confident masculine posture, 
smart casual business style, approachable authority stance, upper body, 
tailored blazer in dark tone with open-collar shirt or fine-knit sweater, no tie, modern and relaxed, 
clean minimalist office background, blurred bookshelves or glass windows, soft bokeh effect, modern workspace, 
natural window light simulation with soft fill, bright and airy atmosphere, minimal shadow, 
modern neutral palette, crisp whites and soft grays, natural skin tones with slight warmth on hands and neck, 
face turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, contemporary corporate photography, 8k uhd
```

### 5. business_manager_female_001 — 大厂管理层形象照（女）

```
Modern female tech leader portrait, poised confident feminine posture, 
contemporary corporate style, blend of warmth and authority, upper body, 
elegant blazer in muted tone with silk camisole or crisp shirt, subtle statement necklace, modern professional, 
bright modern office with soft natural light background, blurred greenery or minimalist interior, fresh open atmosphere, 
bright natural-looking studio light, soft and even with gentle highlights, fresh energetic feel, 
clean modern palette, soft whites and gentle earth tones, luminous skin tones on neck and hands, 
face completely turned away from camera, NO eyes nose mouth visible, smooth blank face area, 
head facing backward, magazine-quality corporate photography, 8k uhd
```

### 6. business_ceo_male_001 — 高管CEO形象照（男）

```
Executive leadership portrait, commanding masculine presence, visionary posture, 
premium editorial style, magazine-quality corporate photography, upper body, 
bespoke dark suit in black or midnight navy, pristine white shirt, understated luxury tie or pocket square, 
impeccable tailoring, dramatic dark backdrop with subtle gradient, luxury boardroom or corner office feel, 
cinematic studio lighting with controlled contrast, subtle rim light, sculpted shadows for gravitas, 
deep cinematic tones, rich blacks and warm skin on neck and hands, editorial color grading with depth, 
face completely turned away from camera, NO facial features visible, smooth blank skin where face would be, 
head facing backward, powerful CEO portrait, 8k uhd
```

### 7. business_ceo_female_001 — 高管CEO形象照（女）

```
Powerful female executive portrait, commanding elegance, magazine editorial quality, 
strong yet graceful leadership posture, upper body, 
power suit in black or deep navy, silk blouse, statement but refined jewelry, 
perfectly tailored executive attire, sophisticated dark backdrop with warm undertones, 
luxury executive environment, premium editorial setting, 
high-end editorial lighting, dramatic but flattering, strong key light with elegant shadow falloff, 
sophisticated warm neutrals, deep blacks and glowing warm skin on neck and collarbone, 
premium editorial color palette, face completely turned away from camera, 
NO facial features visible, smooth blank face area, head facing backward, 
executive editorial quality, 8k uhd
```

---

## 二、科技互联网 (Tech Internet)

### 8. tech_pm_male_001 — 产品经理形象照（男）

```
Tech product manager portrait, thoughtful innovative posture, 
modern casual-professional blend, startup-friendly aesthetic, upper body, 
smart casual, fitted oxford shirt or polo in neutral tones, optional light sweater or unstructured blazer, 
clean and modern, clean bright workspace background, subtle whiteboard or product mockup blur, 
modern tech office vibe, bright natural light simulation, clean and crisp, minimal shadows, 
fresh and energetic atmosphere, clean tech palette, bright whites and soft blues, 
natural healthy skin tones on neck and hands, face completely turned away from camera, 
NO facial features visible, smooth blank face area, head facing backward, 
contemporary tech professional photography, 8k uhd
```

### 9. tech_pm_female_001 — 产品经理形象照（女）

```
Female product manager portrait, intelligent creative posture, 
approachable tech professional, modern startup aesthetic, upper body, 
contemporary business casual, structured blouse or knit top in soft colors, 
minimal elegant accessories, polished but approachable, 
bright modern co-working space blur background, soft natural tones, innovative open environment, 
soft bright lighting with gentle warmth, flattering and natural, professional but not stiff, 
fresh modern palette, soft whites and gentle pastels, warm natural skin tones on neck and hands, 
face turned away from camera, NO eyes nose mouth visible, smooth blank face area, 
head facing backward, modern tech portrait, 8k uhd
```

### 10. tech_expert_male_001 — 技术专家形象照（男）

```
Tech expert portrait, focused intelligent posture, engineer aesthetic, 
modern intellectual vibe, clean and precise, upper body, 
clean hoodie or crew-neck sweater in dark neutral, optional casual blazer, 
glasses optional on collar, understated and smart, 
minimal dark or code-editor-themed backdrop, subtle tech pattern blur, focused serious environment, 
cool-toned studio lighting, crisp and precise, slight contrast for definition, intellectual atmosphere, 
cool tech tones, deep grays and subtle blues, clean modern color balance on visible skin, 
face completely turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, modern tech professional photography, 8k uhd
```

### 11. tech_expert_female_001 — 技术专家形象照（女）

```
Female tech expert portrait, sharp confident posture, modern intellectual style, 
approachable expertise, clean aesthetic, upper body, 
smart casual top or light sweater in neutral or muted tech colors, clean lines, 
minimal accessories, modern glasses optional on collar, 
minimalist light backdrop with subtle tech elements, clean organized workspace blur, 
bright even lighting with slight cool tint, crisp and clear, professional and modern, 
clean neutral palette with cool undertones, fresh and modern, natural skin with clarity on neck and hands, 
face turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, contemporary tech portrait, 8k uhd
```

### 12. tech_founder_male_001 — 创业者形象照（男）

```
Tech founder portrait, dynamic visionary posture, energetic confidence, 
startup culture aesthetic, bold and inspiring, upper body, 
casual but sharp, fitted dark t-shirt or henley with unstructured blazer, 
or clean button-down, modern founder style, 
vibrant modern startup office or city view blur background, energetic aspirational environment, 
warm natural light, warm natural light with dynamic highlights, energetic and inviting, aspirational atmosphere, 
warm energetic palette, golden hour tones mixed with modern neutrals, vibrant skin tones on neck and hands, 
face completely turned away from camera, NO eyes nose mouth visible, smooth blank face area, 
head facing backward, dynamic founder photography, 8k uhd
```

### 13. tech_founder_female_001 — 创业者形象照（女）

```
Female tech founder portrait, bold inspiring posture, confident visionary, 
dynamic energy, modern entrepreneurial aesthetic, upper body, 
modern founder style, elegant blouse or fitted top with statement blazer, 
confident and contemporary, minimal bold accessories, 
bright aspirational workspace or modern loft blur background, energetic innovative setting, warm tones, 
warm dynamic lighting, golden highlights, energetic empowering atmosphere, magazine-quality, 
warm modern palette, aspirational golden tones, confident glowing skin on neck and collarbone, 
premium startup aesthetic, face turned away from camera, NO facial features visible, 
smooth blank face area, head facing backward, founder editorial portrait, 8k uhd
```

---

## 三、创意设计 (Creative Design)

### 14. creative_designer_male_001 — 设计师形象照（男）

```
Creative designer portrait, artistic confident posture, modern creative professional, 
individual style with polish, contemporary aesthetic, upper body, 
stylish modern attire, creative professional look, fitted shirt or turtleneck in black or neutral, 
subtle artistic flair, clean lines, minimal creative studio or design workspace blur background, 
clean modern aesthetic, subtle art elements, contemporary creative environment, 
artistic studio lighting, creative and modern, slight directional light for character, 
modern creative palette, monochrome neutrals with subtle artistic accents, 
clean sophisticated, natural skin with edge on neck and hands, 
face completely turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, contemporary creative portrait, 8k uhd
```

### 15. creative_designer_female_001 — 设计师形象照（女）

```
Female designer portrait, creative sophisticated posture, modern artistic professional, 
elegant individual style, fashion-forward creative, upper body, 
chic creative professional attire, artistic blouse or top with statement accessories, 
modern fashion sensibility, individual expression, 
clean modern studio with subtle design elements background, artistic minimalism, 
contemporary creative workspace blur, soft artistic lighting with gentle direction, 
flattering and modern, creative studio quality, 
sophisticated creative palette, soft neutrals with artistic warm accents, 
elegant natural skin on neck and collarbone, contemporary art tones, 
face turned away from camera, NO eyes nose mouth visible, smooth blank face area, 
head facing backward, fashion creative portrait, 8k uhd
```

### 16. creative_culture_001 — 文化创意形象照

```
Cultural creative professional portrait, expressive thoughtful posture, 
arts and culture vibe, contemporary intellectual creative, stylish and cultured, upper body, 
cultured contemporary attire, smart artistic style, possibly with cultural elements, 
refined and expressive, modern creative elegance, 
art gallery or modern cultural space blur background, sophisticated artistic environment, 
contemporary cultural setting, gallery-quality lighting, refined and artistic, 
soft with slight drama, cultured atmosphere, 
cultured artistic palette, warm neutrals with rich undertones, 
sophisticated skin tones on neck and hands, gallery aesthetic colors, 
face completely turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, gallery portrait quality, 8k uhd
```

---

## 四、教育培训 (Education)

### 17. edu_teacher_male_001 — 教师形象照（男）

```
Professional teacher portrait, wise approachable posture, intellectual warmth, 
educational authority with friendliness, upper body, 
smart casual academic attire, button-down shirt with optional sweater or vest, 
neat and scholarly, approachable professionalism, 
soft blurred classroom or library background, warm natural tones, 
scholarly welcoming environment, warm natural lighting, soft and inviting, 
gentle shadows, intellectual comforting atmosphere, 
warm academic palette, earthy tones and soft creams, natural warm skin on neck and hands, 
scholarly inviting colors, face turned away from camera, NO facial features visible, 
smooth blank face area, head facing backward, academic portrait photography, 8k uhd
```

### 18. edu_teacher_female_001 — 教师形象照（女）

```
Female teacher portrait, warm intelligent posture, nurturing academic presence, 
approachable wisdom, educational grace, upper body, 
elegant professional blouse or dress with cardigan, modest and scholarly, 
warm colors, approachable academic style, 
soft blurred classroom with books or natural light background, warm encouraging educational setting, 
soft warm natural light, flattering and gentle, inviting nurturing atmosphere, 
warm gentle palette, soft earth tones and muted colors, natural warm glowing skin on neck and hands, 
educational warmth, face completely turned away from camera, NO eyes nose mouth visible, 
smooth blank face area, head facing backward, nurturing academic portrait, 8k uhd
```

### 19. edu_trainer_male_001 — 培训师形象照（男）

```
Professional trainer portrait, energetic engaging posture, dynamic communication presence, 
corporate learning authority, upper body, 
sharp business casual, fitted polo or shirt with smart blazer, 
confident and dynamic, professional speaker attire, 
modern training room or seminar space blur background, professional development environment, 
energetic corporate learning setting, bright energetic lighting, dynamic and engaging, 
professional event atmosphere, clear and vibrant, 
energetic professional palette, bright neutrals with dynamic contrast, 
healthy vibrant skin on neck and hands, motivating colors, 
face turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, dynamic trainer photography, 8k uhd
```

### 20. edu_trainer_female_001 — 培训师形象照（女）

```
Female trainer portrait, confident dynamic posture, engaging speaker presence, 
professional development authority, warm energy, upper body, 
smart professional dress or blouse with structured jacket, confident and polished, 
dynamic speaker style, minimal accessories, 
modern seminar or workshop space blur background, bright and professional, 
empowering learning environment, bright flattering lighting, energetic and professional, 
vibrant empowering atmosphere, warm professional palette, bright and inviting, 
confident skin tones on neck and collarbone, motivating empowering colors, 
face completely turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, empowering speaker portrait, 8k uhd
```

---

## 五、医疗健康 (Healthcare)

### 21. health_doctor_male_001 — 白大挎医生形象照（男）

```
Professional doctor portrait, trustworthy compassionate posture, 
medical authority with warmth, clean clinical yet human photography, upper body, 
white lab coat over light blue or white medical scrubs, clean stethoscope optional, 
professional medical attire, soft blurred hospital corridor or clean medical office background, 
white and light blue tones, sterile but welcoming environment, 
bright clean medical lighting, soft and even, trustworthy and clear, no dramatic shadows, 
clean medical whites and soft blues, pure trustworthy palette, 
natural healthy skin tones on neck and hands, face completely turned away from camera, 
NO facial features visible, smooth blank face area, head facing backward, 
medical professional photography, 8k uhd
```

### 22. health_doctor_female_001 — 白大挎医生形象照（女）

```
Female doctor portrait, professional caring posture, medical expertise with feminine warmth, 
clean and approachable, upper body, white lab coat over pastel scrubs or professional dress, 
minimal jewelry, neat professional medical appearance, 
soft blurred modern clinic background, gentle natural light from windows, 
clean comforting medical space, soft bright lighting with gentle warmth, 
flattering and trustworthy, clean clinical quality, 
clean whites and soft pastels, gentle blue-green accents, 
warm natural skin on neck and hands, healing palette, 
face turned away from camera, NO eyes nose mouth visible, smooth blank face area, 
head facing backward, medical professional portrait, 8k uhd
```

### 23. health_nurse_001 — 护士形象照

```
Professional nurse portrait, warm caring posture, dedicated healthcare professional, 
approachable and trustworthy, upper body, clean nursing scrubs in soft blue or pastel, 
optional nurse cap or badge, neat professional medical uniform, 
soft blurred patient care area or modern hospital room background, 
warm comforting tones, human-centered medical environment, 
warm soft lighting, gentle and comforting, natural and inviting, professional care atmosphere, 
warm comforting palette, soft blues and gentle pinks, 
natural glowing skin on neck and hands, caring human tones, 
face completely turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, healthcare professional photography, 8k uhd
```

---

## 六、法律政府 (Legal Government)

### 24. legal_lawyer_male_001 — 律师形象照（男）

```
Professional lawyer portrait, authoritative sharp posture, legal expertise and confidence, 
traditional professional power, trustworthy counsel, upper body, 
impeccable dark suit, crisp white shirt, conservative tie, 
polished legal professional attire, traditional power dressing, 
classic law office or courtroom ambiance blur background, rich wood tones and leather, 
traditional legal authority setting, traditional professional lighting, 
even and authoritative, slight formality, classic portrait setup, 
classic legal palette, deep navy and burgundy tones, 
authoritative warm skin on neck and hands, traditional professional colors, 
face turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, traditional legal portrait, 8k uhd
```

### 25. legal_lawyer_female_001 — 律师形象照（女）

```
Female lawyer portrait, powerful elegant posture, legal authority with feminine sophistication, 
commanding courtroom presence, upper body, powerful tailored suit in dark navy or charcoal, 
silk blouse, refined jewelry, sophisticated legal professional, 
elegant law firm interior blur background, refined and professional, 
modern legal authority with warmth, professional elegant lighting, 
flattering but authoritative, modern legal portrait quality, 
sophisticated legal palette, deep tones with elegant warmth, 
confident skin tones on neck and collarbone, modern professional authority colors, 
face completely turned away from camera, NO eyes nose mouth visible, smooth blank face area, 
head facing backward, elegant legal portrait, 8k uhd
```

### 26. gov_civil_001 — 公务员形象照

```
Civil servant portrait, trustworthy composed posture, public service dedication, 
reliable approachable government professional, upper body, 
formal government attire, dark suit or official uniform, conservative and neat, 
respectable public servant appearance, neutral government office or public building blur background, 
clean and official, understated authority setting, 
even formal lighting, clear and trustworthy, official portrait quality, no dramatic effects, 
official neutral palette, trustworthy blues and grays, 
natural respectful skin tones on neck and hands, government professional colors, 
face turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, official government portrait, 8k uhd
```

---

## 七、销售市场 (Sales Marketing)

### 27. sales_manager_male_001 — 销售经理形象照（男）

```
Sales manager portrait, confident friendly posture, persuasive charm, 
approachable business winner, dynamic professional energy, upper body, 
sharp business attire, well-fitted suit in navy or charcoal, 
confident tie or open collar, successful sales professional look, 
modern corporate office or city view blur background, success-oriented environment, 
dynamic business atmosphere, bright confident lighting, energetic and welcoming, 
success-oriented atmosphere, vibrant and engaging, 
dynamic business palette, confident blues and warm accents, 
successful vibrant skin tones on neck and hands, winning colors, 
face completely turned away from camera, NO facial features visible, smooth blank face area, 
head facing backward, dynamic sales portrait, 8k uhd
```

### 28. market_director_female_001 — 市场总监形象照（女）

```
Marketing director portrait, strategic creative posture, brand-savvy professional, 
dynamic leadership with style, modern marketing authority, upper body, 
fashion-forward business attire, statement blazer or dress, 
contemporary professional with personal brand, stylish and authoritative, 
trendy modern office or creative workspace blur background, brand-conscious environment, 
dynamic marketing setting, modern vibrant lighting, dynamic and stylish, 
brand-conscious atmosphere, contemporary and engaging, 
vibrant modern palette, confident warm tones with contemporary edge, 
glowing skin on neck and collarbone, marketing creativity colors, 
face turned away from camera, NO eyes nose mouth visible, smooth blank face area, 
head facing backward, modern marketing portrait, 8k uhd
```

---

## 使用建议

### Midjourney
1. 复制上面的 Prompt（不含通用质量后缀，因为已包含在prompt内）
2. 在末尾添加参数：`--ar 2:3 --style raw --s 250`
3. 如需要更高质量可加 `--q 2`
4. 建议先用 `Vary (Strong)` 调整几次，再用 `Upscale` 获得最终图

### Stable Diffusion WebUI / Forge
1. 将 Prompt 粘贴到正向提示词框
2. 负向提示词使用：
   ```
   face, facial features, eyes, nose, mouth, lips, teeth, eyebrows, portrait of a person with visible face, head facing camera, ugly, deformed, blurry, low quality
   ```
3. 参数建议：`Steps: 30, Sampler: DPM++ 2M Karras, CFG: 7, Size: 1024x1536`
4. 建议使用 **RealVisXL** 或 **JuggernautXL** 等写实风格大模型

### ComfyUI
1. 使用 `KSampler` + `CheckpointLoaderSimple`（推荐 RealVisXL V4.0）
2. 添加 `CLIPTextEncode` 输入上述正向和负向提示词
3. 使用 `EmptyLatentImage` 设置尺寸为 1024x1536
4. 连接 `VAEDecode` → `SaveImage`，输出保存

### Replicate (本脚本默认)
1. 设置环境变量 `REPLICATE_API_TOKEN`
2. 默认使用 `black-forest-labs/flux-schnell`，也可修改为 `stability-ai/stable-diffusion-3`
3. 运行：`python3 scripts/generate-template-images.py --provider replicate`
