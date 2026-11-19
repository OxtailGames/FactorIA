{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "ed7d6aa4bb6587a53460bdad882f96cecc84c68276eec459c73c25f578a29fd8",
  "slang": "hlsl5",
  "params": [],
  "textures": [
    "mask"
  ],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _150 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _150;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _306_lit : packoffset(c0);\n    float4 _306_ambient : packoffset(c1);\n    float4 _306_normal_uv : packoffset(c2);\n    float4 _306_flat_ambient : packoffset(c3);\n    float4 _306_light_map : packoffset(c4);\n    float4 _306_light_pos[16] : packoffset(c5);\n    float4 _306_light_color[16] : packoffset(c21);\n    float4 _306_light_shadow_v[16] : packoffset(c37);\n    float4 _306_fog_col : packoffset(c53);\n    float4 _306_fog_b : packoffset(c54);\n    float4 _306_fog_c : packoffset(c55);\n    float4 _306_fog_eye : packoffset(c56);\n    float4 _306_fa_time : packoffset(c57);\n    float4 _306_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> mask : register(t4);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 params;\nstatic float2 shape_half;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _245 = fa_linear_to_srgb(param);\n        c = _245;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _253 = fa_srgb_to_linear(param_1);\n            c = _253;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _264 = tex.Sample(smp, p);\n    float3 param = _264.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    return float4(_274, _264.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _87 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_87.x * 255.0f) + 0.5f) * 256.0f) + floor((_87.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _111 = length(d);\n    if (_111 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _125 = atan2(d.y, d.x);\n    float a = _125;\n    float _128;\n    if (_125 < 0.0f)\n    {\n        _128 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _128 = a;\n    }\n    a = _128;\n    float _140 = _128 * 162.9746551513671875f;\n    float _145 = min(floor(_140), 1023.0f);\n    float _152 = _145 + 1.0f;\n    float i1 = _152;\n    if (_152 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _145;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _111) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _111) + 0.5f, 0.0f, 1.0f), _140 - _145);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _381 = _306_lit.y > 0.5f;\n    if (_381)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _306_normal_uv.xy) + _306_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _405 = fa_tex_fix(param, param_1);\n        float3 _409 = (_405 * 2.0f) - 1.0f.xxx;\n        float _416 = cos(params.y);\n        float _418 = sin(params.y);\n        n = normalize(float3((float2(_416, _418) * _409.x) + ((float2(-_418, _416) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _409.y), max(_409.z, 0.0500000007450580596923828125f)));\n    }\n    bool _451 = !_381;\n    bool _457;\n    if (_451)\n    {\n        _457 = _306_lit.z > 0.5f;\n    }\n    else\n    {\n        _457 = _451;\n    }\n    float3 _460;\n    if (_457)\n    {\n        _460 = _306_flat_ambient.xyz;\n    }\n    else\n    {\n        _460 = _306_ambient.xyz;\n    }\n    float3 total = _460;\n    bool _477;\n    if (_457)\n    {\n        _477 = _306_lit.z < 1.5f;\n    }\n    else\n    {\n        _477 = _457;\n    }\n    if (_477)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _306_light_map.xy, 0.0f).xyz * _306_light_map.z);\n    }\n    float3 l;\n    float _596;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _517;\n        if (!_457)\n        {\n            _517 = float(i) >= _306_lit.x;\n        }\n        else\n        {\n            _517 = _457;\n        }\n        if (_517)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_306_light_pos[i].w < 0.0f)\n        {\n            l = _306_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _543 = _306_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_543) / max(_306_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _306_light_color[i].w);\n            float3 _563 = float3(_543, _306_light_pos[i].z);\n            l = _563 / max(length(_563), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_306_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _306_light_shadow_v[i].x;\n                float2 param_3 = -_543;\n                float param_4 = _306_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_381)\n        {\n            _596 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _596 = 1.0f;\n        }\n        total += (_306_light_color[i].xyz * (att * _596));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _291 = fa_srgb_to_linear(param);\n        c = _291;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _625 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _629 = uv * _625;\n    float _635 = _625.x;\n    float _637 = _625.y;\n    float _639 = clamp(shape_rs.x, 0.0f, min(_635, _637));\n    float2 _650 = (abs(_629) - _625) + _639.xx;\n    float d = (length(max(_650, 0.0f.xx)) + min(max(_650.x, _650.y), 0.0f)) - _639;\n    float ax = params.y;\n    bool _671 = params.y > 15.0f;\n    if (_671)\n    {\n        ax -= 20.0f;\n    }\n    float _682;\n    if (ax <= (-1.5f))\n    {\n        _682 = (-2.0f) - ax;\n    }\n    else\n    {\n        _682 = 0.0f;\n    }\n    if (_682 > 0.0f)\n    {\n        float _696 = _682 * 0.5f;\n        d = abs(d + _696) - _696;\n    }\n    float _704 = fwidth(d);\n    float _705 = max(_704, 9.9999997473787516355514526367188e-05f);\n    float _715 = clamp(0.5f - (d / max(shape_rs.y, _705)), 0.0f, 1.0f);\n    float _720;\n    if (shape_rs.y > _705)\n    {\n        _720 = (_715 * _715) * (3.0f - (2.0f * _715));\n    }\n    else\n    {\n        _720 = _715;\n    }\n    float4 c = color;\n    bool _742 = (_682 <= 0.0f) && (ax > (-0.5f));\n    if (_742)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _757 = cos(ax);\n            float _759 = sin(ax);\n            g = ((dot(_629, float2(_757, _759)) / max((abs(_757) * _635) + (abs(_759) * _637), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_671)\n        {\n            float4 _802 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _802;\n            float3 param = _802.xyz;\n            float param_1 = xform.y;\n            float3 _809 = fa_tex_fix(param, param_1);\n            float4 _1501 = c;\n            _1501.x = _809.x;\n            _1501.y = _809.y;\n            _1501.z = _809.z;\n            c = _1501;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _821 = scene_rgb(param_2);\n            float4 _846 = lerp(float4(color.xyz * color.w, color.w), float4(_821 * color2.w, color2.w), g.xxxx);\n            float _848 = _846.w;\n            float3 _851;\n            if (_848 > 9.9999997473787516355514526367188e-06f)\n            {\n                _851 = _846.xyz / _848.xxx;\n            }\n            else\n            {\n                _851 = color.xyz;\n            }\n            c = float4(_851, _848);\n        }\n    }\n    float4 _1510 = c;\n    _1510.w = _1510.w * _720;\n    c = _1510;\n    if (_742 || (shape_rs.y > 0.0f))\n    {\n        float _892 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _901 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _901 + (_892 * 0.0039215688593685626983642578125f).xxx;\n            float3 _907 = fa_srgb_to_linear(param_4);\n            float4 _1513 = c;\n            _1513.x = _907.x;\n            _1513.y = _907.y;\n            _1513.z = _907.z;\n            c = _1513;\n        }\n        else\n        {\n            float4 _917 = c;\n            float3 _920 = _917.xyz + (_892 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1520 = _917;\n            _1520.x = _920.x;\n            _1520.y = _920.y;\n            _1520.z = _920.z;\n            c = _1520;\n        }\n        float4 _1525 = c;\n        _1525.w = clamp(_1525.w + ((_892 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1525.w)), 0.0f, 1.0f);\n        c = _1525;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _313 = gl_FragCoord.xy * _306_fa_target.xy;\n    float _317 = _313.y;\n    return float2(_313.x, lerp(_317, 1.0f - _317, _306_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    QuadInput _1474 = { uv, color, world_xy, fa_screen_uv(), _306_fa_time.x, base_mode, 0.0f.xxxx };\n    return _1474;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _367 = mask.Sample(mask_smp, 0.0500000007450580596923828125f.xx);\n    s.color.x = _367.x;\n    s.color.y = _367.y;\n    s.color.z = _367.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _947 = params.x > 31.5f;\n    if (_947)\n    {\n        mode -= 32.0f;\n    }\n    float _955 = mode;\n    bool _957 = _955 > 15.5f;\n    if (_957)\n    {\n        mode -= 16.0f;\n    }\n    float _965 = mode;\n    bool _967 = _965 > 7.5f;\n    if (_967)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_957)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_957)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1031 = tex_color(param_5) * color;\n                float4 param_6 = _1031;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1031.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1067 = length(uv);\n                    float _1070 = fwidth(_1067);\n                    float _1071 = max(_1070, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1067) / _1071) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1067) / _1071) + 0.5f, 0.0f, 1.0f) * clamp(((_1067 - params.y) / _1071) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1112 = clamp(1.0f - _1067, 0.0f, 1.0f);\n                            cov = (_1112 * _1112) * (3.0f - (2.0f * _1112));\n                        }\n                    }\n                    float3 _1121;\n                    if (_957)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1121 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1121 = color.xyz;\n                    }\n                    frag_color = float4(_1121, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1458 = { frag_color };\n    QuadSurface param_12 = _1458;\n    fragment(param_11, param_12);\n    frag_color = param_12.color;\n    if (_947)\n    {\n        float4 _1158 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1163 = scene_rgb(param_13);\n        float3 _1167 = lerp(_1158.xyz, _1163, color2.w.xxx);\n        frag_color.x = _1167.x;\n        frag_color.y = _1167.y;\n        frag_color.z = _1167.z;\n    }\n    if (_967)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1191 = _306_fog_col.w > 0.0f;\n    bool _1199;\n    if (!_1191)\n    {\n        _1199 = _306_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1199 = _1191;\n    }\n    if (_1199)\n    {\n        float3 _1213 = float3(world_xy, world_z) - _306_fog_eye.xyz;\n        float _1220 = dot(_1213, _306_fog_c.xyz);\n        bool _1224 = _306_fog_c.w > 0.5f;\n        float _1225;\n        if (_1224)\n        {\n            _1225 = _1220;\n        }\n        else\n        {\n            _1225 = length(_1213);\n        }\n        float _1237 = _1225 - _306_fog_b.x;\n        if (_1237 > 0.0f)\n        {\n            float _1246 = _306_fog_col.w * _1237;\n            float tau = _1246 * _1246;\n            if (_306_fog_b.y > 0.0f)\n            {\n                float _1262;\n                if (_1224)\n                {\n                    _1262 = world_xy.y - (_306_fog_c.y * _1220);\n                }\n                else\n                {\n                    _1262 = _306_fog_eye.y;\n                }\n                float _1283 = lerp(_1262, world_xy.y, clamp(_306_fog_b.x / _1225, 0.0f, 1.0f));\n                float _1287 = world_xy.y - _1283;\n                float _1292 = _1283 - _306_fog_b.z;\n                float _1297 = world_xy.y - _306_fog_b.z;\n                bool _1300 = _1292 <= 0.0f;\n                bool _1301 = !_1300;\n                bool _1307;\n                if (_1301)\n                {\n                    _1307 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1307 = _1300;\n                }\n                float _1308;\n                if (_1307)\n                {\n                    _1308 = _306_fog_b.y;\n                }\n                else\n                {\n                    _1308 = _306_fog_b.y * exp(-min(_306_fog_b.w * _1292, 80.0f));\n                }\n                bool _1335;\n                if (_1301)\n                {\n                    _1335 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1335 = _1300;\n                }\n                float _1336;\n                if (_1335)\n                {\n                    _1336 = _306_fog_b.y * _1292;\n                }\n                else\n                {\n                    _1336 = (_306_fog_b.y * (1.0f - exp(-min(_306_fog_b.w * _1292, 80.0f)))) / _306_fog_b.w;\n                }\n                bool _1361 = _1297 <= 0.0f;\n                bool _1368;\n                if (!_1361)\n                {\n                    _1368 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1368 = _1361;\n                }\n                float _1369;\n                if (_1368)\n                {\n                    _1369 = _306_fog_b.y * _1297;\n                }\n                else\n                {\n                    _1369 = (_306_fog_b.y * (1.0f - exp(-min(_306_fog_b.w * _1297, 80.0f)))) / _306_fog_b.w;\n                }\n                float _1396;\n                if (abs(_1287) < 0.001000000047497451305389404296875f)\n                {\n                    _1396 = _1308;\n                }\n                else\n                {\n                    _1396 = (_1369 - _1336) / _1287;\n                }\n                tau += (_1237 * max(_1396, 0.0f));\n            }\n            float4 _1419 = frag_color;\n            float3 _1427 = lerp(_1419.xyz, _306_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1427.x;\n            frag_color.y = _1427.y;\n            frag_color.z = _1427.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    params = stage_input.params;\n    shape_half = stage_input.shape_half;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_306",
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 4
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
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 3
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
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3
          }
        ]
      }
    },
    "quad_plain": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _150 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _155 = _150;\n        _155.x = _82.x;\n        _155.y = _82.y;\n        _155.z = _82.z;\n        _150 = _155;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _150;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _125_lit : packoffset(c0);\n    float4 _125_ambient : packoffset(c1);\n    float4 _125_normal_uv : packoffset(c2);\n    float4 _125_flat_ambient : packoffset(c3);\n    float4 _125_light_map : packoffset(c4);\n    float4 _125_light_pos[16] : packoffset(c5);\n    float4 _125_light_color[16] : packoffset(c21);\n    float4 _125_light_shadow_v[16] : packoffset(c37);\n    float4 _125_fog_col : packoffset(c53);\n    float4 _125_fog_b : packoffset(c54);\n    float4 _125_fog_c : packoffset(c55);\n    float4 _125_fog_eye : packoffset(c56);\n    float4 _125_fa_time : packoffset(c57);\n    float4 _125_fa_target : packoffset(c58);\n};\n\nTexture2D<float4> mask : register(t1);\nSamplerState mask_smp : register(s3);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_half;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _99 = fa_linear_to_srgb(param);\n        c = _99;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _108 = fa_srgb_to_linear(param_1);\n            c = _108;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _132 = gl_FragCoord.xy * _125_fa_target.xy;\n    float _138 = _132.y;\n    return float2(_132.x, lerp(_138, 1.0f - _138, _125_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    QuadInput _291 = { uv, color, world_xy, fa_screen_uv(), _125_fa_time.x, base_mode, 0.0f.xxxx };\n    return _291;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float4 _195 = mask.Sample(mask_smp, 0.0500000007450580596923828125f.xx);\n    s.color.x = _195.x;\n    s.color.y = _195.y;\n    s.color.z = _195.z;\n}\n\nvoid frag_main()\n{\n    float4 _210 = tex.Sample(smp, uv);\n    float3 param = _210.xyz;\n    float param_1 = xform.y;\n    float3 _222 = fa_tex_fix(param, param_1);\n    frag_color = float4(_222, _210.w) * color;\n    float param_2 = 0.0f;\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _275 = { frag_color };\n    QuadSurface param_4 = _275;\n    fragment(param_3, param_4);\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_half = stage_input.shape_half;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_125",
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
              "slot": 4,
              "stage": "fragment",
              "name": "mask",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float",
              "hlsl_register_t_n": 1
            }
          }
        ],
        "samplers": [
          {
            "slot": 3,
            "stage": "fragment",
            "name": "mask_smp",
            "sampler_type": "filtering",
            "hlsl_register_s_n": 3
          },
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
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "mask_mask_smp",
            "view_name": "mask",
            "sampler_name": "mask_smp",
            "view_slot": 4,
            "sampler_slot": 3
          }
        ]
      }
    }
  }
}
