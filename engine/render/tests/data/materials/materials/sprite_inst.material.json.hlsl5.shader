{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "hlsl5",
  "params": [
    "boost"
  ],
  "textures": [],
  "kind": "sprite",
  "instanced": [
    {
      "name": "shift",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _107_view_proj : packoffset(c0);\n    float4 _107_cspace : packoffset(c4);\n    float4 _107_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    float4 fa_inst_d0 : TEXCOORD7;\n    float4 fa_inst_d1 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    float3 _184 = position;\n    float2 _185 = texcoord0;\n    float4 _186 = color0;\n    if (_107_cspace.x > 0.5f)\n    {\n        float3 param_3 = color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex _193 = { _184, _185, _186 };\n    QuadVertex param_4 = _193;\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mul(float4(param_4.world_pos, 1.0f), _107_view_proj);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = _107_cspace.xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _323_lit : packoffset(c0);\n    float4 _323_ambient : packoffset(c1);\n    float4 _323_normal_uv : packoffset(c2);\n    float4 _323_flat_ambient : packoffset(c3);\n    float4 _323_light_map : packoffset(c4);\n    float4 _323_light_pos[16] : packoffset(c5);\n    float4 _323_light_color[16] : packoffset(c21);\n    float4 _323_light_shadow_v[16] : packoffset(c37);\n    float4 _323_fog_col : packoffset(c53);\n    float4 _323_fog_b : packoffset(c54);\n    float4 _323_fog_c : packoffset(c55);\n    float4 _323_fog_eye : packoffset(c56);\n    float4 _323_fa_time : packoffset(c57);\n    float4 _323_fa_target : packoffset(c58);\n    float4 _323_fa_scene : packoffset(c59);\n    float4 _323_fa_world_uv[3] : packoffset(c60);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _413_boost : packoffset(c0);\n    float _413_fa_pad0 : packoffset(c0.y);\n    float _413_fa_pad1 : packoffset(c0.z);\n    float _413_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _256 = fa_linear_to_srgb(param);\n        c = _256;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _264 = fa_srgb_to_linear(param_1);\n            c = _264;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _275 = tex.Sample(smp, p);\n    float3 param = _275.xyz;\n    float param_1 = xform.y;\n    float3 _285 = fa_tex_fix(param, param_1);\n    return float4(_285, _275.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _98 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_98.x * 255.0f) + 0.5f) * 256.0f) + floor((_98.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _122 = length(d);\n    if (_122 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _136 = atan2(d.y, d.x);\n    float a = _136;\n    float _139;\n    if (_136 < 0.0f)\n    {\n        _139 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _139 = a;\n    }\n    a = _139;\n    float _151 = _139 * 162.9746551513671875f;\n    float _156 = min(floor(_151), 1023.0f);\n    float _163 = _156 + 1.0f;\n    float i1 = _163;\n    if (_163 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _156;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _122) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _122) + 0.5f, 0.0f, 1.0f), _151 - _156);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _437 = _323_lit.y > 0.5f;\n    if (_437)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _323_normal_uv.xy) + _323_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _461 = fa_tex_fix(param, param_1);\n        float3 _465 = (_461 * 2.0f) - 1.0f.xxx;\n        float _472 = cos(params.y);\n        float _474 = sin(params.y);\n        n = normalize(float3((float2(_472, _474) * _465.x) + ((float2(-_474, _472) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _465.y), max(_465.z, 0.0500000007450580596923828125f)));\n    }\n    bool _508 = !_437;\n    bool _514;\n    if (_508)\n    {\n        _514 = _323_lit.z > 0.5f;\n    }\n    else\n    {\n        _514 = _508;\n    }\n    float3 _517;\n    if (_514)\n    {\n        _517 = _323_flat_ambient.xyz;\n    }\n    else\n    {\n        _517 = _323_ambient.xyz;\n    }\n    float3 total = _517;\n    bool _534;\n    if (_514)\n    {\n        _534 = _323_lit.z < 1.5f;\n    }\n    else\n    {\n        _534 = _514;\n    }\n    if (_534)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _323_light_map.xy, 0.0f).xyz * _323_light_map.z);\n    }\n    float3 l;\n    float _652;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _574;\n        if (!_514)\n        {\n            _574 = float(i) >= _323_lit.x;\n        }\n        else\n        {\n            _574 = _514;\n        }\n        if (_574)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_323_light_pos[i].w < 0.0f)\n        {\n            l = _323_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _600 = _323_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_600) / max(_323_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _323_light_color[i].w);\n            float3 _620 = float3(_600, _323_light_pos[i].z);\n            l = _620 / max(length(_620), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_323_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _323_light_shadow_v[i].x;\n                float2 param_3 = -_600;\n                float param_4 = _323_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_437)\n        {\n            _652 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _652 = 1.0f;\n        }\n        total += (_323_light_color[i].xyz * (att * _652));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _302 = fa_srgb_to_linear(param);\n        c = _302;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _680 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _684 = uv * _680;\n    float _690 = _680.x;\n    float _692 = _680.y;\n    float _694 = clamp(shape_rs.x, 0.0f, min(_690, _692));\n    float2 _705 = (abs(_684) - _680) + _694.xx;\n    float d = (length(max(_705, 0.0f.xx)) + min(max(_705.x, _705.y), 0.0f)) - _694;\n    float ax = params.y;\n    bool _726 = params.y > 15.0f;\n    if (_726)\n    {\n        ax -= 20.0f;\n    }\n    float _737;\n    if (ax <= (-1.5f))\n    {\n        _737 = (-2.0f) - ax;\n    }\n    else\n    {\n        _737 = 0.0f;\n    }\n    if (_737 > 0.0f)\n    {\n        float _751 = _737 * 0.5f;\n        d = abs(d + _751) - _751;\n    }\n    float _759 = fwidth(d);\n    float _760 = max(_759, 9.9999997473787516355514526367188e-05f);\n    float _770 = clamp(0.5f - (d / max(shape_rs.y, _760)), 0.0f, 1.0f);\n    float _775;\n    if (shape_rs.y > _760)\n    {\n        _775 = (_770 * _770) * (3.0f - (2.0f * _770));\n    }\n    else\n    {\n        _775 = _770;\n    }\n    float4 c = color;\n    bool _797 = (_737 <= 0.0f) && (ax > (-0.5f));\n    if (_797)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _812 = cos(ax);\n            float _814 = sin(ax);\n            g = ((dot(_684, float2(_812, _814)) / max((abs(_812) * _690) + (abs(_814) * _692), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_726)\n        {\n            float4 _857 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _857;\n            float3 param = _857.xyz;\n            float param_1 = xform.y;\n            float3 _864 = fa_tex_fix(param, param_1);\n            float4 _1561 = c;\n            _1561.x = _864.x;\n            _1561.y = _864.y;\n            _1561.z = _864.z;\n            c = _1561;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _876 = scene_rgb(param_2);\n            float4 _901 = lerp(float4(color.xyz * color.w, color.w), float4(_876 * color2.w, color2.w), g.xxxx);\n            float _903 = _901.w;\n            float3 _906;\n            if (_903 > 9.9999997473787516355514526367188e-06f)\n            {\n                _906 = _901.xyz / _903.xxx;\n            }\n            else\n            {\n                _906 = color.xyz;\n            }\n            c = float4(_906, _903);\n        }\n    }\n    float4 _1570 = c;\n    _1570.w = _1570.w * _775;\n    c = _1570;\n    if (_797 || (shape_rs.y > 0.0f))\n    {\n        float _947 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _956 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _956 + (_947 * 0.0039215688593685626983642578125f).xxx;\n            float3 _962 = fa_srgb_to_linear(param_4);\n            float4 _1573 = c;\n            _1573.x = _962.x;\n            _1573.y = _962.y;\n            _1573.z = _962.z;\n            c = _1573;\n        }\n        else\n        {\n            float4 _972 = c;\n            float3 _975 = _972.xyz + (_947 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1580 = _972;\n            _1580.x = _975.x;\n            _1580.y = _975.y;\n            _1580.z = _975.z;\n            c = _1580;\n        }\n        float4 _1585 = c;\n        _1585.w = clamp(_1585.w + ((_947 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1585.w)), 0.0f, 1.0f);\n        c = _1585;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _330 = gl_FragCoord.xy * _323_fa_target.xy;\n    float _334 = _330.y;\n    return float2(_330.x, lerp(_334, 1.0f - _334, _323_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _376 = base_mode < 0.5f;\n    bool _387;\n    if (!_376)\n    {\n        _387 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _387 = _376;\n    }\n    float _388;\n    if (_387)\n    {\n        _388 = shape_half.x;\n    }\n    else\n    {\n        _388 = 0.0f;\n    }\n    QuadInput _1534 = { uv, color, world_xy, fa_screen_uv(), _323_fa_time.x, base_mode, 0.0f.xxxx, _388 };\n    return _1534;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _308 = scene_rgb(param);\n    return _308;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _416 = fa_scene_rgb(param) * _413_boost;\n    s.color.x = _416.x;\n    s.color.y = _416.y;\n    s.color.z = _416.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1002 = params.x > 31.5f;\n    if (_1002)\n    {\n        mode -= 32.0f;\n    }\n    float _1010 = mode;\n    bool _1012 = _1010 > 15.5f;\n    if (_1012)\n    {\n        mode -= 16.0f;\n    }\n    float _1020 = mode;\n    bool _1022 = _1020 > 7.5f;\n    if (_1022)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1012)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1012)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1086 = tex_color(param_5) * color;\n                float4 param_6 = _1086;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1086.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1121 = length(uv);\n                    float _1124 = fwidth(_1121);\n                    float _1125 = max(_1124, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1121) / _1125) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1121) / _1125) + 0.5f, 0.0f, 1.0f) * clamp(((_1121 - params.y) / _1125) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1165 = clamp(1.0f - _1121, 0.0f, 1.0f);\n                            cov = (_1165 * _1165) * (3.0f - (2.0f * _1165));\n                        }\n                    }\n                    float3 _1174;\n                    if (_1012)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1174 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1174 = color.xyz;\n                    }\n                    frag_color = float4(_1174, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1514 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1516 = { _1514 };\n    QuadSurface param_12 = _1516;\n    fragment(param_11, param_12);\n    _1514 = param_12.color;\n    frag_color = param_12.color;\n    if (_1002)\n    {\n        float4 _1212 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1217 = scene_rgb(param_13);\n        float3 _1221 = lerp(_1212.xyz, _1217, color2.w.xxx);\n        frag_color.x = _1221.x;\n        frag_color.y = _1221.y;\n        frag_color.z = _1221.z;\n    }\n    if (_1022)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1245 = _323_fog_col.w > 0.0f;\n    bool _1253;\n    if (!_1245)\n    {\n        _1253 = _323_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1253 = _1245;\n    }\n    if (_1253)\n    {\n        float3 _1267 = float3(world_xy, world_z) - _323_fog_eye.xyz;\n        float _1274 = dot(_1267, _323_fog_c.xyz);\n        bool _1278 = _323_fog_c.w > 0.5f;\n        float _1279;\n        if (_1278)\n        {\n            _1279 = _1274;\n        }\n        else\n        {\n            _1279 = length(_1267);\n        }\n        float _1291 = _1279 - _323_fog_b.x;\n        if (_1291 > 0.0f)\n        {\n            float _1300 = _323_fog_col.w * _1291;\n            float tau = _1300 * _1300;\n            if (_323_fog_b.y > 0.0f)\n            {\n                float _1316;\n                if (_1278)\n                {\n                    _1316 = world_xy.y - (_323_fog_c.y * _1274);\n                }\n                else\n                {\n                    _1316 = _323_fog_eye.y;\n                }\n                float _1337 = lerp(_1316, world_xy.y, clamp(_323_fog_b.x / _1279, 0.0f, 1.0f));\n                float _1341 = world_xy.y - _1337;\n                float _1346 = _1337 - _323_fog_b.z;\n                float _1351 = world_xy.y - _323_fog_b.z;\n                bool _1354 = _1346 <= 0.0f;\n                bool _1355 = !_1354;\n                bool _1361;\n                if (_1355)\n                {\n                    _1361 = _323_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1361 = _1354;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = _323_fog_b.y;\n                }\n                else\n                {\n                    _1362 = _323_fog_b.y * exp(-min(_323_fog_b.w * _1346, 80.0f));\n                }\n                bool _1389;\n                if (_1355)\n                {\n                    _1389 = _323_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1389 = _1354;\n                }\n                float _1390;\n                if (_1389)\n                {\n                    _1390 = _323_fog_b.y * _1346;\n                }\n                else\n                {\n                    _1390 = (_323_fog_b.y * (1.0f - exp(-min(_323_fog_b.w * _1346, 80.0f)))) / _323_fog_b.w;\n                }\n                bool _1415 = _1351 <= 0.0f;\n                bool _1422;\n                if (!_1415)\n                {\n                    _1422 = _323_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1422 = _1415;\n                }\n                float _1423;\n                if (_1422)\n                {\n                    _1423 = _323_fog_b.y * _1351;\n                }\n                else\n                {\n                    _1423 = (_323_fog_b.y * (1.0f - exp(-min(_323_fog_b.w * _1351, 80.0f)))) / _323_fog_b.w;\n                }\n                float _1450;\n                if (abs(_1341) < 0.001000000047497451305389404296875f)\n                {\n                    _1450 = _1362;\n                }\n                else\n                {\n                    _1450 = (_1423 - _1390) / _1341;\n                }\n                tau += (_1291 * max(_1450, 0.0f));\n            }\n            float4 _1473 = frag_color;\n            float3 _1481 = lerp(_1473.xyz, _323_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1481.x;\n            frag_color.y = _1481.y;\n            frag_color.z = _1481.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_323",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_413",
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _107_view_proj : packoffset(c0);\n    float4 _107_cspace : packoffset(c4);\n    float4 _107_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float4 fa_inst_d0;\nstatic float4 fa_inst_d1;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    float4 fa_inst_d0 : TEXCOORD7;\n    float4 fa_inst_d1 : TEXCOORD8;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_Position : SV_Position;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    v.world_pos.x += shift;\n}\n\nvoid vert_main()\n{\n    float4 param = fa_inst_d0;\n    float4 param_1 = fa_inst_d1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n    float3 _184 = position;\n    float2 _185 = texcoord0;\n    float4 _186 = color0;\n    if (_107_cspace.x > 0.5f)\n    {\n        float3 param_3 = color0.xyz;\n        float3 _119 = fa_srgb_to_linear(param_3);\n        float4 _198 = _186;\n        _198.x = _119.x;\n        _198.y = _119.y;\n        _198.z = _119.z;\n        _186 = _198;\n    }\n    QuadVertex _193 = { _184, _185, _186 };\n    QuadVertex param_4 = _193;\n    vertex(param_4);\n    _184 = param_4.world_pos;\n    _185 = param_4.uv;\n    _186 = param_4.color;\n    gl_Position = mul(float4(param_4.world_pos, 1.0f), _107_view_proj);\n    uv = param_4.uv;\n    color = param_4.color;\n    xform = _107_cspace.xyz;\n    params = params0;\n    world_xy = param_4.world_pos.xy;\n    world_z = param_4.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    fa_inst_d0 = stage_input.fa_inst_d0;\n    fa_inst_d1 = stage_input.fa_inst_d1;\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_v0 = fa_inst_v0;\n    stage_output.fa_inst_v1 = fa_inst_v1;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _162_lit : packoffset(c0);\n    float4 _162_ambient : packoffset(c1);\n    float4 _162_normal_uv : packoffset(c2);\n    float4 _162_flat_ambient : packoffset(c3);\n    float4 _162_light_map : packoffset(c4);\n    float4 _162_light_pos[16] : packoffset(c5);\n    float4 _162_light_color[16] : packoffset(c21);\n    float4 _162_light_shadow_v[16] : packoffset(c37);\n    float4 _162_fog_col : packoffset(c53);\n    float4 _162_fog_b : packoffset(c54);\n    float4 _162_fog_c : packoffset(c55);\n    float4 _162_fog_eye : packoffset(c56);\n    float4 _162_fa_time : packoffset(c57);\n    float4 _162_fa_target : packoffset(c58);\n    float4 _162_fa_scene : packoffset(c59);\n    float4 _162_fa_world_uv[3] : packoffset(c60);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _254_boost : packoffset(c0);\n    float _254_fa_pad0 : packoffset(c0.y);\n    float _254_fa_pad1 : packoffset(c0.z);\n    float _254_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _169 = gl_FragCoord.xy * _162_fa_target.xy;\n    float _174 = _169.y;\n    return float2(_169.x, lerp(_174, 1.0f - _174, _162_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _217 = base_mode < 0.5f;\n    bool _228;\n    if (!_217)\n    {\n        _228 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _228 = _217;\n    }\n    float _229;\n    if (_228)\n    {\n        _229 = shape_half.x;\n    }\n    else\n    {\n        _229 = 0.0f;\n    }\n    QuadInput _368 = { uv, color, world_xy, fa_screen_uv(), _162_fa_time.x, base_mode, 0.0f.xxxx, _229 };\n    return _368;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _257 = fa_scene_rgb(param) * _254_boost;\n    s.color.x = _257.x;\n    s.color.y = _257.y;\n    s.color.z = _257.z;\n}\n\nvoid frag_main()\n{\n    float4 _284 = tex.Sample(smp, uv);\n    float3 param = _284.xyz;\n    float param_1 = xform.y;\n    float3 _293 = fa_tex_fix(param, param_1);\n    frag_color = float4(_293, _284.w) * color;\n    float param_2 = 0.0f;\n    float4 _348 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _350 = { _348 };\n    QuadSurface param_4 = _350;\n    fragment(param_3, param_4);\n    _348 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 7
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "hlsl_sem_name": "TEXCOORD",
            "hlsl_sem_index": 8
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 96,
            "struct_name": "vs_params",
            "inst_name": "_107",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_162",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_254",
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
