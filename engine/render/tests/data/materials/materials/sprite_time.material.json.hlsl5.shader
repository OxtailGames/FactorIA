{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _429_lit : packoffset(c0);\n    float4 _429_ambient : packoffset(c1);\n    float4 _429_normal_uv : packoffset(c2);\n    float4 _429_flat_ambient : packoffset(c3);\n    float4 _429_light_map : packoffset(c4);\n    float4 _429_light_pos[16] : packoffset(c5);\n    float4 _429_light_color[16] : packoffset(c21);\n    float4 _429_light_shadow_v[16] : packoffset(c37);\n    float4 _429_fog_col : packoffset(c53);\n    float4 _429_fog_b : packoffset(c54);\n    float4 _429_fog_c : packoffset(c55);\n    float4 _429_fog_eye : packoffset(c56);\n    float4 _429_fa_time : packoffset(c57);\n    float4 _429_fa_target : packoffset(c58);\n    float4 _429_fx_emit : packoffset(c59);\n    float4 _429_fx_emit_uv : packoffset(c60);\n    float4 _429_fx_rim : packoffset(c61);\n    float4 _429_fx_rim_uv : packoffset(c62);\n    float4 _429_light_cookie[16] : packoffset(c63);\n    float4 _429_light_cookie_xf[16] : packoffset(c79);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _367 = fa_linear_to_srgb(param);\n        c = _367;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _375 = fa_srgb_to_linear(param_1);\n            c = _375;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _386 = tex.Sample(smp, p);\n    float3 param = _386.xyz;\n    float param_1 = xform.y;\n    float3 _396 = fa_tex_fix(param, param_1);\n    return float4(_396, _386.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _111 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_111.x * 255.0f) + 0.5f) * 256.0f) + floor((_111.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _135 = length(d);\n    if (_135 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _149 = atan2(d.y, d.x);\n    float a = _149;\n    float _152;\n    if (_149 < 0.0f)\n    {\n        _152 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _152 = a;\n    }\n    a = _152;\n    float _164 = _152 * 162.9746551513671875f;\n    float _169 = min(floor(_164), 1023.0f);\n    float _176 = _169 + 1.0f;\n    float i1 = _176;\n    if (_176 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _169;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _135) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _135) + 0.5f, 0.0f, 1.0f), _164 - _169);\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _239 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _243 = _239.x + 0.5f;\n    float2 c = float2(_243, 0.5f - _239.y);\n    bool _251 = _243 >= 0.0f;\n    bool _257;\n    if (_251)\n    {\n        _257 = c.x <= 1.0f;\n    }\n    else\n    {\n        _257 = _251;\n    }\n    bool _263;\n    if (_257)\n    {\n        _263 = c.y >= 0.0f;\n    }\n    else\n    {\n        _263 = _257;\n    }\n    bool _269;\n    if (_263)\n    {\n        _269 = c.y <= 1.0f;\n    }\n    else\n    {\n        _269 = _263;\n    }\n    float2 _271 = c;\n    float2 _276 = clamp(_271, 0.001953125f.xx, 0.998046875f.xx);\n    c = _276;\n    return float3(cell.x + (_276.x * cell.w), cell.y + (_276.y * cell.z), float(_269));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_429_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _429_light_cookie[i];\n    float4 param_1 = _429_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _537 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _537.xy, 0.0f);\n    return cookie_value(param_3) * _537.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _559 = _429_lit.y > 0.5f;\n    if (_559)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _429_normal_uv.xy) + _429_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _583 = fa_tex_fix(param, param_1);\n        float3 _587 = (_583 * 2.0f) - 1.0f.xxx;\n        float _594 = cos(params.y);\n        float _596 = sin(params.y);\n        n = normalize(float3((float2(_594, _596) * _587.x) + ((float2(-_596, _594) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _587.y), max(_587.z, 0.0500000007450580596923828125f)));\n    }\n    bool _630 = !_559;\n    bool _636;\n    if (_630)\n    {\n        _636 = _429_lit.z > 0.5f;\n    }\n    else\n    {\n        _636 = _630;\n    }\n    float3 _639;\n    if (_636)\n    {\n        _639 = _429_flat_ambient.xyz;\n    }\n    else\n    {\n        _639 = _429_ambient.xyz;\n    }\n    float3 total = _639;\n    bool _656;\n    if (_636)\n    {\n        _656 = _429_lit.z < 1.5f;\n    }\n    else\n    {\n        _656 = _636;\n    }\n    if (_656)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _429_light_map.xy, 0.0f).xyz * _429_light_map.z);\n    }\n    float3 l;\n    float _780;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _694;\n        if (!_636)\n        {\n            _694 = float(i) >= _429_lit.x;\n        }\n        else\n        {\n            _694 = _636;\n        }\n        if (_694)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_429_light_pos[i].w < 0.0f)\n        {\n            l = _429_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _720 = _429_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_720) / max(_429_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _429_light_color[i].w);\n            float3 _740 = float3(_720, _429_light_pos[i].z);\n            l = _740 / max(length(_740), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_429_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _429_light_shadow_v[i].x;\n                float2 param_3 = -_720;\n                float param_4 = _429_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            float2 param_6 = -_720;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_559)\n        {\n            _780 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _780 = 1.0f;\n        }\n        total += (_429_light_color[i].xyz * (att * _780));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _412 = fa_srgb_to_linear(param);\n        c = _412;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1026 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1030 = uv * _1026;\n    float _1036 = _1026.x;\n    float _1038 = _1026.y;\n    float _1040 = clamp(shape_rs.x, 0.0f, min(_1036, _1038));\n    float2 _1051 = (abs(_1030) - _1026) + _1040.xx;\n    float d = (length(max(_1051, 0.0f.xx)) + min(max(_1051.x, _1051.y), 0.0f)) - _1040;\n    float ax = params.y;\n    bool _1072 = params.y > 15.0f;\n    if (_1072)\n    {\n        ax -= 20.0f;\n    }\n    float _1083;\n    if (ax <= (-1.5f))\n    {\n        _1083 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1083 = 0.0f;\n    }\n    if (_1083 > 0.0f)\n    {\n        float _1097 = _1083 * 0.5f;\n        d = abs(d + _1097) - _1097;\n    }\n    float _1105 = fwidth(d);\n    float _1106 = max(_1105, 9.9999997473787516355514526367188e-05f);\n    float _1116 = clamp(0.5f - (d / max(shape_rs.y, _1106)), 0.0f, 1.0f);\n    float _1121;\n    if (shape_rs.y > _1106)\n    {\n        _1121 = (_1116 * _1116) * (3.0f - (2.0f * _1116));\n    }\n    else\n    {\n        _1121 = _1116;\n    }\n    float4 c = color;\n    bool _1143 = (_1083 <= 0.0f) && (ax > (-0.5f));\n    if (_1143)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1158 = cos(ax);\n            float _1160 = sin(ax);\n            g = ((dot(_1030, float2(_1158, _1160)) / max((abs(_1158) * _1036) + (abs(_1160) * _1038), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1072)\n        {\n            float4 _1203 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1203;\n            float3 param = _1203.xyz;\n            float param_1 = xform.y;\n            float3 _1210 = fa_tex_fix(param, param_1);\n            float4 _1998 = c;\n            _1998.x = _1210.x;\n            _1998.y = _1210.y;\n            _1998.z = _1210.z;\n            c = _1998;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1222 = scene_rgb(param_2);\n            float4 _1247 = lerp(float4(color.xyz * color.w, color.w), float4(_1222 * color2.w, color2.w), g.xxxx);\n            float _1249 = _1247.w;\n            float3 _1252;\n            if (_1249 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1252 = _1247.xyz / _1249.xxx;\n            }\n            else\n            {\n                _1252 = color.xyz;\n            }\n            c = float4(_1252, _1249);\n        }\n    }\n    float4 _2007 = c;\n    _2007.w = _2007.w * _1121;\n    c = _2007;\n    if (_1143 || (shape_rs.y > 0.0f))\n    {\n        float _1293 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1302 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1302 + (_1293 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1308 = fa_srgb_to_linear(param_4);\n            float4 _2010 = c;\n            _2010.x = _1308.x;\n            _2010.y = _1308.y;\n            _2010.z = _1308.z;\n            c = _2010;\n        }\n        else\n        {\n            float4 _1318 = c;\n            float3 _1321 = _1318.xyz + (_1293 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2017 = _1318;\n            _2017.x = _1321.x;\n            _2017.y = _1321.y;\n            _2017.z = _1321.z;\n            c = _2017;\n        }\n        float4 _2022 = c;\n        _2022.w = clamp(_2022.w + ((_1293 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2022.w)), 0.0f, 1.0f);\n        c = _2022;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _817 = float2(_429_fx_rim_uv.x, 0.0f);\n    float4 _819 = tex.Sample(smp, uv - _817);\n    float _820 = _819.w;\n    float4 _830 = tex.Sample(smp, uv + _817);\n    float _831 = _830.w;\n    float2 _839 = float2(0.0f, _429_fx_rim_uv.y);\n    float4 _841 = tex.Sample(smp, uv - _839);\n    float _842 = _841.w;\n    float4 _852 = tex.Sample(smp, uv + _839);\n    float _853 = _852.w;\n    float _868 = _820 - _831;\n    float _871 = _853 - _842;\n    float _881 = cos(params.y);\n    float _883 = sin(params.y);\n    float2 _909 = ((float2(_881, _883) * _868) + ((float2(-_883, _881) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _871)) / max(length(float2(_868, _871)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _429_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_429_light_pos[i].w < 0.0f)\n        {\n            to_l = _429_light_pos[i].xy / max(length(_429_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _955 = _429_light_pos[i].xy - world_xy;\n            float _958 = length(_955);\n            att = pow(clamp(1.0f - (_958 / max(_429_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _429_light_color[i].w);\n            to_l = _955 / max(_958, 9.9999997473787516355514526367188e-05f).xx;\n            if (_429_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _429_light_shadow_v[i].x;\n                float2 param_1 = -_955;\n                float param_2 = _429_light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            float2 param_4 = -_955;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (_429_light_color[i].xyz * (att * max(dot(_909, to_l), 0.0f)));\n    }\n    return (sum * _429_fx_rim.xyz) * (a0 * (1.0f - min(min(_820, _831), min(_842, _853))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _435 = gl_FragCoord.xy * _429_fa_target.xy;\n    float _439 = _435.y;\n    return float2(_435.x, lerp(_439, 1.0f - _439, _429_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _480 = base_mode < 0.5f;\n    bool _491;\n    if (!_480)\n    {\n        _491 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _491 = _480;\n    }\n    float _492;\n    if (_491)\n    {\n        _492 = shape_half.x;\n    }\n    else\n    {\n        _492 = 0.0f;\n    }\n    QuadInput _1948 = { uv, color, world_xy, fa_screen_uv(), _429_fa_time.x, base_mode, 0.0f.xxxx, _492 };\n    return _1948;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25f, 0.0f, 1.0f);\n    s.color.y = 0.0f;\n    s.color.z = 0.0f;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1348 = params.x > 31.5f;\n    if (_1348)\n    {\n        mode -= 32.0f;\n    }\n    float _1356 = mode;\n    bool _1358 = _1356 > 15.5f;\n    if (_1358)\n    {\n        mode -= 16.0f;\n    }\n    float _1366 = mode;\n    bool _1368 = _1366 > 7.5f;\n    if (_1368)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1358)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1358)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1430 = tex_color(param_5);\n                float4 _1432 = _1430 * color;\n                float4 param_6 = _1432;\n                float param_7 = mode;\n                float _1439 = _1432.w;\n                frag_color = float4(lit_color(param_6, param_7), _1439);\n                if (_429_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1439;\n                    float param_9 = mode;\n                    float4 _1455 = frag_color;\n                    float3 _1457 = _1455.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1457.x;\n                    frag_color.y = _1457.y;\n                    frag_color.z = _1457.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1487 = length(uv);\n                    float _1490 = fwidth(_1487);\n                    float _1491 = max(_1490, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1487) / _1491) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1487) / _1491) + 0.5f, 0.0f, 1.0f) * clamp(((_1487 - params.y) / _1491) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1531 = clamp(1.0f - _1487, 0.0f, 1.0f);\n                            cov = (_1531 * _1531) * (3.0f - (2.0f * _1531));\n                        }\n                    }\n                    float3 _1540;\n                    if (_1358)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1540 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1540 = color.xyz;\n                    }\n                    frag_color = float4(_1540, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_429_fx_emit.w > 0.5f)\n    {\n        float3 e = _429_fx_emit.xyz;\n        if (_429_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _429_fx_emit_uv.xy) + _429_fx_emit_uv.zw).xyz;\n            float param_13 = _429_fx_emit.w - 2.0f;\n            float3 _1595 = fa_tex_fix(param_12, param_13);\n            e *= _1595;\n        }\n        float4 _1599 = frag_color;\n        float3 _1601 = _1599.xyz + e;\n        frag_color.x = _1601.x;\n        frag_color.y = _1601.y;\n        frag_color.z = _1601.z;\n    }\n    float param_14 = mode;\n    float4 _1928 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _1930 = { _1928 };\n    QuadSurface param_16 = _1930;\n    fragment(param_15, param_16);\n    _1928 = param_16.color;\n    frag_color = param_16.color;\n    if (_1348)\n    {\n        float4 _1627 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1632 = scene_rgb(param_17);\n        float3 _1636 = lerp(_1627.xyz, _1632, color2.w.xxx);\n        frag_color.x = _1636.x;\n        frag_color.y = _1636.y;\n        frag_color.z = _1636.z;\n    }\n    if (_1368)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1660 = _429_fog_col.w > 0.0f;\n    bool _1668;\n    if (!_1660)\n    {\n        _1668 = _429_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1668 = _1660;\n    }\n    if (_1668)\n    {\n        float3 _1682 = float3(world_xy, world_z) - _429_fog_eye.xyz;\n        float _1689 = dot(_1682, _429_fog_c.xyz);\n        bool _1693 = _429_fog_c.w > 0.5f;\n        float _1694;\n        if (_1693)\n        {\n            _1694 = _1689;\n        }\n        else\n        {\n            _1694 = length(_1682);\n        }\n        float _1706 = _1694 - _429_fog_b.x;\n        if (_1706 > 0.0f)\n        {\n            float _1715 = _429_fog_col.w * _1706;\n            float tau = _1715 * _1715;\n            if (_429_fog_b.y > 0.0f)\n            {\n                float _1731;\n                if (_1693)\n                {\n                    _1731 = world_xy.y - (_429_fog_c.y * _1689);\n                }\n                else\n                {\n                    _1731 = _429_fog_eye.y;\n                }\n                float _1752 = lerp(_1731, world_xy.y, clamp(_429_fog_b.x / _1694, 0.0f, 1.0f));\n                float _1756 = world_xy.y - _1752;\n                float _1761 = _1752 - _429_fog_b.z;\n                float _1766 = world_xy.y - _429_fog_b.z;\n                bool _1769 = _1761 <= 0.0f;\n                bool _1770 = !_1769;\n                bool _1776;\n                if (_1770)\n                {\n                    _1776 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1776 = _1769;\n                }\n                float _1777;\n                if (_1776)\n                {\n                    _1777 = _429_fog_b.y;\n                }\n                else\n                {\n                    _1777 = _429_fog_b.y * exp(-min(_429_fog_b.w * _1761, 80.0f));\n                }\n                bool _1804;\n                if (_1770)\n                {\n                    _1804 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1804 = _1769;\n                }\n                float _1805;\n                if (_1804)\n                {\n                    _1805 = _429_fog_b.y * _1761;\n                }\n                else\n                {\n                    _1805 = (_429_fog_b.y * (1.0f - exp(-min(_429_fog_b.w * _1761, 80.0f)))) / _429_fog_b.w;\n                }\n                bool _1830 = _1766 <= 0.0f;\n                bool _1837;\n                if (!_1830)\n                {\n                    _1837 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1837 = _1830;\n                }\n                float _1838;\n                if (_1837)\n                {\n                    _1838 = _429_fog_b.y * _1766;\n                }\n                else\n                {\n                    _1838 = (_429_fog_b.y * (1.0f - exp(-min(_429_fog_b.w * _1766, 80.0f)))) / _429_fog_b.w;\n                }\n                float _1865;\n                if (abs(_1756) < 0.001000000047497451305389404296875f)\n                {\n                    _1865 = _1777;\n                }\n                else\n                {\n                    _1865 = (_1838 - _1805) / _1756;\n                }\n                tau += (_1706 * max(_1865, 0.0f));\n            }\n            float4 _1888 = frag_color;\n            float3 _1896 = lerp(_1888.xyz, _429_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1896.x;\n            frag_color.y = _1896.y;\n            frag_color.z = _1896.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _144 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _149 = _144;\n        _149.x = _82.x;\n        _149.y = _82.y;\n        _149.z = _82.z;\n        _144 = _149;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _144;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _129_lit : packoffset(c0);\n    float4 _129_ambient : packoffset(c1);\n    float4 _129_normal_uv : packoffset(c2);\n    float4 _129_flat_ambient : packoffset(c3);\n    float4 _129_light_map : packoffset(c4);\n    float4 _129_light_pos[16] : packoffset(c5);\n    float4 _129_light_color[16] : packoffset(c21);\n    float4 _129_light_shadow_v[16] : packoffset(c37);\n    float4 _129_fog_col : packoffset(c53);\n    float4 _129_fog_b : packoffset(c54);\n    float4 _129_fog_c : packoffset(c55);\n    float4 _129_fog_eye : packoffset(c56);\n    float4 _129_fa_time : packoffset(c57);\n    float4 _129_fa_target : packoffset(c58);\n    float4 _129_fx_emit : packoffset(c59);\n    float4 _129_fx_emit_uv : packoffset(c60);\n    float4 _129_fx_rim : packoffset(c61);\n    float4 _129_fx_rim_uv : packoffset(c62);\n    float4 _129_light_cookie[16] : packoffset(c63);\n    float4 _129_light_cookie_xf[16] : packoffset(c79);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _136 = gl_FragCoord.xy * _129_fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, lerp(_142, 1.0f - _142, _129_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5f;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0f;\n    }\n    QuadInput _320 = { uv, color, world_xy, fa_screen_uv(), _129_fa_time.x, base_mode, 0.0f.xxxx, _198 };\n    return _320;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = clamp(i.time * 0.25f, 0.0f, 1.0f);\n    s.color.y = 0.0f;\n    s.color.z = 0.0f;\n}\n\nvoid frag_main()\n{\n    float4 _235 = tex.Sample(smp, uv);\n    float3 param = _235.xyz;\n    float param_1 = xform.y;\n    float3 _246 = fa_tex_fix(param, param_1);\n    frag_color = float4(_246, _235.w) * color;\n    float param_2 = 0.0f;\n    float4 _300 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _302 = { _300 };\n    QuadSurface param_4 = _302;\n    fragment(param_3, param_4);\n    _300 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
