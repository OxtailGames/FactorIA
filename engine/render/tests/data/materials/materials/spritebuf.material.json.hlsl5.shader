{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "dbae68a2cd91807fd7df084cee13eb559f2382809eb1ac9d2df2d325d7943acc",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _429_lit : packoffset(c0);\n    float4 _429_ambient : packoffset(c1);\n    float4 _429_normal_uv : packoffset(c2);\n    float4 _429_flat_ambient : packoffset(c3);\n    float4 _429_light_map : packoffset(c4);\n    float4 _429_light_pos[16] : packoffset(c5);\n    float4 _429_light_color[16] : packoffset(c21);\n    float4 _429_light_shadow_v[16] : packoffset(c37);\n    float4 _429_fog_col : packoffset(c53);\n    float4 _429_fog_b : packoffset(c54);\n    float4 _429_fog_c : packoffset(c55);\n    float4 _429_fog_eye : packoffset(c56);\n    float4 _429_fa_time : packoffset(c57);\n    float4 _429_fa_target : packoffset(c58);\n    float4 _429_fx_emit : packoffset(c59);\n    float4 _429_fx_emit_uv : packoffset(c60);\n    float4 _429_fx_rim : packoffset(c61);\n    float4 _429_fx_rim_uv : packoffset(c62);\n    float4 _429_light_cookie[16] : packoffset(c63);\n    float4 _429_light_cookie_xf[16] : packoffset(c79);\n};\n\nByteAddressBuffer points : register(t6);\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> fx_cookie_tex : register(t5);\nSamplerState light_smp : register(s1);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nTexture2D<float4> fx_emissive_tex : register(t4);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic int fa_inst_index_v;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _367 = fa_linear_to_srgb(param);\n        c = _367;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _375 = fa_srgb_to_linear(param_1);\n            c = _375;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _386 = tex.Sample(smp, p);\n    float3 param = _386.xyz;\n    float param_1 = xform.y;\n    float3 _396 = fa_tex_fix(param, param_1);\n    return float4(_396, _386.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _111 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_111.x * 255.0f) + 0.5f) * 256.0f) + floor((_111.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _135 = length(d);\n    if (_135 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _149 = atan2(d.y, d.x);\n    float a = _149;\n    float _152;\n    if (_149 < 0.0f)\n    {\n        _152 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _152 = a;\n    }\n    a = _152;\n    float _164 = _152 * 162.9746551513671875f;\n    float _169 = min(floor(_164), 1023.0f);\n    float _176 = _169 + 1.0f;\n    float i1 = _176;\n    if (_176 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _169;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _135) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _135) + 0.5f, 0.0f, 1.0f), _164 - _169);\n}\n\nfloat3 cookie_coord(float4 cell, float4 xf, float2 off)\n{\n    float2 _239 = float2((xf.x * off.x) + (xf.y * off.y), (xf.x * off.y) - (xf.y * off.x)) * xf.z;\n    float _243 = _239.x + 0.5f;\n    float2 c = float2(_243, 0.5f - _239.y);\n    bool _251 = _243 >= 0.0f;\n    bool _257;\n    if (_251)\n    {\n        _257 = c.x <= 1.0f;\n    }\n    else\n    {\n        _257 = _251;\n    }\n    bool _263;\n    if (_257)\n    {\n        _263 = c.y >= 0.0f;\n    }\n    else\n    {\n        _263 = _257;\n    }\n    bool _269;\n    if (_263)\n    {\n        _269 = c.y <= 1.0f;\n    }\n    else\n    {\n        _269 = _263;\n    }\n    float2 _271 = c;\n    float2 _276 = clamp(_271, 0.001953125f.xx, 0.998046875f.xx);\n    c = _276;\n    return float3(cell.x + (_276.x * cell.w), cell.y + (_276.y * cell.z), float(_269));\n}\n\nfloat cookie_value(float4 t)\n{\n    return dot(t.xyz, float3(0.2125999927520751953125f, 0.715200006961822509765625f, 0.072200000286102294921875f)) * t.w;\n}\n\nfloat cookie_att(int i, float2 d)\n{\n    if (_429_light_cookie[i].w == 0.0f)\n    {\n        return 1.0f;\n    }\n    float4 param = _429_light_cookie[i];\n    float4 param_1 = _429_light_cookie_xf[i];\n    float2 param_2 = d;\n    float3 _542 = cookie_coord(param, param_1, param_2);\n    float4 param_3 = fx_cookie_tex.SampleLevel(light_smp, _542.xy, 0.0f);\n    return cookie_value(param_3) * _542.z;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _564 = _429_lit.y > 0.5f;\n    if (_564)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _429_normal_uv.xy) + _429_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _588 = fa_tex_fix(param, param_1);\n        float3 _592 = (_588 * 2.0f) - 1.0f.xxx;\n        float _599 = cos(params.y);\n        float _601 = sin(params.y);\n        n = normalize(float3((float2(_599, _601) * _592.x) + ((float2(-_601, _599) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _592.y), max(_592.z, 0.0500000007450580596923828125f)));\n    }\n    bool _635 = !_564;\n    bool _641;\n    if (_635)\n    {\n        _641 = _429_lit.z > 0.5f;\n    }\n    else\n    {\n        _641 = _635;\n    }\n    float3 _644;\n    if (_641)\n    {\n        _644 = _429_flat_ambient.xyz;\n    }\n    else\n    {\n        _644 = _429_ambient.xyz;\n    }\n    float3 total = _644;\n    bool _661;\n    if (_641)\n    {\n        _661 = _429_lit.z < 1.5f;\n    }\n    else\n    {\n        _661 = _641;\n    }\n    if (_661)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _429_light_map.xy, 0.0f).xyz * _429_light_map.z);\n    }\n    float3 l;\n    float _785;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _699;\n        if (!_641)\n        {\n            _699 = float(i) >= _429_lit.x;\n        }\n        else\n        {\n            _699 = _641;\n        }\n        if (_699)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_429_light_pos[i].w < 0.0f)\n        {\n            l = _429_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _725 = _429_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_725) / max(_429_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _429_light_color[i].w);\n            float3 _745 = float3(_725, _429_light_pos[i].z);\n            l = _745 / max(length(_745), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_429_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _429_light_shadow_v[i].x;\n                float2 param_3 = -_725;\n                float param_4 = _429_light_pos[i].w;\n                att *= light_shadow(param_2, param_3, param_4);\n            }\n            int param_5 = i;\n            float2 param_6 = -_725;\n            att *= cookie_att(param_5, param_6);\n        }\n        if (_564)\n        {\n            _785 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _785 = 1.0f;\n        }\n        total += (_429_light_color[i].xyz * (att * _785));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _412 = fa_srgb_to_linear(param);\n        c = _412;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _1031 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _1035 = uv * _1031;\n    float _1041 = _1031.x;\n    float _1043 = _1031.y;\n    float _1045 = clamp(shape_rs.x, 0.0f, min(_1041, _1043));\n    float2 _1056 = (abs(_1035) - _1031) + _1045.xx;\n    float d = (length(max(_1056, 0.0f.xx)) + min(max(_1056.x, _1056.y), 0.0f)) - _1045;\n    float ax = params.y;\n    bool _1077 = params.y > 15.0f;\n    if (_1077)\n    {\n        ax -= 20.0f;\n    }\n    float _1088;\n    if (ax <= (-1.5f))\n    {\n        _1088 = (-2.0f) - ax;\n    }\n    else\n    {\n        _1088 = 0.0f;\n    }\n    if (_1088 > 0.0f)\n    {\n        float _1102 = _1088 * 0.5f;\n        d = abs(d + _1102) - _1102;\n    }\n    float _1110 = fwidth(d);\n    float _1111 = max(_1110, 9.9999997473787516355514526367188e-05f);\n    float _1121 = clamp(0.5f - (d / max(shape_rs.y, _1111)), 0.0f, 1.0f);\n    float _1126;\n    if (shape_rs.y > _1111)\n    {\n        _1126 = (_1121 * _1121) * (3.0f - (2.0f * _1121));\n    }\n    else\n    {\n        _1126 = _1121;\n    }\n    float4 c = color;\n    bool _1148 = (_1088 <= 0.0f) && (ax > (-0.5f));\n    if (_1148)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1163 = cos(ax);\n            float _1165 = sin(ax);\n            g = ((dot(_1035, float2(_1163, _1165)) / max((abs(_1163) * _1041) + (abs(_1165) * _1043), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_1077)\n        {\n            float4 _1208 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1208;\n            float3 param = _1208.xyz;\n            float param_1 = xform.y;\n            float3 _1215 = fa_tex_fix(param, param_1);\n            float4 _2003 = c;\n            _2003.x = _1215.x;\n            _2003.y = _1215.y;\n            _2003.z = _1215.z;\n            c = _2003;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1227 = scene_rgb(param_2);\n            float4 _1252 = lerp(float4(color.xyz * color.w, color.w), float4(_1227 * color2.w, color2.w), g.xxxx);\n            float _1254 = _1252.w;\n            float3 _1257;\n            if (_1254 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1257 = _1252.xyz / _1254.xxx;\n            }\n            else\n            {\n                _1257 = color.xyz;\n            }\n            c = float4(_1257, _1254);\n        }\n    }\n    float4 _2012 = c;\n    _2012.w = _2012.w * _1126;\n    c = _2012;\n    if (_1148 || (shape_rs.y > 0.0f))\n    {\n        float _1298 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1307 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1307 + (_1298 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1313 = fa_srgb_to_linear(param_4);\n            float4 _2015 = c;\n            _2015.x = _1313.x;\n            _2015.y = _1313.y;\n            _2015.z = _1313.z;\n            c = _2015;\n        }\n        else\n        {\n            float4 _1323 = c;\n            float3 _1326 = _1323.xyz + (_1298 * 0.0039215688593685626983642578125f).xxx;\n            float4 _2022 = _1323;\n            _2022.x = _1326.x;\n            _2022.y = _1326.y;\n            _2022.z = _1326.z;\n            c = _2022;\n        }\n        float4 _2027 = c;\n        _2027.w = clamp(_2027.w + ((_1298 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _2027.w)), 0.0f, 1.0f);\n        c = _2027;\n    }\n    return c;\n}\n\nfloat3 rim_color(float a0, float mode)\n{\n    float2 _822 = float2(_429_fx_rim_uv.x, 0.0f);\n    float4 _824 = tex.Sample(smp, uv - _822);\n    float _825 = _824.w;\n    float4 _835 = tex.Sample(smp, uv + _822);\n    float _836 = _835.w;\n    float2 _844 = float2(0.0f, _429_fx_rim_uv.y);\n    float4 _846 = tex.Sample(smp, uv - _844);\n    float _847 = _846.w;\n    float4 _857 = tex.Sample(smp, uv + _844);\n    float _858 = _857.w;\n    float _873 = _825 - _836;\n    float _876 = _858 - _847;\n    float _886 = cos(params.y);\n    float _888 = sin(params.y);\n    float2 _914 = ((float2(_886, _888) * _873) + ((float2(-_888, _886) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _876)) / max(length(float2(_873, _876)), 9.9999997473787516355514526367188e-05f).xx;\n    float3 sum = 0.0f.xxx;\n    float2 to_l;\n    for (int i = 0; i < 16; i++)\n    {\n        if (float(i) >= _429_lit.x)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_429_light_pos[i].w < 0.0f)\n        {\n            to_l = _429_light_pos[i].xy / max(length(_429_light_pos[i].xy), 9.9999997473787516355514526367188e-05f).xx;\n        }\n        else\n        {\n            float2 _960 = _429_light_pos[i].xy - world_xy;\n            float _963 = length(_960);\n            att = pow(clamp(1.0f - (_963 / max(_429_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _429_light_color[i].w);\n            to_l = _960 / max(_963, 9.9999997473787516355514526367188e-05f).xx;\n            if (_429_light_shadow_v[i].x >= 0.0f)\n            {\n                float param = _429_light_shadow_v[i].x;\n                float2 param_1 = -_960;\n                float param_2 = _429_light_pos[i].w;\n                att *= light_shadow(param, param_1, param_2);\n            }\n            int param_3 = i;\n            float2 param_4 = -_960;\n            att *= cookie_att(param_3, param_4);\n        }\n        sum += (_429_light_color[i].xyz * (att * max(dot(_914, to_l), 0.0f)));\n    }\n    return (sum * _429_fx_rim.xyz) * (a0 * (1.0f - min(min(_825, _836), min(_847, _858))));\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _435 = gl_FragCoord.xy * _429_fa_target.xy;\n    float _439 = _435.y;\n    return float2(_435.x, lerp(_439, 1.0f - _439, _429_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _480 = base_mode < 0.5f;\n    bool _491;\n    if (!_480)\n    {\n        _491 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _491 = _480;\n    }\n    float _492;\n    if (_491)\n    {\n        _492 = shape_half.x;\n    }\n    else\n    {\n        _492 = 0.0f;\n    }\n    QuadInput _1953 = { uv, color, world_xy, fa_screen_uv(), _429_fa_time.x, base_mode, 0.0f.xxxx, _492 };\n    return _1953;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).x;\n    s.color.y = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).y;\n    s.color.z = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1353 = params.x > 31.5f;\n    if (_1353)\n    {\n        mode -= 32.0f;\n    }\n    float _1361 = mode;\n    bool _1363 = _1361 > 15.5f;\n    if (_1363)\n    {\n        mode -= 16.0f;\n    }\n    float _1371 = mode;\n    bool _1373 = _1371 > 7.5f;\n    if (_1373)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1363)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1363)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1435 = tex_color(param_5);\n                float4 _1437 = _1435 * color;\n                float4 param_6 = _1437;\n                float param_7 = mode;\n                float _1444 = _1437.w;\n                frag_color = float4(lit_color(param_6, param_7), _1444);\n                if (_429_fx_rim.w > 0.5f)\n                {\n                    float param_8 = _1444;\n                    float param_9 = mode;\n                    float4 _1460 = frag_color;\n                    float3 _1462 = _1460.xyz + rim_color(param_8, param_9);\n                    frag_color.x = _1462.x;\n                    frag_color.y = _1462.y;\n                    frag_color.z = _1462.z;\n                }\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1492 = length(uv);\n                    float _1495 = fwidth(_1492);\n                    float _1496 = max(_1495, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1492) / _1496) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1492) / _1496) + 0.5f, 0.0f, 1.0f) * clamp(((_1492 - params.y) / _1496) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1536 = clamp(1.0f - _1492, 0.0f, 1.0f);\n                            cov = (_1536 * _1536) * (3.0f - (2.0f * _1536));\n                        }\n                    }\n                    float3 _1545;\n                    if (_1363)\n                    {\n                        float4 param_10 = color;\n                        float param_11 = 5.0f;\n                        _1545 = lit_color(param_10, param_11);\n                    }\n                    else\n                    {\n                        _1545 = color.xyz;\n                    }\n                    frag_color = float4(_1545, color.w * cov);\n                }\n            }\n        }\n    }\n    if (_429_fx_emit.w > 0.5f)\n    {\n        float3 e = _429_fx_emit.xyz;\n        if (_429_fx_emit.w > 1.5f)\n        {\n            float3 param_12 = fx_emissive_tex.Sample(smp, (uv * _429_fx_emit_uv.xy) + _429_fx_emit_uv.zw).xyz;\n            float param_13 = _429_fx_emit.w - 2.0f;\n            float3 _1600 = fa_tex_fix(param_12, param_13);\n            e *= _1600;\n        }\n        float4 _1604 = frag_color;\n        float3 _1606 = _1604.xyz + e;\n        frag_color.x = _1606.x;\n        frag_color.y = _1606.y;\n        frag_color.z = _1606.z;\n    }\n    float param_14 = mode;\n    float4 _1933 = frag_color;\n    fa_inst_load();\n    QuadInput param_15 = fa_quad_input(param_14);\n    QuadSurface _1935 = { _1933 };\n    QuadSurface param_16 = _1935;\n    fragment(param_15, param_16);\n    _1933 = param_16.color;\n    frag_color = param_16.color;\n    if (_1353)\n    {\n        float4 _1632 = frag_color;\n        float3 param_17 = color2.xyz;\n        float3 _1637 = scene_rgb(param_17);\n        float3 _1641 = lerp(_1632.xyz, _1637, color2.w.xxx);\n        frag_color.x = _1641.x;\n        frag_color.y = _1641.y;\n        frag_color.z = _1641.z;\n    }\n    if (_1373)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1665 = _429_fog_col.w > 0.0f;\n    bool _1673;\n    if (!_1665)\n    {\n        _1673 = _429_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1673 = _1665;\n    }\n    if (_1673)\n    {\n        float3 _1687 = float3(world_xy, world_z) - _429_fog_eye.xyz;\n        float _1694 = dot(_1687, _429_fog_c.xyz);\n        bool _1698 = _429_fog_c.w > 0.5f;\n        float _1699;\n        if (_1698)\n        {\n            _1699 = _1694;\n        }\n        else\n        {\n            _1699 = length(_1687);\n        }\n        float _1711 = _1699 - _429_fog_b.x;\n        if (_1711 > 0.0f)\n        {\n            float _1720 = _429_fog_col.w * _1711;\n            float tau = _1720 * _1720;\n            if (_429_fog_b.y > 0.0f)\n            {\n                float _1736;\n                if (_1698)\n                {\n                    _1736 = world_xy.y - (_429_fog_c.y * _1694);\n                }\n                else\n                {\n                    _1736 = _429_fog_eye.y;\n                }\n                float _1757 = lerp(_1736, world_xy.y, clamp(_429_fog_b.x / _1699, 0.0f, 1.0f));\n                float _1761 = world_xy.y - _1757;\n                float _1766 = _1757 - _429_fog_b.z;\n                float _1771 = world_xy.y - _429_fog_b.z;\n                bool _1774 = _1766 <= 0.0f;\n                bool _1775 = !_1774;\n                bool _1781;\n                if (_1775)\n                {\n                    _1781 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1781 = _1774;\n                }\n                float _1782;\n                if (_1781)\n                {\n                    _1782 = _429_fog_b.y;\n                }\n                else\n                {\n                    _1782 = _429_fog_b.y * exp(-min(_429_fog_b.w * _1766, 80.0f));\n                }\n                bool _1809;\n                if (_1775)\n                {\n                    _1809 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1809 = _1774;\n                }\n                float _1810;\n                if (_1809)\n                {\n                    _1810 = _429_fog_b.y * _1766;\n                }\n                else\n                {\n                    _1810 = (_429_fog_b.y * (1.0f - exp(-min(_429_fog_b.w * _1766, 80.0f)))) / _429_fog_b.w;\n                }\n                bool _1835 = _1771 <= 0.0f;\n                bool _1842;\n                if (!_1835)\n                {\n                    _1842 = _429_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1842 = _1835;\n                }\n                float _1843;\n                if (_1842)\n                {\n                    _1843 = _429_fog_b.y * _1771;\n                }\n                else\n                {\n                    _1843 = (_429_fog_b.y * (1.0f - exp(-min(_429_fog_b.w * _1771, 80.0f)))) / _429_fog_b.w;\n                }\n                float _1870;\n                if (abs(_1761) < 0.001000000047497451305389404296875f)\n                {\n                    _1870 = _1782;\n                }\n                else\n                {\n                    _1870 = (_1843 - _1810) / _1761;\n                }\n                tau += (_1711 * max(_1870, 0.0f));\n            }\n            float4 _1893 = frag_color;\n            float3 _1901 = lerp(_1893.xyz, _429_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1901.x;\n            frag_color.y = _1901.y;\n            frag_color.z = _1901.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_index_v = stage_input.fa_inst_index_v;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
              "hlsl_register_t_n": 6
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t0);\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _105_view_proj : packoffset(c0);\n    float4 _105_cspace : packoffset(c4);\n    float4 _105_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic int fa_inst_index_v;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    float3 _68 = v.world_pos;\n    float2 _76 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xy + (_68.xy * asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w);\n    v.world_pos.x = _76.x;\n    v.world_pos.y = _76.y;\n}\n\nvoid vert_main()\n{\n    fa_inst_index_v = gl_InstanceIndex;\n    float3 _178 = position;\n    float2 _179 = texcoord0;\n    float4 _180 = color0;\n    if (_105_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _117 = fa_srgb_to_linear(param);\n        float4 _192 = _180;\n        _192.x = _117.x;\n        _192.y = _117.y;\n        _192.z = _117.z;\n        _180 = _192;\n    }\n    QuadVertex _187 = { _178, _179, _180 };\n    QuadVertex param_1 = _187;\n    vertex(param_1);\n    _178 = param_1.world_pos;\n    _179 = param_1.uv;\n    _180 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _105_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _105_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_index_v = fa_inst_index_v;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _129_lit : packoffset(c0);\n    float4 _129_ambient : packoffset(c1);\n    float4 _129_normal_uv : packoffset(c2);\n    float4 _129_flat_ambient : packoffset(c3);\n    float4 _129_light_map : packoffset(c4);\n    float4 _129_light_pos[16] : packoffset(c5);\n    float4 _129_light_color[16] : packoffset(c21);\n    float4 _129_light_shadow_v[16] : packoffset(c37);\n    float4 _129_fog_col : packoffset(c53);\n    float4 _129_fog_b : packoffset(c54);\n    float4 _129_fog_c : packoffset(c55);\n    float4 _129_fog_eye : packoffset(c56);\n    float4 _129_fa_time : packoffset(c57);\n    float4 _129_fa_target : packoffset(c58);\n    float4 _129_fx_emit : packoffset(c59);\n    float4 _129_fx_emit_uv : packoffset(c60);\n    float4 _129_fx_rim : packoffset(c61);\n    float4 _129_fx_rim_uv : packoffset(c62);\n    float4 _129_light_cookie[16] : packoffset(c63);\n    float4 _129_light_cookie_xf[16] : packoffset(c79);\n};\n\nByteAddressBuffer points : register(t1);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic int fa_inst_index_v;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _136 = gl_FragCoord.xy * _129_fa_target.xy;\n    float _142 = _136.y;\n    return float2(_136.x, lerp(_142, 1.0f - _142, _129_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _186 = base_mode < 0.5f;\n    bool _197;\n    if (!_186)\n    {\n        _197 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _197 = _186;\n    }\n    float _198;\n    if (_197)\n    {\n        _198 = shape_half.x;\n    }\n    else\n    {\n        _198 = 0.0f;\n    }\n    QuadInput _325 = { uv, color, world_xy, fa_screen_uv(), _129_fa_time.x, base_mode, 0.0f.xxxx, _198 };\n    return _325;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).x;\n    s.color.y = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).y;\n    s.color.z = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).z;\n}\n\nvoid frag_main()\n{\n    float4 _240 = tex.Sample(smp, uv);\n    float3 param = _240.xyz;\n    float param_1 = xform.y;\n    float3 _251 = fa_tex_fix(param, param_1);\n    frag_color = float4(_251, _240.w) * color;\n    float param_2 = 0.0f;\n    float4 _305 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _307 = { _305 };\n    QuadSurface param_4 = _307;\n    fragment(param_3, param_4);\n    _305 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_index_v = stage_input.fa_inst_index_v;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
