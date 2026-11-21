{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _565_lit : packoffset(c0);\n    float4 _565_ambient : packoffset(c1);\n    float4 _565_normal_uv : packoffset(c2);\n    float4 _565_flat_ambient : packoffset(c3);\n    float4 _565_light_map : packoffset(c4);\n    float4 _565_light_pos[16] : packoffset(c5);\n    float4 _565_light_color[16] : packoffset(c21);\n    float4 _565_light_shadow_v[16] : packoffset(c37);\n    float4 _565_fog_col : packoffset(c53);\n    float4 _565_fog_b : packoffset(c54);\n    float4 _565_fog_c : packoffset(c55);\n    float4 _565_fog_eye : packoffset(c56);\n    float4 _565_fa_time : packoffset(c57);\n    float4 _565_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _504 = fa_linear_to_srgb(param);\n        c = _504;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _512 = fa_srgb_to_linear(param_1);\n            c = _512;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _523 = tex.Sample(smp, p);\n    float3 param = _523.xyz;\n    float param_1 = xform.y;\n    float3 _533 = fa_tex_fix(param, param_1);\n    return float4(_533, _523.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _109 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_109.x * 255.0f) + 0.5f) * 256.0f) + floor((_109.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _212 = floor(tt);\n    float _222 = _212 - (1024.0f * floor(_212 * 0.0009765625f));\n    float _225 = _222 + 1.0f;\n    float i1 = _225;\n    if (_225 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _222;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _212);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _262 = length(d);\n    float result = 1.0f;\n    if (_262 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _273 = atan2(d.y, d.x);\n        float a = _273;\n        float _276;\n        if (_273 < 0.0f)\n        {\n            _276 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _276 = a;\n        }\n        a = _276;\n        float _286 = _276 * 162.9746551513671875f;\n        float _295 = min((size * 10.0f) / _262, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _323 = floor(_286 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _295));\n            float param = v;\n            float param_1 = _323 - (1024.0f * floor(_323 * 0.0009765625f));\n            float _337 = shadow_texel(param, param_1) * radius;\n            if (_337 < _262)\n            {\n                sum += _337;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _369 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _262)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _387 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _393 = 1.0f - (0.800000011920928955078125f * abs(_387));\n                float param_2 = v;\n                float param_3 = _286 + (_387 * _369);\n                float param_4 = _262;\n                float param_5 = radius;\n                acc += (_393 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _393;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _133 = length(d);\n    if (_133 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _147 = atan2(d.y, d.x);\n    float a = _147;\n    float _150;\n    if (_147 < 0.0f)\n    {\n        _150 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _150 = a;\n    }\n    a = _150;\n    float _162 = _150 * 162.9746551513671875f;\n    float _167 = min(floor(_162), 1023.0f);\n    float _174 = _167 + 1.0f;\n    float i1 = _174;\n    if (_174 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _167;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _133) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _133) + 0.5f, 0.0f, 1.0f), _162 - _167);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _644 = _565_lit.y > 0.5f;\n    if (_644)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _565_normal_uv.xy) + _565_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _668 = fa_tex_fix(param, param_1);\n        float3 _672 = (_668 * 2.0f) - 1.0f.xxx;\n        float _679 = cos(params.y);\n        float _681 = sin(params.y);\n        n = normalize(float3((float2(_679, _681) * _672.x) + ((float2(-_681, _679) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _672.y), max(_672.z, 0.0500000007450580596923828125f)));\n    }\n    bool _715 = !_644;\n    bool _721;\n    if (_715)\n    {\n        _721 = _565_lit.z > 0.5f;\n    }\n    else\n    {\n        _721 = _715;\n    }\n    float3 _724;\n    if (_721)\n    {\n        _724 = _565_flat_ambient.xyz;\n    }\n    else\n    {\n        _724 = _565_ambient.xyz;\n    }\n    float3 total = _724;\n    bool _741;\n    if (_721)\n    {\n        _741 = _565_lit.z < 1.5f;\n    }\n    else\n    {\n        _741 = _721;\n    }\n    if (_741)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _565_light_map.xy, 0.0f).xyz * _565_light_map.z);\n    }\n    float3 l;\n    float _861;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _779;\n        if (!_721)\n        {\n            _779 = float(i) >= _565_lit.x;\n        }\n        else\n        {\n            _779 = _721;\n        }\n        if (_779)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_565_light_pos[i].w < 0.0f)\n        {\n            l = _565_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _805 = _565_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_805) / max(_565_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _565_light_color[i].w);\n            float3 _825 = float3(_805, _565_light_pos[i].z);\n            l = _825 / max(length(_825), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_565_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _565_light_shadow_v[i].x;\n                float param_3 = _565_light_shadow_v[i].y;\n                float2 param_4 = -_805;\n                float param_5 = _565_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_644)\n        {\n            _861 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _861 = 1.0f;\n        }\n        total += (_565_light_color[i].xyz * (att * _861));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _550 = fa_srgb_to_linear(param);\n        c = _550;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _889 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _893 = uv * _889;\n    float _899 = _889.x;\n    float _901 = _889.y;\n    float _903 = clamp(shape_rs.x, 0.0f, min(_899, _901));\n    float2 _914 = (abs(_893) - _889) + _903.xx;\n    float d = (length(max(_914, 0.0f.xx)) + min(max(_914.x, _914.y), 0.0f)) - _903;\n    float ax = params.y;\n    bool _935 = params.y > 15.0f;\n    if (_935)\n    {\n        ax -= 20.0f;\n    }\n    float _946;\n    if (ax <= (-1.5f))\n    {\n        _946 = (-2.0f) - ax;\n    }\n    else\n    {\n        _946 = 0.0f;\n    }\n    if (_946 > 0.0f)\n    {\n        float _960 = _946 * 0.5f;\n        d = abs(d + _960) - _960;\n    }\n    float _968 = fwidth(d);\n    float _969 = max(_968, 9.9999997473787516355514526367188e-05f);\n    float _979 = clamp(0.5f - (d / max(shape_rs.y, _969)), 0.0f, 1.0f);\n    float _984;\n    if (shape_rs.y > _969)\n    {\n        _984 = (_979 * _979) * (3.0f - (2.0f * _979));\n    }\n    else\n    {\n        _984 = _979;\n    }\n    float4 c = color;\n    bool _1006 = (_946 <= 0.0f) && (ax > (-0.5f));\n    if (_1006)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1021 = cos(ax);\n            float _1023 = sin(ax);\n            g = ((dot(_893, float2(_1021, _1023)) / max((abs(_1021) * _899) + (abs(_1023) * _901), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_935)\n        {\n            float4 _1066 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1066;\n            float3 param = _1066.xyz;\n            float param_1 = xform.y;\n            float3 _1073 = fa_tex_fix(param, param_1);\n            float4 _1769 = c;\n            _1769.x = _1073.x;\n            _1769.y = _1073.y;\n            _1769.z = _1073.z;\n            c = _1769;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1085 = scene_rgb(param_2);\n            float4 _1110 = lerp(float4(color.xyz * color.w, color.w), float4(_1085 * color2.w, color2.w), g.xxxx);\n            float _1112 = _1110.w;\n            float3 _1115;\n            if (_1112 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1115 = _1110.xyz / _1112.xxx;\n            }\n            else\n            {\n                _1115 = color.xyz;\n            }\n            c = float4(_1115, _1112);\n        }\n    }\n    float4 _1778 = c;\n    _1778.w = _1778.w * _984;\n    c = _1778;\n    if (_1006 || (shape_rs.y > 0.0f))\n    {\n        float _1156 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1165 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1165 + (_1156 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1171 = fa_srgb_to_linear(param_4);\n            float4 _1781 = c;\n            _1781.x = _1171.x;\n            _1781.y = _1171.y;\n            _1781.z = _1171.z;\n            c = _1781;\n        }\n        else\n        {\n            float4 _1181 = c;\n            float3 _1184 = _1181.xyz + (_1156 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1788 = _1181;\n            _1788.x = _1184.x;\n            _1788.y = _1184.y;\n            _1788.z = _1184.z;\n            c = _1788;\n        }\n        float4 _1793 = c;\n        _1793.w = clamp(_1793.w + ((_1156 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1793.w)), 0.0f, 1.0f);\n        c = _1793;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _571 = gl_FragCoord.xy * _565_fa_target.xy;\n    float _575 = _571.y;\n    return float2(_571.x, lerp(_575, 1.0f - _575, _565_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _614 = base_mode < 0.5f;\n    bool _625;\n    if (!_614)\n    {\n        _625 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _625 = _614;\n    }\n    float _626;\n    if (_625)\n    {\n        _626 = shape_half.x;\n    }\n    else\n    {\n        _626 = 0.0f;\n    }\n    QuadInput _1742 = { uv, color, world_xy, fa_screen_uv(), _565_fa_time.x, base_mode, 0.0f.xxxx, _626 };\n    return _1742;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1211 = params.x > 31.5f;\n    if (_1211)\n    {\n        mode -= 32.0f;\n    }\n    float _1219 = mode;\n    bool _1221 = _1219 > 15.5f;\n    if (_1221)\n    {\n        mode -= 16.0f;\n    }\n    float _1229 = mode;\n    bool _1231 = _1229 > 7.5f;\n    if (_1231)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1221)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1221)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1295 = tex_color(param_5) * color;\n                float4 param_6 = _1295;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1295.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1330 = length(uv);\n                    float _1333 = fwidth(_1330);\n                    float _1334 = max(_1333, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1330) / _1334) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1330) / _1334) + 0.5f, 0.0f, 1.0f) * clamp(((_1330 - params.y) / _1334) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1374 = clamp(1.0f - _1330, 0.0f, 1.0f);\n                            cov = (_1374 * _1374) * (3.0f - (2.0f * _1374));\n                        }\n                    }\n                    float3 _1383;\n                    if (_1221)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1383 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1383 = color.xyz;\n                    }\n                    frag_color = float4(_1383, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1722 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1724 = { _1722 };\n    QuadSurface param_12 = _1724;\n    fragment(param_11, param_12);\n    _1722 = param_12.color;\n    frag_color = param_12.color;\n    if (_1211)\n    {\n        float4 _1421 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1426 = scene_rgb(param_13);\n        float3 _1430 = lerp(_1421.xyz, _1426, color2.w.xxx);\n        frag_color.x = _1430.x;\n        frag_color.y = _1430.y;\n        frag_color.z = _1430.z;\n    }\n    if (_1231)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1454 = _565_fog_col.w > 0.0f;\n    bool _1462;\n    if (!_1454)\n    {\n        _1462 = _565_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1462 = _1454;\n    }\n    if (_1462)\n    {\n        float3 _1476 = float3(world_xy, world_z) - _565_fog_eye.xyz;\n        float _1483 = dot(_1476, _565_fog_c.xyz);\n        bool _1487 = _565_fog_c.w > 0.5f;\n        float _1488;\n        if (_1487)\n        {\n            _1488 = _1483;\n        }\n        else\n        {\n            _1488 = length(_1476);\n        }\n        float _1500 = _1488 - _565_fog_b.x;\n        if (_1500 > 0.0f)\n        {\n            float _1509 = _565_fog_col.w * _1500;\n            float tau = _1509 * _1509;\n            if (_565_fog_b.y > 0.0f)\n            {\n                float _1525;\n                if (_1487)\n                {\n                    _1525 = world_xy.y - (_565_fog_c.y * _1483);\n                }\n                else\n                {\n                    _1525 = _565_fog_eye.y;\n                }\n                float _1546 = lerp(_1525, world_xy.y, clamp(_565_fog_b.x / _1488, 0.0f, 1.0f));\n                float _1550 = world_xy.y - _1546;\n                float _1555 = _1546 - _565_fog_b.z;\n                float _1560 = world_xy.y - _565_fog_b.z;\n                bool _1563 = _1555 <= 0.0f;\n                bool _1564 = !_1563;\n                bool _1570;\n                if (_1564)\n                {\n                    _1570 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1570 = _1563;\n                }\n                float _1571;\n                if (_1570)\n                {\n                    _1571 = _565_fog_b.y;\n                }\n                else\n                {\n                    _1571 = _565_fog_b.y * exp(-min(_565_fog_b.w * _1555, 80.0f));\n                }\n                bool _1598;\n                if (_1564)\n                {\n                    _1598 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1598 = _1563;\n                }\n                float _1599;\n                if (_1598)\n                {\n                    _1599 = _565_fog_b.y * _1555;\n                }\n                else\n                {\n                    _1599 = (_565_fog_b.y * (1.0f - exp(-min(_565_fog_b.w * _1555, 80.0f)))) / _565_fog_b.w;\n                }\n                bool _1624 = _1560 <= 0.0f;\n                bool _1631;\n                if (!_1624)\n                {\n                    _1631 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1631 = _1624;\n                }\n                float _1632;\n                if (_1631)\n                {\n                    _1632 = _565_fog_b.y * _1560;\n                }\n                else\n                {\n                    _1632 = (_565_fog_b.y * (1.0f - exp(-min(_565_fog_b.w * _1560, 80.0f)))) / _565_fog_b.w;\n                }\n                float _1659;\n                if (abs(_1550) < 0.001000000047497451305389404296875f)\n                {\n                    _1659 = _1571;\n                }\n                else\n                {\n                    _1659 = (_1632 - _1599) / _1550;\n                }\n                tau += (_1500 * max(_1659, 0.0f));\n            }\n            float4 _1682 = frag_color;\n            float3 _1690 = lerp(_1682.xyz, _565_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1690.x;\n            frag_color.y = _1690.y;\n            frag_color.z = _1690.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_68",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_565",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 2
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 3
            }
          }
        ],
        "samplers": [
          {
            "slot": 2,
            "stage": "fragment",
            "name": "shadow_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 2
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "light_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 1
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "normal_tex_smp",
            "view_name": "normal_tex",
            "sampler_name": "smp",
            "view_slot": 1,
            "sampler_slot": 0
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "light_tex_light_smp",
            "view_name": "light_tex",
            "sampler_name": "light_smp",
            "view_slot": 2,
            "sampler_slot": 1
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "shadow_tex_shadow_smp",
            "view_name": "shadow_tex",
            "sampler_name": "shadow_smp",
            "view_slot": 3,
            "sampler_slot": 2
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _127_lit : packoffset(c0);\n    float4 _127_ambient : packoffset(c1);\n    float4 _127_normal_uv : packoffset(c2);\n    float4 _127_flat_ambient : packoffset(c3);\n    float4 _127_light_map : packoffset(c4);\n    float4 _127_light_pos[16] : packoffset(c5);\n    float4 _127_light_color[16] : packoffset(c21);\n    float4 _127_light_shadow_v[16] : packoffset(c37);\n    float4 _127_fog_col : packoffset(c53);\n    float4 _127_fog_b : packoffset(c54);\n    float4 _127_fog_c : packoffset(c55);\n    float4 _127_fog_eye : packoffset(c56);\n    float4 _127_fa_time : packoffset(c57);\n    float4 _127_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _134 = gl_FragCoord.xy * _127_fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, lerp(_140, 1.0f - _140, _127_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5f;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0f;\n    }\n    QuadInput _306 = { uv, color, world_xy, fa_screen_uv(), _127_fa_time.x, base_mode, 0.0f.xxxx, _196 };\n    return _306;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n}\n\nvoid frag_main()\n{\n    float4 _221 = tex.Sample(smp, uv);\n    float3 param = _221.xyz;\n    float param_1 = xform.y;\n    float3 _232 = fa_tex_fix(param, param_1);\n    frag_color = float4(_232, _221.w) * color;\n    float param_2 = 0.0f;\n    float4 _286 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _288 = { _286 };\n    QuadSurface param_4 = _288;\n    fragment(param_3, param_4);\n    _286 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main",
          "d3d11_target": "vs_5_0"
        },
        "fragment_func": {
          "entry_point": "main",
          "d3d11_target": "ps_5_0"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 0
          },
          {
            "slot": 1,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 1
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 2
          },
          {
            "slot": 3,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 3
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 4
          },
          {
            "slot": 5,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 5
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 6
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_68",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_127",
            "hlsl_register_b_n": 1
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 0
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 0
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "tex_smp",
            "view_name": "tex",
            "sampler_name": "smp",
            "view_slot": 0,
            "sampler_slot": 0
          }
        ]
      }
    }
  }
}
