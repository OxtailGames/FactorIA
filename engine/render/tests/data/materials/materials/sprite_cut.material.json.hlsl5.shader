{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "dac082249371b076675e61040e0115b7624fdfe0d386fccb444476b7af3a109f",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _306_lit : packoffset(c0);\n    float4 _306_ambient : packoffset(c1);\n    float4 _306_normal_uv : packoffset(c2);\n    float4 _306_flat_ambient : packoffset(c3);\n    float4 _306_light_map : packoffset(c4);\n    float4 _306_light_pos[16] : packoffset(c5);\n    float4 _306_light_color[16] : packoffset(c21);\n    float4 _306_light_shadow_v[16] : packoffset(c37);\n    float4 _306_fog_col : packoffset(c53);\n    float4 _306_fog_b : packoffset(c54);\n    float4 _306_fog_c : packoffset(c55);\n    float4 _306_fog_eye : packoffset(c56);\n    float4 _306_fa_time : packoffset(c57);\n    float4 _306_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _364_cut : packoffset(c0);\n    float _364_fa_pad0 : packoffset(c0.y);\n    float _364_fa_pad1 : packoffset(c0.z);\n    float _364_fa_pad2 : packoffset(c0.w);\n    float _364_cutY : packoffset(c1);\n    float _364_fa_pad3 : packoffset(c1.y);\n    float _364_fa_pad4 : packoffset(c1.z);\n    float _364_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 params;\nstatic float2 shape_half;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _245 = fa_linear_to_srgb(param);\n        c = _245;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _253 = fa_srgb_to_linear(param_1);\n            c = _253;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _264 = tex.Sample(smp, p);\n    float3 param = _264.xyz;\n    float param_1 = xform.y;\n    float3 _274 = fa_tex_fix(param, param_1);\n    return float4(_274, _264.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _87 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_87.x * 255.0f) + 0.5f) * 256.0f) + floor((_87.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _111 = length(d);\n    if (_111 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _125 = atan2(d.y, d.x);\n    float a = _125;\n    float _128;\n    if (_125 < 0.0f)\n    {\n        _128 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _128 = a;\n    }\n    a = _128;\n    float _140 = _128 * 162.9746551513671875f;\n    float _145 = min(floor(_140), 1023.0f);\n    float _152 = _145 + 1.0f;\n    float i1 = _152;\n    if (_152 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _145;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _111) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _111) + 0.5f, 0.0f, 1.0f), _140 - _145);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _386 = _306_lit.y > 0.5f;\n    if (_386)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _306_normal_uv.xy) + _306_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _410 = fa_tex_fix(param, param_1);\n        float3 _414 = (_410 * 2.0f) - 1.0f.xxx;\n        float _421 = cos(params.y);\n        float _423 = sin(params.y);\n        n = normalize(float3((float2(_421, _423) * _414.x) + ((float2(-_423, _421) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _414.y), max(_414.z, 0.0500000007450580596923828125f)));\n    }\n    bool _457 = !_386;\n    bool _463;\n    if (_457)\n    {\n        _463 = _306_lit.z > 0.5f;\n    }\n    else\n    {\n        _463 = _457;\n    }\n    float3 _466;\n    if (_463)\n    {\n        _466 = _306_flat_ambient.xyz;\n    }\n    else\n    {\n        _466 = _306_ambient.xyz;\n    }\n    float3 total = _466;\n    bool _483;\n    if (_463)\n    {\n        _483 = _306_lit.z < 1.5f;\n    }\n    else\n    {\n        _483 = _463;\n    }\n    if (_483)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _306_light_map.xy, 0.0f).xyz * _306_light_map.z);\n    }\n    float3 l;\n    float _602;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _523;\n        if (!_463)\n        {\n            _523 = float(i) >= _306_lit.x;\n        }\n        else\n        {\n            _523 = _463;\n        }\n        if (_523)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_306_light_pos[i].w < 0.0f)\n        {\n            l = _306_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _549 = _306_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_549) / max(_306_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _306_light_color[i].w);\n            float3 _569 = float3(_549, _306_light_pos[i].z);\n            l = _569 / max(length(_569), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_306_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _306_light_shadow_v[i].x;\n                float2 param_3 = -_549;\n                float param_4 = _306_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_386)\n        {\n            _602 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _602 = 1.0f;\n        }\n        total += (_306_light_color[i].xyz * (att * _602));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _291 = fa_srgb_to_linear(param);\n        c = _291;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _631 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _635 = uv * _631;\n    float _641 = _631.x;\n    float _643 = _631.y;\n    float _645 = clamp(shape_rs.x, 0.0f, min(_641, _643));\n    float2 _656 = (abs(_635) - _631) + _645.xx;\n    float d = (length(max(_656, 0.0f.xx)) + min(max(_656.x, _656.y), 0.0f)) - _645;\n    float ax = params.y;\n    bool _677 = params.y > 15.0f;\n    if (_677)\n    {\n        ax -= 20.0f;\n    }\n    float _688;\n    if (ax <= (-1.5f))\n    {\n        _688 = (-2.0f) - ax;\n    }\n    else\n    {\n        _688 = 0.0f;\n    }\n    if (_688 > 0.0f)\n    {\n        float _702 = _688 * 0.5f;\n        d = abs(d + _702) - _702;\n    }\n    float _710 = fwidth(d);\n    float _711 = max(_710, 9.9999997473787516355514526367188e-05f);\n    float _721 = clamp(0.5f - (d / max(shape_rs.y, _711)), 0.0f, 1.0f);\n    float _726;\n    if (shape_rs.y > _711)\n    {\n        _726 = (_721 * _721) * (3.0f - (2.0f * _721));\n    }\n    else\n    {\n        _726 = _721;\n    }\n    float4 c = color;\n    bool _748 = (_688 <= 0.0f) && (ax > (-0.5f));\n    if (_748)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _763 = cos(ax);\n            float _765 = sin(ax);\n            g = ((dot(_635, float2(_763, _765)) / max((abs(_763) * _641) + (abs(_765) * _643), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_677)\n        {\n            float4 _808 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _808;\n            float3 param = _808.xyz;\n            float param_1 = xform.y;\n            float3 _815 = fa_tex_fix(param, param_1);\n            float4 _1507 = c;\n            _1507.x = _815.x;\n            _1507.y = _815.y;\n            _1507.z = _815.z;\n            c = _1507;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _827 = scene_rgb(param_2);\n            float4 _852 = lerp(float4(color.xyz * color.w, color.w), float4(_827 * color2.w, color2.w), g.xxxx);\n            float _854 = _852.w;\n            float3 _857;\n            if (_854 > 9.9999997473787516355514526367188e-06f)\n            {\n                _857 = _852.xyz / _854.xxx;\n            }\n            else\n            {\n                _857 = color.xyz;\n            }\n            c = float4(_857, _854);\n        }\n    }\n    float4 _1516 = c;\n    _1516.w = _1516.w * _726;\n    c = _1516;\n    if (_748 || (shape_rs.y > 0.0f))\n    {\n        float _898 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _907 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _907 + (_898 * 0.0039215688593685626983642578125f).xxx;\n            float3 _913 = fa_srgb_to_linear(param_4);\n            float4 _1519 = c;\n            _1519.x = _913.x;\n            _1519.y = _913.y;\n            _1519.z = _913.z;\n            c = _1519;\n        }\n        else\n        {\n            float4 _923 = c;\n            float3 _926 = _923.xyz + (_898 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1526 = _923;\n            _1526.x = _926.x;\n            _1526.y = _926.y;\n            _1526.z = _926.z;\n            c = _1526;\n        }\n        float4 _1531 = c;\n        _1531.w = clamp(_1531.w + ((_898 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1531.w)), 0.0f, 1.0f);\n        c = _1531;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _313 = gl_FragCoord.xy * _306_fa_target.xy;\n    float _317 = _313.y;\n    return float2(_313.x, lerp(_317, 1.0f - _317, _306_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    QuadInput _1480 = { uv, color, world_xy, fa_screen_uv(), _306_fa_time.x, base_mode, 0.0f.xxxx };\n    return _1480;\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _367 = i.screen_uv.x < _364_cut;\n    bool _376;\n    if (!_367)\n    {\n        _376 = i.screen_uv.y < _364_cutY;\n    }\n    else\n    {\n        _376 = _367;\n    }\n    if (_376)\n    {\n        discard;\n    }\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _953 = params.x > 31.5f;\n    if (_953)\n    {\n        mode -= 32.0f;\n    }\n    float _961 = mode;\n    bool _963 = _961 > 15.5f;\n    if (_963)\n    {\n        mode -= 16.0f;\n    }\n    float _971 = mode;\n    bool _973 = _971 > 7.5f;\n    if (_973)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_963)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_963)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1037 = tex_color(param_5) * color;\n                float4 param_6 = _1037;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1037.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1073 = length(uv);\n                    float _1076 = fwidth(_1073);\n                    float _1077 = max(_1076, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1073) / _1077) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1073) / _1077) + 0.5f, 0.0f, 1.0f) * clamp(((_1073 - params.y) / _1077) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1118 = clamp(1.0f - _1073, 0.0f, 1.0f);\n                            cov = (_1118 * _1118) * (3.0f - (2.0f * _1118));\n                        }\n                    }\n                    float3 _1127;\n                    if (_963)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1127 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1127 = color.xyz;\n                    }\n                    frag_color = float4(_1127, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1464 = { frag_color };\n    QuadSurface param_12 = _1464;\n    fragment(param_11, param_12);\n    frag_color = param_12.color;\n    if (_953)\n    {\n        float4 _1164 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1169 = scene_rgb(param_13);\n        float3 _1173 = lerp(_1164.xyz, _1169, color2.w.xxx);\n        frag_color.x = _1173.x;\n        frag_color.y = _1173.y;\n        frag_color.z = _1173.z;\n    }\n    if (_973)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1197 = _306_fog_col.w > 0.0f;\n    bool _1205;\n    if (!_1197)\n    {\n        _1205 = _306_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1205 = _1197;\n    }\n    if (_1205)\n    {\n        float3 _1219 = float3(world_xy, world_z) - _306_fog_eye.xyz;\n        float _1226 = dot(_1219, _306_fog_c.xyz);\n        bool _1230 = _306_fog_c.w > 0.5f;\n        float _1231;\n        if (_1230)\n        {\n            _1231 = _1226;\n        }\n        else\n        {\n            _1231 = length(_1219);\n        }\n        float _1243 = _1231 - _306_fog_b.x;\n        if (_1243 > 0.0f)\n        {\n            float _1252 = _306_fog_col.w * _1243;\n            float tau = _1252 * _1252;\n            if (_306_fog_b.y > 0.0f)\n            {\n                float _1268;\n                if (_1230)\n                {\n                    _1268 = world_xy.y - (_306_fog_c.y * _1226);\n                }\n                else\n                {\n                    _1268 = _306_fog_eye.y;\n                }\n                float _1289 = lerp(_1268, world_xy.y, clamp(_306_fog_b.x / _1231, 0.0f, 1.0f));\n                float _1293 = world_xy.y - _1289;\n                float _1298 = _1289 - _306_fog_b.z;\n                float _1303 = world_xy.y - _306_fog_b.z;\n                bool _1306 = _1298 <= 0.0f;\n                bool _1307 = !_1306;\n                bool _1313;\n                if (_1307)\n                {\n                    _1313 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1313 = _1306;\n                }\n                float _1314;\n                if (_1313)\n                {\n                    _1314 = _306_fog_b.y;\n                }\n                else\n                {\n                    _1314 = _306_fog_b.y * exp(-min(_306_fog_b.w * _1298, 80.0f));\n                }\n                bool _1341;\n                if (_1307)\n                {\n                    _1341 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1341 = _1306;\n                }\n                float _1342;\n                if (_1341)\n                {\n                    _1342 = _306_fog_b.y * _1298;\n                }\n                else\n                {\n                    _1342 = (_306_fog_b.y * (1.0f - exp(-min(_306_fog_b.w * _1298, 80.0f)))) / _306_fog_b.w;\n                }\n                bool _1367 = _1303 <= 0.0f;\n                bool _1374;\n                if (!_1367)\n                {\n                    _1374 = _306_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1374 = _1367;\n                }\n                float _1375;\n                if (_1374)\n                {\n                    _1375 = _306_fog_b.y * _1303;\n                }\n                else\n                {\n                    _1375 = (_306_fog_b.y * (1.0f - exp(-min(_306_fog_b.w * _1303, 80.0f)))) / _306_fog_b.w;\n                }\n                float _1402;\n                if (abs(_1293) < 0.001000000047497451305389404296875f)\n                {\n                    _1402 = _1314;\n                }\n                else\n                {\n                    _1402 = (_1375 - _1342) / _1293;\n                }\n                tau += (_1243 * max(_1402, 0.0f));\n            }\n            float4 _1425 = frag_color;\n            float3 _1433 = lerp(_1425.xyz, _306_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1433.x;\n            frag_color.y = _1433.y;\n            frag_color.z = _1433.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    params = stage_input.params;\n    shape_half = stage_input.shape_half;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_364",
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
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _125_lit : packoffset(c0);\n    float4 _125_ambient : packoffset(c1);\n    float4 _125_normal_uv : packoffset(c2);\n    float4 _125_flat_ambient : packoffset(c3);\n    float4 _125_light_map : packoffset(c4);\n    float4 _125_light_pos[16] : packoffset(c5);\n    float4 _125_light_color[16] : packoffset(c21);\n    float4 _125_light_shadow_v[16] : packoffset(c37);\n    float4 _125_fog_col : packoffset(c53);\n    float4 _125_fog_b : packoffset(c54);\n    float4 _125_fog_c : packoffset(c55);\n    float4 _125_fog_eye : packoffset(c56);\n    float4 _125_fa_time : packoffset(c57);\n    float4 _125_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _187_cut : packoffset(c0);\n    float _187_fa_pad0 : packoffset(c0.y);\n    float _187_fa_pad1 : packoffset(c0.z);\n    float _187_fa_pad2 : packoffset(c0.w);\n    float _187_cutY : packoffset(c1);\n    float _187_fa_pad3 : packoffset(c1.y);\n    float _187_fa_pad4 : packoffset(c1.z);\n    float _187_fa_pad5 : packoffset(c1.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_half;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _99 = fa_linear_to_srgb(param);\n        c = _99;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _108 = fa_srgb_to_linear(param_1);\n            c = _108;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _132 = gl_FragCoord.xy * _125_fa_target.xy;\n    float _138 = _132.y;\n    return float2(_132.x, lerp(_138, 1.0f - _138, _125_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    QuadInput _296 = { uv, color, world_xy, fa_screen_uv(), _125_fa_time.x, base_mode, 0.0f.xxxx };\n    return _296;\n}\n\nvoid fragment(QuadInput i, QuadSurface s)\n{\n    bool _190 = i.screen_uv.x < _187_cut;\n    bool _199;\n    if (!_190)\n    {\n        _199 = i.screen_uv.y < _187_cutY;\n    }\n    else\n    {\n        _199 = _190;\n    }\n    if (_199)\n    {\n        discard;\n    }\n}\n\nvoid frag_main()\n{\n    float4 _215 = tex.Sample(smp, uv);\n    float3 param = _215.xyz;\n    float param_1 = xform.y;\n    float3 _227 = fa_tex_fix(param, param_1);\n    frag_color = float4(_227, _215.w) * color;\n    float param_2 = 0.0f;\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _280 = { frag_color };\n    QuadSurface param_4 = _280;\n    fragment(param_3, param_4);\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_half = stage_input.shape_half;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_187",
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
