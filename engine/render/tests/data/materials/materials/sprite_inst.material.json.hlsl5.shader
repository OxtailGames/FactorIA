{
  "format": "factoria.shader/1",
  "engine": "0.31.0",
  "template": "e7ae2aae15992ecb78a26a34b353f3d952e8e65744815e598b5d319af1a2ba44",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _322_lit : packoffset(c0);\n    float4 _322_ambient : packoffset(c1);\n    float4 _322_normal_uv : packoffset(c2);\n    float4 _322_flat_ambient : packoffset(c3);\n    float4 _322_light_map : packoffset(c4);\n    float4 _322_light_pos[16] : packoffset(c5);\n    float4 _322_light_color[16] : packoffset(c21);\n    float4 _322_light_shadow_v[16] : packoffset(c37);\n    float4 _322_fog_col : packoffset(c53);\n    float4 _322_fog_b : packoffset(c54);\n    float4 _322_fog_c : packoffset(c55);\n    float4 _322_fog_eye : packoffset(c56);\n    float4 _322_fa_time : packoffset(c57);\n    float4 _322_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _412_boost : packoffset(c0);\n    float _412_fa_pad0 : packoffset(c0.y);\n    float _412_fa_pad1 : packoffset(c0.z);\n    float _412_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _256 = fa_linear_to_srgb(param);\n        c = _256;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _264 = fa_srgb_to_linear(param_1);\n            c = _264;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _275 = tex.Sample(smp, p);\n    float3 param = _275.xyz;\n    float param_1 = xform.y;\n    float3 _285 = fa_tex_fix(param, param_1);\n    return float4(_285, _275.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _98 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_98.x * 255.0f) + 0.5f) * 256.0f) + floor((_98.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _122 = length(d);\n    if (_122 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _136 = atan2(d.y, d.x);\n    float a = _136;\n    float _139;\n    if (_136 < 0.0f)\n    {\n        _139 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _139 = a;\n    }\n    a = _139;\n    float _151 = _139 * 162.9746551513671875f;\n    float _156 = min(floor(_151), 1023.0f);\n    float _163 = _156 + 1.0f;\n    float i1 = _163;\n    if (_163 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _156;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _122) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _122) + 0.5f, 0.0f, 1.0f), _151 - _156);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _436 = _322_lit.y > 0.5f;\n    if (_436)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _322_normal_uv.xy) + _322_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _460 = fa_tex_fix(param, param_1);\n        float3 _464 = (_460 * 2.0f) - 1.0f.xxx;\n        float _471 = cos(params.y);\n        float _473 = sin(params.y);\n        n = normalize(float3((float2(_471, _473) * _464.x) + ((float2(-_473, _471) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _464.y), max(_464.z, 0.0500000007450580596923828125f)));\n    }\n    bool _507 = !_436;\n    bool _513;\n    if (_507)\n    {\n        _513 = _322_lit.z > 0.5f;\n    }\n    else\n    {\n        _513 = _507;\n    }\n    float3 _516;\n    if (_513)\n    {\n        _516 = _322_flat_ambient.xyz;\n    }\n    else\n    {\n        _516 = _322_ambient.xyz;\n    }\n    float3 total = _516;\n    bool _533;\n    if (_513)\n    {\n        _533 = _322_lit.z < 1.5f;\n    }\n    else\n    {\n        _533 = _513;\n    }\n    if (_533)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _322_light_map.xy, 0.0f).xyz * _322_light_map.z);\n    }\n    float3 l;\n    float _651;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _573;\n        if (!_513)\n        {\n            _573 = float(i) >= _322_lit.x;\n        }\n        else\n        {\n            _573 = _513;\n        }\n        if (_573)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_322_light_pos[i].w < 0.0f)\n        {\n            l = _322_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _599 = _322_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_599) / max(_322_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _322_light_color[i].w);\n            float3 _619 = float3(_599, _322_light_pos[i].z);\n            l = _619 / max(length(_619), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_322_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _322_light_shadow_v[i].x;\n                float2 param_3 = -_599;\n                float param_4 = _322_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_436)\n        {\n            _651 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _651 = 1.0f;\n        }\n        total += (_322_light_color[i].xyz * (att * _651));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _302 = fa_srgb_to_linear(param);\n        c = _302;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _679 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _683 = uv * _679;\n    float _689 = _679.x;\n    float _691 = _679.y;\n    float _693 = clamp(shape_rs.x, 0.0f, min(_689, _691));\n    float2 _704 = (abs(_683) - _679) + _693.xx;\n    float d = (length(max(_704, 0.0f.xx)) + min(max(_704.x, _704.y), 0.0f)) - _693;\n    float ax = params.y;\n    bool _725 = params.y > 15.0f;\n    if (_725)\n    {\n        ax -= 20.0f;\n    }\n    float _736;\n    if (ax <= (-1.5f))\n    {\n        _736 = (-2.0f) - ax;\n    }\n    else\n    {\n        _736 = 0.0f;\n    }\n    if (_736 > 0.0f)\n    {\n        float _750 = _736 * 0.5f;\n        d = abs(d + _750) - _750;\n    }\n    float _758 = fwidth(d);\n    float _759 = max(_758, 9.9999997473787516355514526367188e-05f);\n    float _769 = clamp(0.5f - (d / max(shape_rs.y, _759)), 0.0f, 1.0f);\n    float _774;\n    if (shape_rs.y > _759)\n    {\n        _774 = (_769 * _769) * (3.0f - (2.0f * _769));\n    }\n    else\n    {\n        _774 = _769;\n    }\n    float4 c = color;\n    bool _796 = (_736 <= 0.0f) && (ax > (-0.5f));\n    if (_796)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _811 = cos(ax);\n            float _813 = sin(ax);\n            g = ((dot(_683, float2(_811, _813)) / max((abs(_811) * _689) + (abs(_813) * _691), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_725)\n        {\n            float4 _856 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _856;\n            float3 param = _856.xyz;\n            float param_1 = xform.y;\n            float3 _863 = fa_tex_fix(param, param_1);\n            float4 _1559 = c;\n            _1559.x = _863.x;\n            _1559.y = _863.y;\n            _1559.z = _863.z;\n            c = _1559;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _875 = scene_rgb(param_2);\n            float4 _900 = lerp(float4(color.xyz * color.w, color.w), float4(_875 * color2.w, color2.w), g.xxxx);\n            float _902 = _900.w;\n            float3 _905;\n            if (_902 > 9.9999997473787516355514526367188e-06f)\n            {\n                _905 = _900.xyz / _902.xxx;\n            }\n            else\n            {\n                _905 = color.xyz;\n            }\n            c = float4(_905, _902);\n        }\n    }\n    float4 _1568 = c;\n    _1568.w = _1568.w * _774;\n    c = _1568;\n    if (_796 || (shape_rs.y > 0.0f))\n    {\n        float _946 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _955 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _955 + (_946 * 0.0039215688593685626983642578125f).xxx;\n            float3 _961 = fa_srgb_to_linear(param_4);\n            float4 _1571 = c;\n            _1571.x = _961.x;\n            _1571.y = _961.y;\n            _1571.z = _961.z;\n            c = _1571;\n        }\n        else\n        {\n            float4 _971 = c;\n            float3 _974 = _971.xyz + (_946 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1578 = _971;\n            _1578.x = _974.x;\n            _1578.y = _974.y;\n            _1578.z = _974.z;\n            c = _1578;\n        }\n        float4 _1583 = c;\n        _1583.w = clamp(_1583.w + ((_946 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1583.w)), 0.0f, 1.0f);\n        c = _1583;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _329 = gl_FragCoord.xy * _322_fa_target.xy;\n    float _333 = _329.y;\n    return float2(_329.x, lerp(_333, 1.0f - _333, _322_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _375 = base_mode < 0.5f;\n    bool _386;\n    if (!_375)\n    {\n        _386 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _386 = _375;\n    }\n    float _387;\n    if (_386)\n    {\n        _387 = shape_half.x;\n    }\n    else\n    {\n        _387 = 0.0f;\n    }\n    QuadInput _1532 = { uv, color, world_xy, fa_screen_uv(), _322_fa_time.x, base_mode, 0.0f.xxxx, _387 };\n    return _1532;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _308 = scene_rgb(param);\n    return _308;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _415 = fa_scene_rgb(param) * _412_boost;\n    s.color.x = _415.x;\n    s.color.y = _415.y;\n    s.color.z = _415.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1001 = params.x > 31.5f;\n    if (_1001)\n    {\n        mode -= 32.0f;\n    }\n    float _1009 = mode;\n    bool _1011 = _1009 > 15.5f;\n    if (_1011)\n    {\n        mode -= 16.0f;\n    }\n    float _1019 = mode;\n    bool _1021 = _1019 > 7.5f;\n    if (_1021)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1011)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1011)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1085 = tex_color(param_5) * color;\n                float4 param_6 = _1085;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1085.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1120 = length(uv);\n                    float _1123 = fwidth(_1120);\n                    float _1124 = max(_1123, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1120) / _1124) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1120) / _1124) + 0.5f, 0.0f, 1.0f) * clamp(((_1120 - params.y) / _1124) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1164 = clamp(1.0f - _1120, 0.0f, 1.0f);\n                            cov = (_1164 * _1164) * (3.0f - (2.0f * _1164));\n                        }\n                    }\n                    float3 _1173;\n                    if (_1011)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1173 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1173 = color.xyz;\n                    }\n                    frag_color = float4(_1173, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1512 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1514 = { _1512 };\n    QuadSurface param_12 = _1514;\n    fragment(param_11, param_12);\n    _1512 = param_12.color;\n    frag_color = param_12.color;\n    if (_1001)\n    {\n        float4 _1211 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1216 = scene_rgb(param_13);\n        float3 _1220 = lerp(_1211.xyz, _1216, color2.w.xxx);\n        frag_color.x = _1220.x;\n        frag_color.y = _1220.y;\n        frag_color.z = _1220.z;\n    }\n    if (_1021)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1244 = _322_fog_col.w > 0.0f;\n    bool _1252;\n    if (!_1244)\n    {\n        _1252 = _322_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1252 = _1244;\n    }\n    if (_1252)\n    {\n        float3 _1266 = float3(world_xy, world_z) - _322_fog_eye.xyz;\n        float _1273 = dot(_1266, _322_fog_c.xyz);\n        bool _1277 = _322_fog_c.w > 0.5f;\n        float _1278;\n        if (_1277)\n        {\n            _1278 = _1273;\n        }\n        else\n        {\n            _1278 = length(_1266);\n        }\n        float _1290 = _1278 - _322_fog_b.x;\n        if (_1290 > 0.0f)\n        {\n            float _1299 = _322_fog_col.w * _1290;\n            float tau = _1299 * _1299;\n            if (_322_fog_b.y > 0.0f)\n            {\n                float _1315;\n                if (_1277)\n                {\n                    _1315 = world_xy.y - (_322_fog_c.y * _1273);\n                }\n                else\n                {\n                    _1315 = _322_fog_eye.y;\n                }\n                float _1336 = lerp(_1315, world_xy.y, clamp(_322_fog_b.x / _1278, 0.0f, 1.0f));\n                float _1340 = world_xy.y - _1336;\n                float _1345 = _1336 - _322_fog_b.z;\n                float _1350 = world_xy.y - _322_fog_b.z;\n                bool _1353 = _1345 <= 0.0f;\n                bool _1354 = !_1353;\n                bool _1360;\n                if (_1354)\n                {\n                    _1360 = _322_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1360 = _1353;\n                }\n                float _1361;\n                if (_1360)\n                {\n                    _1361 = _322_fog_b.y;\n                }\n                else\n                {\n                    _1361 = _322_fog_b.y * exp(-min(_322_fog_b.w * _1345, 80.0f));\n                }\n                bool _1388;\n                if (_1354)\n                {\n                    _1388 = _322_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1388 = _1353;\n                }\n                float _1389;\n                if (_1388)\n                {\n                    _1389 = _322_fog_b.y * _1345;\n                }\n                else\n                {\n                    _1389 = (_322_fog_b.y * (1.0f - exp(-min(_322_fog_b.w * _1345, 80.0f)))) / _322_fog_b.w;\n                }\n                bool _1414 = _1350 <= 0.0f;\n                bool _1421;\n                if (!_1414)\n                {\n                    _1421 = _322_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1421 = _1414;\n                }\n                float _1422;\n                if (_1421)\n                {\n                    _1422 = _322_fog_b.y * _1350;\n                }\n                else\n                {\n                    _1422 = (_322_fog_b.y * (1.0f - exp(-min(_322_fog_b.w * _1350, 80.0f)))) / _322_fog_b.w;\n                }\n                float _1449;\n                if (abs(_1340) < 0.001000000047497451305389404296875f)\n                {\n                    _1449 = _1361;\n                }\n                else\n                {\n                    _1449 = (_1422 - _1389) / _1340;\n                }\n                tau += (_1290 * max(_1449, 0.0f));\n            }\n            float4 _1472 = frag_color;\n            float3 _1480 = lerp(_1472.xyz, _322_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1480.x;\n            frag_color.y = _1480.y;\n            frag_color.z = _1480.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_322",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_412",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _160_lit : packoffset(c0);\n    float4 _160_ambient : packoffset(c1);\n    float4 _160_normal_uv : packoffset(c2);\n    float4 _160_flat_ambient : packoffset(c3);\n    float4 _160_light_map : packoffset(c4);\n    float4 _160_light_pos[16] : packoffset(c5);\n    float4 _160_light_color[16] : packoffset(c21);\n    float4 _160_light_shadow_v[16] : packoffset(c37);\n    float4 _160_fog_col : packoffset(c53);\n    float4 _160_fog_b : packoffset(c54);\n    float4 _160_fog_c : packoffset(c55);\n    float4 _160_fog_eye : packoffset(c56);\n    float4 _160_fa_time : packoffset(c57);\n    float4 _160_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float _252_boost : packoffset(c0);\n    float _252_fa_pad0 : packoffset(c0.y);\n    float _252_fa_pad1 : packoffset(c0.z);\n    float _252_fa_pad2 : packoffset(c0.w);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 fa_inst_v0;\nstatic float4 fa_inst_v1;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation float4 fa_inst_v0 : TEXCOORD9;\n    nointerpolation float4 fa_inst_v1 : TEXCOORD10;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nstatic float shift;\nstatic float4 tint;\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _114 = fa_linear_to_srgb(param);\n        c = _114;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _123 = fa_srgb_to_linear(param_1);\n            c = _123;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _167 = gl_FragCoord.xy * _160_fa_target.xy;\n    float _172 = _167.y;\n    return float2(_167.x, lerp(_172, 1.0f - _172, _160_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _215 = base_mode < 0.5f;\n    bool _226;\n    if (!_215)\n    {\n        _226 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _226 = _215;\n    }\n    float _227;\n    if (_226)\n    {\n        _227 = shape_half.x;\n    }\n    else\n    {\n        _227 = 0.0f;\n    }\n    QuadInput _365 = { uv, color, world_xy, fa_screen_uv(), _160_fa_time.x, base_mode, 0.0f.xxxx, _227 };\n    return _365;\n}\n\nvoid fa_instance_unpack(float4 fa_d0, float4 fa_d1, float4 fa_d2)\n{\n    shift = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    float4 param = fa_inst_v0;\n    float4 param_1 = fa_inst_v1;\n    float4 param_2 = 0.0f.xxxx;\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _139 = fa_srgb_to_linear(param);\n        c = _139;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _145 = scene_rgb(param);\n    return _145;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = tint.xyz;\n    float3 _255 = fa_scene_rgb(param) * _252_boost;\n    s.color.x = _255.x;\n    s.color.y = _255.y;\n    s.color.z = _255.z;\n}\n\nvoid frag_main()\n{\n    float4 _282 = tex.Sample(smp, uv);\n    float3 param = _282.xyz;\n    float param_1 = xform.y;\n    float3 _291 = fa_tex_fix(param, param_1);\n    frag_color = float4(_291, _282.w) * color;\n    float param_2 = 0.0f;\n    float4 _345 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _347 = { _345 };\n    QuadSurface param_4 = _347;\n    fragment(param_3, param_4);\n    _345 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_v0 = stage_input.fa_inst_v0;\n    fa_inst_v1 = stage_input.fa_inst_v1;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "size": 944,
            "struct_name": "quad_fs_params",
            "inst_name": "_160",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_252",
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
