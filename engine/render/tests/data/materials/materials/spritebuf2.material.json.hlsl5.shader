{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "hlsl5",
  "params": [],
  "textures": [],
  "kind": "sprite",
  "buffers": [
    {
      "name": "extra",
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
    },
    {
      "name": "points",
      "binding": 1,
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _122_view_proj : packoffset(c0);\n    float4 _122_cspace : packoffset(c4);\n    float4 _122_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic int fa_inst_index_v;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    float3 _86 = v.world_pos;\n    float2 _93 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xy + ((_86.xy * asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w) * ((asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f)) ? 0.0f : 1.0f));\n    v.world_pos.x = _93.x;\n    v.world_pos.y = _93.y;\n}\n\nvoid vert_main()\n{\n    fa_inst_index_v = gl_InstanceIndex;\n    float3 _192 = position;\n    float2 _193 = texcoord0;\n    float4 _194 = color0;\n    if (_122_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _132 = fa_srgb_to_linear(param);\n        float4 _206 = _194;\n        _206.x = _132.x;\n        _206.y = _132.y;\n        _206.z = _132.z;\n        _194 = _206;\n    }\n    QuadVertex _201 = { _192, _193, _194 };\n    QuadVertex param_1 = _201;\n    vertex(param_1);\n    _192 = param_1.world_pos;\n    _193 = param_1.uv;\n    _194 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _122_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _122_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_index_v = fa_inst_index_v;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _565_lit : packoffset(c0);\n    float4 _565_ambient : packoffset(c1);\n    float4 _565_normal_uv : packoffset(c2);\n    float4 _565_flat_ambient : packoffset(c3);\n    float4 _565_light_map : packoffset(c4);\n    float4 _565_light_pos[16] : packoffset(c5);\n    float4 _565_light_color[16] : packoffset(c21);\n    float4 _565_light_shadow_v[16] : packoffset(c37);\n    float4 _565_fog_col : packoffset(c53);\n    float4 _565_fog_b : packoffset(c54);\n    float4 _565_fog_c : packoffset(c55);\n    float4 _565_fog_eye : packoffset(c56);\n    float4 _565_fa_time : packoffset(c57);\n    float4 _565_fa_target : packoffset(c58);\n};\n\nByteAddressBuffer points : register(t4);\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic int fa_inst_index_v;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _504 = fa_linear_to_srgb(param);\n        c = _504;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _512 = fa_srgb_to_linear(param_1);\n            c = _512;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _523 = tex.Sample(smp, p);\n    float3 param = _523.xyz;\n    float param_1 = xform.y;\n    float3 _533 = fa_tex_fix(param, param_1);\n    return float4(_533, _523.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _109 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_109.x * 255.0f) + 0.5f) * 256.0f) + floor((_109.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _212 = floor(tt);\n    float _222 = _212 - (1024.0f * floor(_212 * 0.0009765625f));\n    float _225 = _222 + 1.0f;\n    float i1 = _225;\n    if (_225 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _222;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _212);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _262 = length(d);\n    float result = 1.0f;\n    if (_262 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _273 = atan2(d.y, d.x);\n        float a = _273;\n        float _276;\n        if (_273 < 0.0f)\n        {\n            _276 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _276 = a;\n        }\n        a = _276;\n        float _286 = _276 * 162.9746551513671875f;\n        float _295 = min((size * 10.0f) / _262, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _323 = floor(_286 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _295));\n            float param = v;\n            float param_1 = _323 - (1024.0f * floor(_323 * 0.0009765625f));\n            float _337 = shadow_texel(param, param_1) * radius;\n            if (_337 < _262)\n            {\n                sum += _337;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _369 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _262)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _387 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _393 = 1.0f - (0.800000011920928955078125f * abs(_387));\n                float param_2 = v;\n                float param_3 = _286 + (_387 * _369);\n                float param_4 = _262;\n                float param_5 = radius;\n                acc += (_393 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _393;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _133 = length(d);\n    if (_133 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _147 = atan2(d.y, d.x);\n    float a = _147;\n    float _150;\n    if (_147 < 0.0f)\n    {\n        _150 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _150 = a;\n    }\n    a = _150;\n    float _162 = _150 * 162.9746551513671875f;\n    float _167 = min(floor(_162), 1023.0f);\n    float _174 = _167 + 1.0f;\n    float i1 = _174;\n    if (_174 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _167;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _133) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _133) + 0.5f, 0.0f, 1.0f), _162 - _167);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _661 = _565_lit.y > 0.5f;\n    if (_661)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _565_normal_uv.xy) + _565_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _685 = fa_tex_fix(param, param_1);\n        float3 _689 = (_685 * 2.0f) - 1.0f.xxx;\n        float _696 = cos(params.y);\n        float _698 = sin(params.y);\n        n = normalize(float3((float2(_696, _698) * _689.x) + ((float2(-_698, _696) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _689.y), max(_689.z, 0.0500000007450580596923828125f)));\n    }\n    bool _732 = !_661;\n    bool _738;\n    if (_732)\n    {\n        _738 = _565_lit.z > 0.5f;\n    }\n    else\n    {\n        _738 = _732;\n    }\n    float3 _741;\n    if (_738)\n    {\n        _741 = _565_flat_ambient.xyz;\n    }\n    else\n    {\n        _741 = _565_ambient.xyz;\n    }\n    float3 total = _741;\n    bool _758;\n    if (_738)\n    {\n        _758 = _565_lit.z < 1.5f;\n    }\n    else\n    {\n        _758 = _738;\n    }\n    if (_758)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _565_light_map.xy, 0.0f).xyz * _565_light_map.z);\n    }\n    float3 l;\n    float _878;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _796;\n        if (!_738)\n        {\n            _796 = float(i) >= _565_lit.x;\n        }\n        else\n        {\n            _796 = _738;\n        }\n        if (_796)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_565_light_pos[i].w < 0.0f)\n        {\n            l = _565_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _822 = _565_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_822) / max(_565_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _565_light_color[i].w);\n            float3 _842 = float3(_822, _565_light_pos[i].z);\n            l = _842 / max(length(_842), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_565_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _565_light_shadow_v[i].x;\n                float param_3 = _565_light_shadow_v[i].y;\n                float2 param_4 = -_822;\n                float param_5 = _565_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_661)\n        {\n            _878 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _878 = 1.0f;\n        }\n        total += (_565_light_color[i].xyz * (att * _878));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _550 = fa_srgb_to_linear(param);\n        c = _550;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _906 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _910 = uv * _906;\n    float _916 = _906.x;\n    float _918 = _906.y;\n    float _920 = clamp(shape_rs.x, 0.0f, min(_916, _918));\n    float2 _931 = (abs(_910) - _906) + _920.xx;\n    float d = (length(max(_931, 0.0f.xx)) + min(max(_931.x, _931.y), 0.0f)) - _920;\n    float ax = params.y;\n    bool _952 = params.y > 15.0f;\n    if (_952)\n    {\n        ax -= 20.0f;\n    }\n    float _963;\n    if (ax <= (-1.5f))\n    {\n        _963 = (-2.0f) - ax;\n    }\n    else\n    {\n        _963 = 0.0f;\n    }\n    if (_963 > 0.0f)\n    {\n        float _977 = _963 * 0.5f;\n        d = abs(d + _977) - _977;\n    }\n    float _985 = fwidth(d);\n    float _986 = max(_985, 9.9999997473787516355514526367188e-05f);\n    float _996 = clamp(0.5f - (d / max(shape_rs.y, _986)), 0.0f, 1.0f);\n    float _1001;\n    if (shape_rs.y > _986)\n    {\n        _1001 = (_996 * _996) * (3.0f - (2.0f * _996));\n    }\n    else\n    {\n        _1001 = _996;\n    }\n    float4 c = color;\n    bool _1023 = (_963 <= 0.0f) && (ax > (-0.5f));\n    if (_1023)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1038 = cos(ax);\n            float _1040 = sin(ax);\n            g = ((dot(_910, float2(_1038, _1040)) / max((abs(_1038) * _916) + (abs(_1040) * _918), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_952)\n        {\n            float4 _1083 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1083;\n            float3 param = _1083.xyz;\n            float param_1 = xform.y;\n            float3 _1090 = fa_tex_fix(param, param_1);\n            float4 _1791 = c;\n            _1791.x = _1090.x;\n            _1791.y = _1090.y;\n            _1791.z = _1090.z;\n            c = _1791;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1102 = scene_rgb(param_2);\n            float4 _1127 = lerp(float4(color.xyz * color.w, color.w), float4(_1102 * color2.w, color2.w), g.xxxx);\n            float _1129 = _1127.w;\n            float3 _1132;\n            if (_1129 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1132 = _1127.xyz / _1129.xxx;\n            }\n            else\n            {\n                _1132 = color.xyz;\n            }\n            c = float4(_1132, _1129);\n        }\n    }\n    float4 _1800 = c;\n    _1800.w = _1800.w * _1001;\n    c = _1800;\n    if (_1023 || (shape_rs.y > 0.0f))\n    {\n        float _1173 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1182 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1182 + (_1173 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1188 = fa_srgb_to_linear(param_4);\n            float4 _1803 = c;\n            _1803.x = _1188.x;\n            _1803.y = _1188.y;\n            _1803.z = _1188.z;\n            c = _1803;\n        }\n        else\n        {\n            float4 _1198 = c;\n            float3 _1201 = _1198.xyz + (_1173 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1810 = _1198;\n            _1810.x = _1201.x;\n            _1810.y = _1201.y;\n            _1810.z = _1201.z;\n            c = _1810;\n        }\n        float4 _1815 = c;\n        _1815.w = clamp(_1815.w + ((_1173 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1815.w)), 0.0f, 1.0f);\n        c = _1815;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _571 = gl_FragCoord.xy * _565_fa_target.xy;\n    float _575 = _571.y;\n    return float2(_571.x, lerp(_575, 1.0f - _575, _565_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _614 = base_mode < 0.5f;\n    bool _625;\n    if (!_614)\n    {\n        _625 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _625 = _614;\n    }\n    float _626;\n    if (_625)\n    {\n        _626 = shape_half.x;\n    }\n    else\n    {\n        _626 = 0.0f;\n    }\n    QuadInput _1764 = { uv, color, world_xy, fa_screen_uv(), _565_fa_time.x, base_mode, 0.0f.xxxx, _626 };\n    return _1764;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).x;\n    s.color.y = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).y;\n    s.color.z = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1228 = params.x > 31.5f;\n    if (_1228)\n    {\n        mode -= 32.0f;\n    }\n    float _1236 = mode;\n    bool _1238 = _1236 > 15.5f;\n    if (_1238)\n    {\n        mode -= 16.0f;\n    }\n    float _1246 = mode;\n    bool _1248 = _1246 > 7.5f;\n    if (_1248)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1238)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1238)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1312 = tex_color(param_5) * color;\n                float4 param_6 = _1312;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1312.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1347 = length(uv);\n                    float _1350 = fwidth(_1347);\n                    float _1351 = max(_1350, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1347) / _1351) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1347) / _1351) + 0.5f, 0.0f, 1.0f) * clamp(((_1347 - params.y) / _1351) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1391 = clamp(1.0f - _1347, 0.0f, 1.0f);\n                            cov = (_1391 * _1391) * (3.0f - (2.0f * _1391));\n                        }\n                    }\n                    float3 _1400;\n                    if (_1238)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1400 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1400 = color.xyz;\n                    }\n                    frag_color = float4(_1400, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1744 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1746 = { _1744 };\n    QuadSurface param_12 = _1746;\n    fragment(param_11, param_12);\n    _1744 = param_12.color;\n    frag_color = param_12.color;\n    if (_1228)\n    {\n        float4 _1438 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1443 = scene_rgb(param_13);\n        float3 _1447 = lerp(_1438.xyz, _1443, color2.w.xxx);\n        frag_color.x = _1447.x;\n        frag_color.y = _1447.y;\n        frag_color.z = _1447.z;\n    }\n    if (_1248)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1471 = _565_fog_col.w > 0.0f;\n    bool _1479;\n    if (!_1471)\n    {\n        _1479 = _565_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1479 = _1471;\n    }\n    if (_1479)\n    {\n        float3 _1493 = float3(world_xy, world_z) - _565_fog_eye.xyz;\n        float _1500 = dot(_1493, _565_fog_c.xyz);\n        bool _1504 = _565_fog_c.w > 0.5f;\n        float _1505;\n        if (_1504)\n        {\n            _1505 = _1500;\n        }\n        else\n        {\n            _1505 = length(_1493);\n        }\n        float _1517 = _1505 - _565_fog_b.x;\n        if (_1517 > 0.0f)\n        {\n            float _1526 = _565_fog_col.w * _1517;\n            float tau = _1526 * _1526;\n            if (_565_fog_b.y > 0.0f)\n            {\n                float _1542;\n                if (_1504)\n                {\n                    _1542 = world_xy.y - (_565_fog_c.y * _1500);\n                }\n                else\n                {\n                    _1542 = _565_fog_eye.y;\n                }\n                float _1563 = lerp(_1542, world_xy.y, clamp(_565_fog_b.x / _1505, 0.0f, 1.0f));\n                float _1567 = world_xy.y - _1563;\n                float _1572 = _1563 - _565_fog_b.z;\n                float _1577 = world_xy.y - _565_fog_b.z;\n                bool _1580 = _1572 <= 0.0f;\n                bool _1581 = !_1580;\n                bool _1587;\n                if (_1581)\n                {\n                    _1587 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1587 = _1580;\n                }\n                float _1588;\n                if (_1587)\n                {\n                    _1588 = _565_fog_b.y;\n                }\n                else\n                {\n                    _1588 = _565_fog_b.y * exp(-min(_565_fog_b.w * _1572, 80.0f));\n                }\n                bool _1615;\n                if (_1581)\n                {\n                    _1615 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1615 = _1580;\n                }\n                float _1616;\n                if (_1615)\n                {\n                    _1616 = _565_fog_b.y * _1572;\n                }\n                else\n                {\n                    _1616 = (_565_fog_b.y * (1.0f - exp(-min(_565_fog_b.w * _1572, 80.0f)))) / _565_fog_b.w;\n                }\n                bool _1641 = _1577 <= 0.0f;\n                bool _1648;\n                if (!_1641)\n                {\n                    _1648 = _565_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1648 = _1641;\n                }\n                float _1649;\n                if (_1648)\n                {\n                    _1649 = _565_fog_b.y * _1577;\n                }\n                else\n                {\n                    _1649 = (_565_fog_b.y * (1.0f - exp(-min(_565_fog_b.w * _1577, 80.0f)))) / _565_fog_b.w;\n                }\n                float _1676;\n                if (abs(_1567) < 0.001000000047497451305389404296875f)\n                {\n                    _1676 = _1588;\n                }\n                else\n                {\n                    _1676 = (_1649 - _1616) / _1567;\n                }\n                tau += (_1517 * max(_1676, 0.0f));\n            }\n            float4 _1699 = frag_color;\n            float3 _1707 = lerp(_1699.xyz, _565_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1707.x;\n            frag_color.y = _1707.y;\n            frag_color.z = _1707.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_index_v = stage_input.fa_inst_index_v;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_122",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
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
      "vs": "struct QuadVertex\n{\n    float3 world_pos;\n    float2 uv;\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nstruct extra_item\n{\n    float4 pos;\n    float4 tint;\n};\n\nByteAddressBuffer fa_vs_points : register(t1);\nByteAddressBuffer fa_vs_extra : register(t0);\ncbuffer vs_params : register(b0)\n{\n    row_major float4x4 _122_view_proj : packoffset(c0);\n    float4 _122_cspace : packoffset(c4);\n    float4 _122_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic int gl_InstanceIndex;\nstatic int fa_inst_index_v;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n    uint gl_InstanceIndex : SV_InstanceID;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vertex(inout QuadVertex v)\n{\n    float3 _86 = v.world_pos;\n    float2 _93 = asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).xy + ((_86.xy * asfloat(fa_vs_points.Load4(gl_InstanceIndex * 32 + 0)).w) * ((asfloat(fa_vs_extra.Load(gl_InstanceIndex * 32 + 12)) < (-1.0f)) ? 0.0f : 1.0f));\n    v.world_pos.x = _93.x;\n    v.world_pos.y = _93.y;\n}\n\nvoid vert_main()\n{\n    fa_inst_index_v = gl_InstanceIndex;\n    float3 _192 = position;\n    float2 _193 = texcoord0;\n    float4 _194 = color0;\n    if (_122_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _132 = fa_srgb_to_linear(param);\n        float4 _206 = _194;\n        _206.x = _132.x;\n        _206.y = _132.y;\n        _206.z = _132.z;\n        _194 = _206;\n    }\n    QuadVertex _201 = { _192, _193, _194 };\n    QuadVertex param_1 = _201;\n    vertex(param_1);\n    _192 = param_1.world_pos;\n    _193 = param_1.uv;\n    _194 = param_1.color;\n    gl_Position = mul(float4(param_1.world_pos, 1.0f), _122_view_proj);\n    uv = param_1.uv;\n    color = param_1.color;\n    xform = _122_cspace.xyz;\n    params = params0;\n    world_xy = param_1.world_pos.xy;\n    world_z = param_1.world_pos.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_InstanceIndex = int(stage_input.gl_InstanceIndex);\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.fa_inst_index_v = fa_inst_index_v;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\nstruct points_item\n{\n    float4 pos;\n    float4 tint;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _127_lit : packoffset(c0);\n    float4 _127_ambient : packoffset(c1);\n    float4 _127_normal_uv : packoffset(c2);\n    float4 _127_flat_ambient : packoffset(c3);\n    float4 _127_light_map : packoffset(c4);\n    float4 _127_light_pos[16] : packoffset(c5);\n    float4 _127_light_color[16] : packoffset(c21);\n    float4 _127_light_shadow_v[16] : packoffset(c37);\n    float4 _127_fog_col : packoffset(c53);\n    float4 _127_fog_b : packoffset(c54);\n    float4 _127_fog_c : packoffset(c55);\n    float4 _127_fog_eye : packoffset(c56);\n    float4 _127_fa_time : packoffset(c57);\n    float4 _127_fa_target : packoffset(c58);\n};\n\nByteAddressBuffer points : register(t1);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic int fa_inst_index_v;\nstatic float4 frag_color;\nstatic float3 xform;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    nointerpolation int fa_inst_index_v : TEXCOORD9;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _101 = fa_linear_to_srgb(param);\n        c = _101;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _110 = fa_srgb_to_linear(param_1);\n            c = _110;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _134 = gl_FragCoord.xy * _127_fa_target.xy;\n    float _140 = _134.y;\n    return float2(_134.x, lerp(_140, 1.0f - _140, _127_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _184 = base_mode < 0.5f;\n    bool _195;\n    if (!_184)\n    {\n        _195 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _195 = _184;\n    }\n    float _196;\n    if (_195)\n    {\n        _196 = shape_half.x;\n    }\n    else\n    {\n        _196 = 0.0f;\n    }\n    QuadInput _328 = { uv, color, world_xy, fa_screen_uv(), _127_fa_time.x, base_mode, 0.0f.xxxx, _196 };\n    return _328;\n}\n\nvoid fa_inst_load()\n{\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    s.color.x = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).x;\n    s.color.y = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).y;\n    s.color.z = asfloat(points.Load4(fa_inst_index_v * 32 + 16)).z;\n}\n\nvoid frag_main()\n{\n    float4 _238 = tex.Sample(smp, uv);\n    float3 param = _238.xyz;\n    float param_1 = xform.y;\n    float3 _249 = fa_tex_fix(param, param_1);\n    frag_color = float4(_249, _238.w) * color;\n    float param_2 = 0.0f;\n    float4 _308 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _310 = { _308 };\n    QuadSurface param_4 = _310;\n    fragment(param_3, param_4);\n    _308 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    fa_inst_index_v = stage_input.fa_inst_index_v;\n    xform = stage_input.xform;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_122",
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "hlsl_register_t_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "hlsl_register_t_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
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
