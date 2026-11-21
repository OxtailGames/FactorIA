{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "92b6737b88986088c23ec149effb731593899af4f139a1a2f6aa207cd28c4169",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "points",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "quad": {
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _105_view_proj : packoffset(c0);\n    float4 _105_cspace : packoffset(c4);\n    float4 _105_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic int fa_inst_index_v;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    float3 _68 = v.world_pos;\n    float2 _76 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xy + (_68.xy * asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid vert_main()\n{\n    fa_inst_index_v = gl_InstanceIndex;\n    float3 _178 = position;\n    float2 _179 = texcoord0;\n    float4 _180 = color0;\n    if (_105_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _117 = fa_srgb_to_linear(param);\n        float4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex _187 = { _178, _179, _180 };\n    QuadVertex param_1 = _187;\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _105_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _105_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_index_v = fa_inst_index_v;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _309_lit : packoffset(c0);\n    float4 _309_ambient : packoffset(c1);\n    float4 _309_normal_uv : packoffset(c2);\n    float4 _309_flat_ambient : packoffset(c3);\n    float4 _309_light_map : packoffset(c4);\n    float4 _309_light_pos[16] : packoffset(c5);\n    float4 _309_light_color[16] : packoffset(c21);\n    float4 _309_light_shadow_v[16] : packoffset(c37);\n    float4 _309_fog_col : packoffset(c53);\n    float4 _309_fog_b : packoffset(c54);\n    float4 _309_fog_c : packoffset(c55);\n    float4 _309_fog_eye : packoffset(c56);\n    float4 _309_fa_time : packoffset(c57);\n    float4 _309_fa_target : packoffset(c58);\n    float4 _309_fa_scene : packoffset(c59);\n    float4 _309_fa_world_uv[3] : packoffset(c60);\n};\n\nByteAddressBuffer points : register(t4);\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic int fa_inst_index_v;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _247 = fa_linear_to_srgb(param);\n        c = _247;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _255 = fa_srgb_to_linear(param_1);\n            c = _255;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _266 = tex.Sample(smp, p);\n    float3 param = _266.xyz;\n    float param_1 = xform.y;\n    float3 _276 = fa_tex_fix(param, param_1);\n    return float4(_276, _266.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _89 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_89.x * 255.0f) + 0.5f) * 256.0f) + floor((_89.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _113 = length(d);\n    if (_113 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _127 = atan2(d.y, d.x);\n    float a = _127;\n    float _130;\n    if (_127 < 0.0f)\n    {\n        _130 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _130 = a;\n    }\n    a = _130;\n    float _142 = _130 * 162.9746551513671875f;\n    float _147 = min(floor(_142), 1023.0f);\n    float _154 = _147 + 1.0f;\n    float i1 = _154;\n    if (_154 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _147;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _113) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _113) + 0.5f, 0.0f, 1.0f), _142 - _147);\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _409 = _309_lit.y > 0.5f;\n    if (_409)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _309_normal_uv.xy) + _309_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _433 = fa_tex_fix(param, param_1);\n        float3 _437 = (_433 * 2.0f) - 1.0f.xxx;\n        float _444 = cos(params.y);\n        float _446 = sin(params.y);\n        n = normalize(float3((float2(_444, _446) * _437.x) + ((float2(-_446, _444) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _437.y), max(_437.z, 0.0500000007450580596923828125f)));\n    }\n    bool _480 = !_409;\n    bool _486;\n    if (_480)\n    {\n        _486 = _309_lit.z > 0.5f;\n    }\n    else\n    {\n        _486 = _480;\n    }\n    float3 _489;\n    if (_486)\n    {\n        _489 = _309_flat_ambient.xyz;\n    }\n    else\n    {\n        _489 = _309_ambient.xyz;\n    }\n    float3 total = _489;\n    bool _506;\n    if (_486)\n    {\n        _506 = _309_lit.z < 1.5f;\n    }\n    else\n    {\n        _506 = _486;\n    }\n    if (_506)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _309_light_map.xy, 0.0f).xyz * _309_light_map.z);\n    }\n    float3 l;\n    float _624;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _546;\n        if (!_486)\n        {\n            _546 = float(i) >= _309_lit.x;\n        }\n        else\n        {\n            _546 = _486;\n        }\n        if (_546)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_309_light_pos[i].w < 0.0f)\n        {\n            l = _309_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _572 = _309_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_572) / max(_309_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _309_light_color[i].w);\n            float3 _592 = float3(_572, _309_light_pos[i].z);\n            l = _592 / max(length(_592), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_309_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _309_light_shadow_v[i].x;\n                float2 param_3 = -_572;\n                float param_4 = _309_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n        }\n        if (_409)\n        {\n            _624 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _624 = 1.0f;\n        }\n        total += (_309_light_color[i].xyz * (att * _624));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _293 = fa_srgb_to_linear(param);\n        c = _293;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _652 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _656 = uv * _652;\n    float _662 = _652.x;\n    float _664 = _652.y;\n    float _666 = clamp(shape_rs.x, 0.0f, min(_662, _664));\n    float2 _677 = (abs(_656) - _652) + _666.xx;\n    float d = (length(max(_677, 0.0f.xx)) + min(max(_677.x, _677.y), 0.0f)) - _666;\n    float ax = params.y;\n    bool _698 = params.y > 15.0f;\n    if (_698)\n    {\n        ax -= 20.0f;\n    }\n    float _709;\n    if (ax <= (-1.5f))\n    {\n        _709 = (-2.0f) - ax;\n    }\n    else\n    {\n        _709 = 0.0f;\n    }\n    if (_709 > 0.0f)\n    {\n        float _723 = _709 * 0.5f;\n        d = abs(d + _723) - _723;\n    }\n    float _731 = fwidth(d);\n    float _732 = max(_731, 9.9999997473787516355514526367188e-05f);\n    float _742 = clamp(0.5f - (d / max(shape_rs.y, _732)), 0.0f, 1.0f);\n    float _747;\n    if (shape_rs.y > _732)\n    {\n        _747 = (_742 * _742) * (3.0f - (2.0f * _742));\n    }\n    else\n    {\n        _747 = _742;\n    }\n    float4 c = color;\n    bool _769 = (_709 <= 0.0f) && (ax > (-0.5f));\n    if (_769)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _784 = cos(ax);\n            float _786 = sin(ax);\n            g = ((dot(_656, float2(_784, _786)) / max((abs(_784) * _662) + (abs(_786) * _664), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_698)\n        {\n            float4 _829 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _829;\n            float3 param = _829.xyz;\n            float param_1 = xform.y;\n            float3 _836 = fa_tex_fix(param, param_1);\n            float4 _1533 = c;\n            _1533.x = _836.x;\n            _1533.y = _836.y;\n            _1533.z = _836.z;\n            c = _1533;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _848 = scene_rgb(param_2);\n            float4 _873 = lerp(float4(color.xyz * color.w, color.w), float4(_848 * color2.w, color2.w), g.xxxx);\n            float _875 = _873.w;\n            float3 _878;\n            if (_875 > 9.9999997473787516355514526367188e-06f)\n            {\n                _878 = _873.xyz / _875.xxx;\n            }\n            else\n            {\n                _878 = color.xyz;\n            }\n            c = float4(_878, _875);\n        }\n    }\n    float4 _1542 = c;\n    _1542.w = _1542.w * _747;\n    c = _1542;\n    if (_769 || (shape_rs.y > 0.0f))\n    {\n        float _919 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _928 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _928 + (_919 * 0.0039215688593685626983642578125f).xxx;\n            float3 _934 = fa_srgb_to_linear(param_4);\n            float4 _1545 = c;\n            _1545.x = _934.x;\n            _1545.y = _934.y;\n            _1545.z = _934.z;\n            c = _1545;\n        }\n        else\n        {\n            float4 _944 = c;\n            float3 _947 = _944.xyz + (_919 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1552 = _944;\n            _1552.x = _947.x;\n            _1552.y = _947.y;\n            _1552.z = _947.z;\n            c = _1552;\n        }\n        float4 _1557 = c;\n        _1557.w = clamp(_1557.w + ((_919 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1557.w)), 0.0f, 1.0f);\n        c = _1557;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _316 = gl_FragCoord.xy * _309_fa_target.xy;\n    float _320 = _316.y;\n    return float2(_316.x, lerp(_320, 1.0f - _320, _309_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _362 = base_mode < 0.5f;\n    bool _373;\n    if (!_362)\n    {\n        _373 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _373 = _362;\n    }\n    float _374;\n    if (_373)\n    {\n        _374 = shape_half.x;\n    }\n    else\n    {\n        _374 = 0.0f;\n    }\n    QuadInput _1506 = { uv, color, world_xy, fa_screen_uv(), _309_fa_time.x, base_mode, 0.0f.xxxx, _374 };\n    return _1506;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).x;\n    s.color.y = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).y;\n    s.color.z = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _974 = params.x > 31.5f;\n    if (_974)\n    {\n        mode -= 32.0f;\n    }\n    float _982 = mode;\n    bool _984 = _982 > 15.5f;\n    if (_984)\n    {\n        mode -= 16.0f;\n    }\n    float _992 = mode;\n    bool _994 = _992 > 7.5f;\n    if (_994)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_984)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_984)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1058 = tex_color(param_5) * color;\n                float4 param_6 = _1058;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1058.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1093 = length(uv);\n                    float _1096 = fwidth(_1093);\n                    float _1097 = max(_1096, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1093) / _1097) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1093) / _1097) + 0.5f, 0.0f, 1.0f) * clamp(((_1093 - params.y) / _1097) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1137 = clamp(1.0f - _1093, 0.0f, 1.0f);\n                            cov = (_1137 * _1137) * (3.0f - (2.0f * _1137));\n                        }\n                    }\n                    float3 _1146;\n                    if (_984)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1146 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1146 = color.xyz;\n                    }\n                    frag_color = float4(_1146, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1486 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1488 = { _1486 };\n    QuadSurface param_12 = _1488;\n    fragment(param_11, param_12);\n    _1486 = param_12.color;\n    frag_color = param_12.color;\n    if (_974)\n    {\n        float4 _1184 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1189 = scene_rgb(param_13);\n        float3 _1193 = lerp(_1184.xyz, _1189, color2.w.xxx);\n        frag_color.x = _1193.x;\n        frag_color.y = _1193.y;\n        frag_color.z = _1193.z;\n    }\n    if (_994)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1217 = _309_fog_col.w > 0.0f;\n    bool _1225;\n    if (!_1217)\n    {\n        _1225 = _309_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1225 = _1217;\n    }\n    if (_1225)\n    {\n        float3 _1239 = float3(world_xy, world_z) - _309_fog_eye.xyz;\n        float _1246 = dot(_1239, _309_fog_c.xyz);\n        bool _1250 = _309_fog_c.w > 0.5f;\n        float _1251;\n        if (_1250)\n        {\n            _1251 = _1246;\n        }\n        else\n        {\n            _1251 = length(_1239);\n        }\n        float _1263 = _1251 - _309_fog_b.x;\n        if (_1263 > 0.0f)\n        {\n            float _1272 = _309_fog_col.w * _1263;\n            float tau = _1272 * _1272;\n            if (_309_fog_b.y > 0.0f)\n            {\n                float _1288;\n                if (_1250)\n                {\n                    _1288 = world_xy.y - (_309_fog_c.y * _1246);\n                }\n                else\n                {\n                    _1288 = _309_fog_eye.y;\n                }\n                float _1309 = lerp(_1288, world_xy.y, clamp(_309_fog_b.x / _1251, 0.0f, 1.0f));\n                float _1313 = world_xy.y - _1309;\n                float _1318 = _1309 - _309_fog_b.z;\n                float _1323 = world_xy.y - _309_fog_b.z;\n                bool _1326 = _1318 <= 0.0f;\n                bool _1327 = !_1326;\n                bool _1333;\n                if (_1327)\n                {\n                    _1333 = _309_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1333 = _1326;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = _309_fog_b.y;\n                }\n                else\n                {\n                    _1334 = _309_fog_b.y * exp(-min(_309_fog_b.w * _1318, 80.0f));\n                }\n                bool _1361;\n                if (_1327)\n                {\n                    _1361 = _309_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1361 = _1326;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = _309_fog_b.y * _1318;\n                }\n                else\n                {\n                    _1362 = (_309_fog_b.y * (1.0f - exp(-min(_309_fog_b.w * _1318, 80.0f)))) / _309_fog_b.w;\n                }\n                bool _1387 = _1323 <= 0.0f;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _309_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                float _1395;\n                if (_1394)\n                {\n                    _1395 = _309_fog_b.y * _1323;\n                }\n                else\n                {\n                    _1395 = (_309_fog_b.y * (1.0f - exp(-min(_309_fog_b.w * _1323, 80.0f)))) / _309_fog_b.w;\n                }\n                float _1422;\n                if (abs(_1313) < 0.001000000047497451305389404296875f)\n                {\n                    _1422 = _1334;\n                }\n                else\n                {\n                    _1422 = (_1395 - _1362) / _1313;\n                }\n                tau += (_1263 * max(_1422, 0.0f));\n            }\n            float4 _1445 = frag_color;\n            float3 _1453 = lerp(_1445.xyz, _309_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1453.x;\n            frag_color.y = _1453.y;\n            frag_color.z = _1453.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_index_v = stage_input.fa_inst_index_v;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_105",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
            "struct_name": "quad_fs_params",
            "inst_name": "_309",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _105_view_proj : packoffset(c0);\n    float4 _105_cspace : packoffset(c4);\n    float4 _105_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic int fa_inst_index_v;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    float3 _68 = v.world_pos;\n    float2 _76 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xy + (_68.xy * asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid vert_main()\n{\n    fa_inst_index_v = gl_InstanceIndex;\n    float3 _178 = position;\n    float2 _179 = texcoord0;\n    float4 _180 = color0;\n    if (_105_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _117 = fa_srgb_to_linear(param);\n        float4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex _187 = { _178, _179, _180 };\n    QuadVertex param_1 = _187;\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _105_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _105_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_index_v = fa_inst_index_v;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _129_lit : packoffset(c0);\n    float4 _129_ambient : packoffset(c1);\n    float4 _129_normal_uv : packoffset(c2);\n    float4 _129_flat_ambient : packoffset(c3);\n    float4 _129_light_map : packoffset(c4);\n    float4 _129_light_pos[16] : packoffset(c5);\n    float4 _129_light_color[16] : packoffset(c21);\n    float4 _129_light_shadow_v[16] : packoffset(c37);\n    float4 _129_fog_col : packoffset(c53);\n    float4 _129_fog_b : packoffset(c54);\n    float4 _129_fog_c : packoffset(c55);\n    float4 _129_fog_eye : packoffset(c56);\n    float4 _129_fa_time : packoffset(c57);\n    float4 _129_fa_target : packoffset(c58);\n    float4 _129_fa_scene : packoffset(c59);\n    float4 _129_fa_world_uv[3] : packoffset(c60);\n};\n\nByteAddressBuffer points : register(t1);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic int fa_inst_index_v;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _136 = gl_FragCoord.xy * _129_fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, lerp(_142, 1.0f - _142, _129_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5f;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0f;\n    }\n    QuadInput _326 = { uv, color, world_xy, fa_screen_uv(), _129_fa_time.x, base_mode, 0.0f.xxxx, _198 };\n    return _326;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).x;\n    s.color.y = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).y;\n    s.color.z = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).z;\n}\n\nvoid frag_main()\n{\n    float4 _240 = tex.Sample(smp, uv);\n    float3 param = _240.xyz;\n    float param_1 = xform.y;\n    float3 _251 = fa_tex_fix(param, param_1);\n    frag_color = float4(_251, _240.w) * color;\n    float param_2 = 0.0f;\n    float4 _306 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _308 = { _306 };\n    QuadSurface param_4 = _308;\n    fragment(param_3, param_4);\n    _306 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_index_v = stage_input.fa_inst_index_v;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_105",
            "hlsl_register_b_n": 0
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 1008,
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
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
