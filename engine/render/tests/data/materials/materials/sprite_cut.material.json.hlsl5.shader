{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "hlsl5",
  "params": [
    "cut",
    "cutY"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _429_lit : packoffset(c0);\n    float4 _429_ambient : packoffset(c1);\n    float4 _429_normal_uv : packoffset(c2);\n    float4 _429_flat_ambient : packoffset(c3);\n    float4 _429_light_map : packoffset(c4);\n    float4 _429_light_pos[16] : packoffset(c5);\n    float4 _429_light_color[16] : packoffset(c21);\n    float4 _429_light_shadow_v[16] : packoffset(c37);\n    float4 _429_fog_col : packoffset(c53);\n    float4 _429_fog_b : packoffset(c54);\n    float4 _429_fog_c : packoffset(c55);\n    float4 _429_fog_eye : packoffset(c56);\n    float4 _429_fa_time : packoffset(c57);\n    float4 _429_fa_target : packoffset(c58);\n    float4 _429_fx_emit : packoffset(c59);\n    float4 _429_fx_emit_uv : packoffset(c60);\n    float4 _429_fx_rim : packoffset(c61);\n    float4 _429_fx_rim_uv : packoffset(c62);\n    float4 _429_light_cookie[16] : packoffset(c63);\n    float4 _429_light_cookie_xf[16] : packoffset(c79);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _508_cut : packoffset(c0);\n    float _508_fa_pad0 : packoffset(c0.y);\n    float _508_fa_pad1 : packoffset(c0.z);\n    float _508_fa_pad2 : packoffset(c0.w);\n    float _508_cutY : packoffset(c1);\n    float _508_fa_pad3 : packoffset(c1.y);\n    float _508_fa_pad4 : packoffset(c1.z);\n    float _508_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _367 = fa_linear_to_srgb(param);\n        c = _367;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _375 = fa_srgb_to_linear(param_1);\n            c = _375;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _386 = tex.Sample(smp, p);\n    float3 param = _386.xyz;\n    float param_1 = xform.y;\n    float3 _396 = fa_tex_fix(param, param_1);\n    return float4(_396, _386.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _111 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_111.x * 255.0f) + 0.5f) * 256.0f) + floor((_111.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _135 = length(d);\n    if (_135 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _149 = atan2(d.y, d.x);\n    float a = _149;\n    float _152;\n    if (_149 < 0.0f)\n    {\n        _152 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _152 = a;\n    }\n    a = _152;\n    float _164 = _152 * 162.9746551513671875f;\n    float _169 = min(floor(_164), 1023.0f);\n    float _176 = _169 + 1.0f;\n    float i1 = _176;\n    if (_176 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _169;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _135) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _135) + 0.5f, 0.0f, 1.0f), _164 - _169);\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _239 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _243 = _239.x + 0.5f;\n    float2 c = float2(_243, 0.5f - _239.y);\n    bool _251 = _243 >= 0.0f;\n    bool _257;\n    if (_251)\n    {\n        _257 = c.x <= 1.0f;\n    }\n    else\n    {\n        _257 = _251;\n    }\n    bool _263;\n    if (_257)\n    {\n        _263 = c.y >= 0.0f;\n    }\n    else\n    {\n        _263 = _257;\n    }\n    bool _269;\n    if (_263)\n    {\n        _269 = c.y <= 1.0f;\n    }\n    else\n    {\n        _269 = _263;\n    }\n    float2 _271 = c;\n    float2 _276 = clamp(_271, 0.001953125f.xx, 0.998046875f.xx);\n    c = _276;\n    return float3(cell.x + (_276.x * cell.w), cell.y + (_276.y * cell.z), float(_269));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_429_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _429_light_cookie[i];\n    float4 param_1 = _429_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _545 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _545.xy, 0.0f);\n    return cookie_value(param_3) * _545.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _567 = _429_lit.y > 0.5f;\n    if (_567)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _429_normal_uv.xy) + _429_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _591 = fa_tex_fix(param, param_1);\n        float3 _595 = (_591 * 2.0f) - 1.0f.xxx;\n        float _602 = cos(params.y);\n        float _604 = sin(params.y);\n        n = normalize(float3((float2(_602, _604) * _595.x) + ((float2(-_604, _602) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _595.y), max(_595.z, 0.0500000007450580596923828125f)));\n    }\n    bool _638 = !_567;\n    bool _644;\n    if (_638)\n    {\n        _644 = _429_lit.z > 0.5f;\n    }\n    else\n    {\n        _644 = _638;\n    }\n    float3 _647;\n    if (_644)\n    {\n        _647 = _429_flat_ambient.xyz;\n    }\n    else\n    {\n        _647 = _429_ambient.xyz;\n    }\n    float3 total = _647;\n    bool _664;\n    if (_644)\n    {\n        _664 = _429_lit.z < 1.5f;\n    }\n    else\n    {\n        _664 = _644;\n    }\n    if (_664)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _429_light_map.xy, 0.0f).xyz * _429_light_map.z);\n    }\n    float3 l;\n    float _788;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _702;\n        if (!_644)\n        {\n            _702 = float(i) >= _429_lit.x;\n        }\n        else\n        {\n            _702 = _644;\n        }\n        if (_702)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_429_light_pos[i].w < 0.0f)\n        {\n            l = _429_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _728 = _429_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_728) / max(_429_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _429_light_color[i].w);\n            float3 _748 = float3(_728, _429_light_pos[i].z);\n            l = _748 / max(length(_748), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_429_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _429_light_shadow_v[i].x;\n                float2 param_3 = -_728;\n                float param_4 = _429_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            float2 param_6 = -_728;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_567)\n        {\n            _788 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _788 = 1.0f;\n        }\n        total += (_429_light_color[i].xyz * (att * _788));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _412 = fa_srgb_to_linear(param);\n        c = _412;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1034 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1038 = uv * _1034;\n    float _1044 = _1034.x;\n    float _1046 = _1034.y;\n    float _1048 = clamp(shape_rs.x, 0.0f, min(_1044, _1046));\n    float2 _1059 = (abs(_1038) - _1034) + _1048.xx;\n    float d = (length(max(_1059, 0.0f.xx)) + min(max(_1059.x, _1059.y), 0.0f)) - _1048;\n    float ax = params.y;\n    bool _1080 = params.y > 15.0f;\n    if (_1080)\n    {\n        ax -= 20.0f;\n    }\n    float _1091;\n    if (ax <= (-1.5f))\n    {\n        _1091 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1091 = 0.0f;\n    }\n    if (_1091 > 0.0f)\n    {\n        float _1105 = _1091 * 0.5f;\n        d = abs(d + _1105) - _1105;\n    }\n    float _1113 = fwidth(d);\n    float _1114 = max(_1113, 9.9999997473787516355514526367188e-05f);\n    float _1124 = clamp(0.5f - (d / max(shape_rs.y, _1114)), 0.0f, 1.0f);\n    float _1129;\n    if (shape_rs.y > _1114)\n    {\n        _1129 = (_1124 * _1124) * (3.0f - (2.0f * _1124));\n    }\n    else\n    {\n        _1129 = _1124;\n    }\n    float4 c = color;\n    bool _1151 = (_1091 <= 0.0f) && (ax > (-0.5f));\n    if (_1151)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1166 = cos(ax);\n            float _1168 = sin(ax);\n            g = ((dot(_1038, float2(_1166, _1168)) / max((abs(_1166) * _1044) + (abs(_1168) * _1046), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1080)\n        {\n            float4 _1211 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1211;\n            float3 param = _1211.xyz;\n            float param_1 = xform.y;\n            float3 _1218 = fa_tex_fix(param, param_1);\n            float4 _2006 = c;\n            _2006.x = _1218.x;\n            _2006.y = _1218.y;\n            _2006.z = _1218.z;\n            c = _2006;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1230 = scene_rgb(param_2);\n            float4 _1255 = lerp(float4(color.xyz * color.w, color.w), float4(_1230 * color2.w, color2.w), g.xxxx);\n            float _1257 = _1255.w;\n            float3 _1260;\n            if (_1257 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1260 = _1255.xyz / _1257.xxx;\n            }\n            else\n            {\n                _1260 = color.xyz;\n            }\n            c = float4(_1260, _1257);\n        }\n    }\n    float4 _2015 = c;\n    _2015.w = _2015.w * _1129;\n    c = _2015;\n    if (_1151 || (shape_rs.y > 0.0f))\n    {\n        float _1301 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1310 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1310 + (_1301 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1316 = fa_srgb_to_linear(param_4);\n            float4 _2018 = c;\n            _2018.x = _1316.x;\n            _2018.y = _1316.y;\n            _2018.z = _1316.z;\n            c = _2018;\n        }\n        else\n        {\n            float4 _1326 = c;\n            float3 _1329 = _1326.xyz + (_1301 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2025 = _1326;\n            _2025.x = _1329.x;\n            _2025.y = _1329.y;\n            _2025.z = _1329.z;\n            c = _2025;\n        }\n        float4 _2030 = c;\n        _2030.w = clamp(_2030.w + ((_1301 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2030.w)), 0.0f, 1.0f);\n        c = _2030;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _825 = float2(_429_fx_rim_uv.x, 0.0f);\n    float4 _827 = tex.Sample(smp, uv - _825);\n    float _828 = _827.w;\n    float4 _838 = tex.Sample(smp, uv + _825);\n    float _839 = _838.w;\n    float2 _847 = float2(0.0f, _429_fx_rim_uv.y);\n    float4 _849 = tex.Sample(smp, uv - _847);\n    float _850 = _849.w;\n    float4 _860 = tex.Sample(smp, uv + _847);\n    float _861 = _860.w;\n    float _876 = _828 - _839;\n    float _879 = _861 - _850;\n    float _889 = cos(params.y);\n    float _891 = sin(params.y);\n    float2 _917 = ((float2(_889, _891) * _876) + ((float2(-_891, _889) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _879)) / max(length(float2(_876, _879)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _429_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_429_light_pos[i].w < 0.0f)\n        {\n            to_l = _429_light_pos[i].xy / max(length(_429_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _963 = _429_light_pos[i].xy - world_xy;\n            float _966 = length(_963);\n            att = pow(clamp(1.0f - (_966 / max(_429_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _429_light_color[i].w);\n            to_l = _963 / max(_966, 9.9999997473787516355514526367188e-05f).xx;\n            if (_429_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _429_light_shadow_v[i].x;\n                float2 param_1 = -_963;\n                float param_2 = _429_light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            float2 param_4 = -_963;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (_429_light_color[i].xyz * (att * max(dot(_917, to_l), 0.0f)));\n    }\n    return (sum * _429_fx_rim.xyz) * (a0 * (1.0f - min(min(_828, _839), min(_850, _861))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _435 = gl_FragCoord.xy * _429_fa_target.xy;\n    float _439 = _435.y;\n    return float2(_435.x, lerp(_439, 1.0f - _439, _429_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _480 = base_mode < 0.5f;\n    bool _491;\n    if (!_480)\n    {\n        _491 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _491 = _480;\n    }\n    float _492;\n    if (_491)\n    {\n        _492 = shape_half.x;\n    }\n    else\n    {\n        _492 = 0.0f;\n    }\n    QuadInput _1956 = { uv, color, world_xy, fa_screen_uv(), _429_fa_time.x, base_mode, 0.0f.xxxx, _492 };\n    return _1956;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _511 = i.screen_uv.x < _508_cut;\n    bool _520;\n    if (!_511)\n    {\n        _520 = i.screen_uv.y < _508_cutY;\n    }\n    else\n    {\n        _520 = _511;\n    }\n    if (_520)\n    {\n        discard;\n    }\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1356 = params.x > 31.5f;\n    if (_1356)\n    {\n        mode -= 32.0f;\n    }\n    float _1364 = mode;\n    bool _1366 = _1364 > 15.5f;\n    if (_1366)\n    {\n        mode -= 16.0f;\n    }\n    float _1374 = mode;\n    bool _1376 = _1374 > 7.5f;\n    if (_1376)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1366)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1366)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1438 = tex_color(param_5);\n                float4 _1440 = _1438 * color;\n                float4 param_6 = _1440;\n                float param_7 = mode;\n                float _1447 = _1440.w;\n                frag_color = float4(lit_color(param_6, param_7), _1447);\n                if (_429_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1447;\n                    float param_9 = mode;\n                    float4 _1463 = frag_color;\n                    float3 _1465 = _1463.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1465.x;\n                    frag_color.y = _1465.y;\n                    frag_color.z = _1465.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1495 = length(uv);\n                    float _1498 = fwidth(_1495);\n                    float _1499 = max(_1498, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1495) / _1499) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1495) / _1499) + 0.5f, 0.0f, 1.0f) * clamp(((_1495 - params.y) / _1499) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1539 = clamp(1.0f - _1495, 0.0f, 1.0f);\n                            cov = (_1539 * _1539) * (3.0f - (2.0f * _1539));\n                        }\n                    }\n                    float3 _1548;\n                    if (_1366)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1548 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1548 = color.xyz;\n                    }\n                    frag_color = float4(_1548, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_429_fx_emit.w > 0.5f)\n    {\n        float3 e = _429_fx_emit.xyz;\n        if (_429_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _429_fx_emit_uv.xy) + _429_fx_emit_uv.zw).xyz;\n            float param_13 = _429_fx_emit.w - 2.0f;\n            float3 _1603 = fa_tex_fix(param_12, param_13);\n            e *= _1603;\n        }\n        float4 _1607 = frag_color;\n        float3 _1609 = _1607.xyz + e;\n        frag_color.x = _1609.x;\n        frag_color.y = _1609.y;\n        frag_color.z = _1609.z;\n    }\n    float param_14 = mode;\n    float4 _1936 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _1938 = { _1936 };\n    QuadSurface param_16 = _1938;\n    fragment(param_15, param_16);\n    _1936 = param_16.color;\n    frag_color = param_16.color;\n    if (_1356)\n    {\n        float4 _1635 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1640 = scene_rgb(param_17);\n        float3 _1644 = lerp(_1635.xyz, _1640, color2.w.xxx);\n        frag_color.x = _1644.x;\n        frag_color.y = _1644.y;\n        frag_color.z = _1644.z;\n    }\n    if (_1376)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1668 = _429_fog_col.w > 0.0f;\n    bool _1676;\n    if (!_1668)\n    {\n        _1676 = _429_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1676 = _1668;\n    }\n    if (_1676)\n    {\n        float3 _1690 = float3(world_xy, world_z) - _429_fog_eye.xyz;\n        float _1697 = dot(_1690, _429_fog_c.xyz);\n        bool _1701 = _429_fog_c.w > 0.5f;\n        float _1702;\n        if (_1701)\n        {\n            _1702 = _1697;\n        }\n        else\n        {\n            _1702 = length(_1690);\n        }\n        float _1714 = _1702 - _429_fog_b.x;\n        if (_1714 > 0.0f)\n        {\n            float _1723 = _429_fog_col.w * _1714;\n            float tau = _1723 * _1723;\n            if (_429_fog_b.y > 0.0f)\n            {\n                float _1739;\n                if (_1701)\n                {\n                    _1739 = world_xy.y - (_429_fog_c.y * _1697);\n                }\n                else\n                {\n                    _1739 = _429_fog_eye.y;\n                }\n                float _1760 = lerp(_1739, world_xy.y, clamp(_429_fog_b.x / _1702, 0.0f, 1.0f));\n                float _1764 = world_xy.y - _1760;\n                float _1769 = _1760 - _429_fog_b.z;\n                float _1774 = world_xy.y - _429_fog_b.z;\n                bool _1777 = _1769 <= 0.0f;\n                bool _1778 = !_1777;\n                bool _1784;\n                if (_1778)\n                {\n                    _1784 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1784 = _1777;\n                }\n                float _1785;\n                if (_1784)\n                {\n                    _1785 = _429_fog_b.y;\n                }\n                else\n                {\n                    _1785 = _429_fog_b.y * exp(-min(_429_fog_b.w * _1769, 80.0f));\n                }\n                bool _1812;\n                if (_1778)\n                {\n                    _1812 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1812 = _1777;\n                }\n                float _1813;\n                if (_1812)\n                {\n                    _1813 = _429_fog_b.y * _1769;\n                }\n                else\n                {\n                    _1813 = (_429_fog_b.y * (1.0f - exp(-min(_429_fog_b.w * _1769, 80.0f)))) / _429_fog_b.w;\n                }\n                bool _1838 = _1774 <= 0.0f;\n                bool _1845;\n                if (!_1838)\n                {\n                    _1845 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1845 = _1838;\n                }\n                float _1846;\n                if (_1845)\n                {\n                    _1846 = _429_fog_b.y * _1774;\n                }\n                else\n                {\n                    _1846 = (_429_fog_b.y * (1.0f - exp(-min(_429_fog_b.w * _1774, 80.0f)))) / _429_fog_b.w;\n                }\n                float _1873;\n                if (abs(_1764) < 0.001000000047497451305389404296875f)\n                {\n                    _1873 = _1785;\n                }\n                else\n                {\n                    _1873 = (_1846 - _1813) / _1764;\n                }\n                tau += (_1714 * max(_1873, 0.0f));\n            }\n            float4 _1896 = frag_color;\n            float3 _1904 = lerp(_1896.xyz, _429_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1904.x;\n            frag_color.y = _1904.y;\n            frag_color.z = _1904.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_429",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_508",
            "hlsl_register_b_n": 5
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
          },
          {
            "texture": {
              "slot": 12,
              "stage": "fragment",
              "name": "fx_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
            }
          },
          {
            "texture": {
              "slot": 13,
              "stage": "fragment",
              "name": "fx_cookie_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 5
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
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fx_cookie_tex_light_smp",
            "view_name": "fx_cookie_tex",
            "sampler_name": "light_smp",
            "view_slot": 13,
            "sampler_slot": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fx_emissive_tex_smp",
            "view_name": "fx_emissive_tex",
            "sampler_name": "smp",
            "view_slot": 12,
            "sampler_slot": 0
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _129_lit : packoffset(c0);\n    float4 _129_ambient : packoffset(c1);\n    float4 _129_normal_uv : packoffset(c2);\n    float4 _129_flat_ambient : packoffset(c3);\n    float4 _129_light_map : packoffset(c4);\n    float4 _129_light_pos[16] : packoffset(c5);\n    float4 _129_light_color[16] : packoffset(c21);\n    float4 _129_light_shadow_v[16] : packoffset(c37);\n    float4 _129_fog_col : packoffset(c53);\n    float4 _129_fog_b : packoffset(c54);\n    float4 _129_fog_c : packoffset(c55);\n    float4 _129_fog_eye : packoffset(c56);\n    float4 _129_fa_time : packoffset(c57);\n    float4 _129_fa_target : packoffset(c58);\n    float4 _129_fx_emit : packoffset(c59);\n    float4 _129_fx_emit_uv : packoffset(c60);\n    float4 _129_fx_rim : packoffset(c61);\n    float4 _129_fx_rim_uv : packoffset(c62);\n    float4 _129_light_cookie[16] : packoffset(c63);\n    float4 _129_light_cookie_xf[16] : packoffset(c79);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _215_cut : packoffset(c0);\n    float _215_fa_pad0 : packoffset(c0.y);\n    float _215_fa_pad1 : packoffset(c0.z);\n    float _215_fa_pad2 : packoffset(c0.w);\n    float _215_cutY : packoffset(c1);\n    float _215_fa_pad3 : packoffset(c1.y);\n    float _215_fa_pad4 : packoffset(c1.z);\n    float _215_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _136 = gl_FragCoord.xy * _129_fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, lerp(_142, 1.0f - _142, _129_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5f;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0f;\n    }\n    QuadInput _328 = { uv, color, world_xy, fa_screen_uv(), _129_fa_time.x, base_mode, 0.0f.xxxx, _198 };\n    return _328;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _218 = i.screen_uv.x < _215_cut;\n    bool _227;\n    if (!_218)\n    {\n        _227 = i.screen_uv.y < _215_cutY;\n    }\n    else\n    {\n        _227 = _218;\n    }\n    if (_227)\n    {\n        discard;\n    }\n}\n\nvoid frag_main()\n{\n    float4 _243 = tex.Sample(smp, uv);\n    float3 param = _243.xyz;\n    float param_1 = xform.y;\n    float3 _254 = fa_tex_fix(param, param_1);\n    frag_color = float4(_254, _243.w) * color;\n    float param_2 = 0.0f;\n    float4 _308 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _310 = { _308 };\n    QuadSurface param_4 = _310;\n    fragment(param_3, param_4);\n    _308 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 1520,
            "struct_name": "quad_fs_params",
            "inst_name": "_129",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_215",
            "hlsl_register_b_n": 5
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
