{
  "format": "factoria.shader/1",
  "engine": "0.33.0",
  "template": "c1e79074f2aeaac8a4969a5266649c9c9bd6dddadcf288d2b3f256eda8e982d0",
  "slang": "hlsl5",
  "params": [
    "tint"
  ],
  "textures": [],
  "kind": "sprite",
  "programs": {
    "quad": {
      "vs": "cbuffer vs_params : register(b0)\n{\n    row_major float4x4 _68_view_proj : packoffset(c0);\n    float4 _68_cspace : packoffset(c4);\n    float4 _68_fa_time : packoffset(c5);\n};\n\n\nstatic float4 gl_Position;\nstatic float3 position;\nstatic float2 texcoord0;\nstatic float4 color0;\nstatic float2 uv;\nstatic float4 color;\nstatic float3 xform;\nstatic float2 params;\nstatic float2 params0;\nstatic float2 world_xy;\nstatic float world_z;\nstatic float4 color2;\nstatic float4 color2_0;\nstatic float2 shape_half;\nstatic float2 shape_half0;\nstatic float2 shape_rs;\nstatic float2 shape_rs0;\n\nstruct SPIRV_Cross_Input\n{\n    float3 position : TEXCOORD0;\n    float2 texcoord0 : TEXCOORD1;\n    float4 color0 : TEXCOORD2;\n    float2 params0 : TEXCOORD3;\n    float4 color2_0 : TEXCOORD4;\n    float2 shape_half0 : TEXCOORD5;\n    float2 shape_rs0 : TEXCOORD6;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_Position : SV_Position;\n};\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nvoid vert_main()\n{\n    float4 _147 = color0;\n    if (_68_cspace.x > 0.5f)\n    {\n        float3 param = color0.xyz;\n        float3 _82 = fa_srgb_to_linear(param);\n        float4 _152 = _147;\n        _152.x = _82.x;\n        _152.y = _82.y;\n        _152.z = _82.z;\n        _147 = _152;\n    }\n    gl_Position = mul(float4(position, 1.0f), _68_view_proj);\n    uv = texcoord0;\n    color = _147;\n    xform = _68_cspace.xyz;\n    params = params0;\n    world_xy = position.xy;\n    world_z = position.z;\n    color2 = color2_0;\n    shape_half = shape_half0;\n    shape_rs = shape_rs0;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    position = stage_input.position;\n    texcoord0 = stage_input.texcoord0;\n    color0 = stage_input.color0;\n    params0 = stage_input.params0;\n    color2_0 = stage_input.color2_0;\n    shape_half0 = stage_input.shape_half0;\n    shape_rs0 = stage_input.shape_rs0;\n    vert_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.gl_Position = gl_Position;\n    stage_output.uv = uv;\n    stage_output.color = color;\n    stage_output.xform = xform;\n    stage_output.params = params;\n    stage_output.world_xy = world_xy;\n    stage_output.world_z = world_z;\n    stage_output.color2 = color2;\n    stage_output.shape_half = shape_half;\n    stage_output.shape_rs = shape_rs;\n    return stage_output;\n}\n",
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _573_lit : packoffset(c0);\n    float4 _573_ambient : packoffset(c1);\n    float4 _573_normal_uv : packoffset(c2);\n    float4 _573_flat_ambient : packoffset(c3);\n    float4 _573_light_map : packoffset(c4);\n    float4 _573_light_pos[16] : packoffset(c5);\n    float4 _573_light_color[16] : packoffset(c21);\n    float4 _573_light_shadow_v[16] : packoffset(c37);\n    float4 _573_fog_col : packoffset(c53);\n    float4 _573_fog_b : packoffset(c54);\n    float4 _573_fog_c : packoffset(c55);\n    float4 _573_fog_eye : packoffset(c56);\n    float4 _573_fa_time : packoffset(c57);\n    float4 _573_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _648_tint : packoffset(c0);\n};\n\nTexture2D<float4> shadow_tex : register(t3);\nSamplerState shadow_smp : register(s2);\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\nTexture2D<float4> normal_tex : register(t1);\nTexture2D<float4> light_tex : register(t2);\nSamplerState light_smp : register(s1);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float2 params;\nstatic float2 shape_rs;\nstatic float4 color2;\nstatic float4 frag_color;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _507 = fa_linear_to_srgb(param);\n        c = _507;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _515 = fa_srgb_to_linear(param_1);\n            c = _515;\n        }\n    }\n    return c;\n}\n\nfloat4 tex_color(float2 p)\n{\n    float4 _526 = tex.Sample(smp, p);\n    float3 param = _526.xyz;\n    float param_1 = xform.y;\n    float3 _536 = fa_tex_fix(param, param_1);\n    return float4(_536, _526.w);\n}\n\nfloat shadow_texel(float v, float i)\n{\n    float4 _112 = shadow_tex.SampleLevel(shadow_smp, float2((i + 0.5f) * 0.0009765625f, v), 0.0f);\n    return ((floor((_112.x * 255.0f) + 0.5f) * 256.0f) + floor((_112.y * 255.0f) + 0.5f)) * 1.525902189314365386962890625e-05f;\n}\n\nfloat light_shadow_tap(float v, float tt, float dist, float radius)\n{\n    float _215 = floor(tt);\n    float _225 = _215 - (1024.0f * floor(_215 * 0.0009765625f));\n    float _228 = _225 + 1.0f;\n    float i1 = _228;\n    if (_228 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _225;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - dist) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - dist) + 0.5f, 0.0f, 1.0f), tt - _215);\n}\n\nfloat light_shadow_soft(float v, float size, float2 d, float radius)\n{\n    float _265 = length(d);\n    float result = 1.0f;\n    if (_265 >= 9.9999997473787516355514526367188e-05f)\n    {\n        float _276 = atan2(d.y, d.x);\n        float a = _276;\n        float _279;\n        if (_276 < 0.0f)\n        {\n            _279 = a + 6.283185482025146484375f;\n        }\n        else\n        {\n            _279 = a;\n        }\n        a = _279;\n        float _289 = _279 * 162.9746551513671875f;\n        float _298 = min((size * 10.0f) / _265, 0.699999988079071044921875f) * 162.9746551513671875f;\n        float sum = 0.0f;\n        float n = 0.0f;\n        for (int k = 0; k < 12; k++)\n        {\n            float _326 = floor(_289 + ((((float(k) + 0.5f) * 0.16666667163372039794921875f) - 1.0f) * _298));\n            float param = v;\n            float param_1 = _326 - (1024.0f * floor(_326 * 0.0009765625f));\n            float _340 = shadow_texel(param, param_1) * radius;\n            if (_340 < _265)\n            {\n                sum += _340;\n                n += 1.0f;\n            }\n        }\n        if (n > 0.5f)\n        {\n            float _372 = min(size * ((1.0f / max(sum / n, 1.0f)) - (1.0f / _265)), 0.699999988079071044921875f) * 162.9746551513671875f;\n            float acc = 0.0f;\n            float wsum = 0.0f;\n            for (int k_1 = 0; k_1 < 16; k_1++)\n            {\n                float _390 = ((float(k_1) + 0.5f) * 0.125f) - 1.0f;\n                float _396 = 1.0f - (0.800000011920928955078125f * abs(_390));\n                float param_2 = v;\n                float param_3 = _289 + (_390 * _372);\n                float param_4 = _265;\n                float param_5 = radius;\n                acc += (_396 * light_shadow_tap(param_2, param_3, param_4, param_5));\n                wsum += _396;\n            }\n            result = acc / wsum;\n        }\n    }\n    return result;\n}\n\nfloat light_shadow(float v, float2 d, float radius)\n{\n    float _136 = length(d);\n    if (_136 < 9.9999997473787516355514526367188e-05f)\n    {\n        return 1.0f;\n    }\n    float _150 = atan2(d.y, d.x);\n    float a = _150;\n    float _153;\n    if (_150 < 0.0f)\n    {\n        _153 = a + 6.283185482025146484375f;\n    }\n    else\n    {\n        _153 = a;\n    }\n    a = _153;\n    float _165 = _153 * 162.9746551513671875f;\n    float _170 = min(floor(_165), 1023.0f);\n    float _177 = _170 + 1.0f;\n    float i1 = _177;\n    if (_177 > 1023.5f)\n    {\n        i1 = 0.0f;\n    }\n    float param = v;\n    float param_1 = _170;\n    float param_2 = v;\n    float param_3 = i1;\n    return lerp(clamp(((shadow_texel(param, param_1) * radius) - _136) + 0.5f, 0.0f, 1.0f), clamp(((shadow_texel(param_2, param_3) * radius) - _136) + 0.5f, 0.0f, 1.0f), _165 - _170);\n}\n\nfloat light_shadow_sized(float v, float size, float2 d, float radius)\n{\n    float r = 1.0f;\n    if (size > 0.0f)\n    {\n        float param = v;\n        float param_1 = size;\n        float2 param_2 = d;\n        float param_3 = radius;\n        r = light_shadow_soft(param, param_1, param_2, param_3);\n    }\n    else\n    {\n        float param_4 = v;\n        float2 param_5 = d;\n        float param_6 = radius;\n        r = light_shadow(param_4, param_5, param_6);\n    }\n    return r;\n}\n\nfloat3 lit_color(float4 base, float mode)\n{\n    float3 n = float3(0.0f, 0.0f, 1.0f);\n    bool _670 = _573_lit.y > 0.5f;\n    if (_670)\n    {\n        float3 param = normal_tex.Sample(smp, (uv * _573_normal_uv.xy) + _573_normal_uv.zw).xyz;\n        float param_1 = xform.z;\n        float3 _694 = fa_tex_fix(param, param_1);\n        float3 _698 = (_694 * 2.0f) - 1.0f.xxx;\n        float _705 = cos(params.y);\n        float _707 = sin(params.y);\n        n = normalize(float3((float2(_705, _707) * _698.x) + ((float2(-_707, _705) * ((mode > 5.5f) ? (-1.0f) : 1.0f)) * _698.y), max(_698.z, 0.0500000007450580596923828125f)));\n    }\n    bool _741 = !_670;\n    bool _747;\n    if (_741)\n    {\n        _747 = _573_lit.z > 0.5f;\n    }\n    else\n    {\n        _747 = _741;\n    }\n    float3 _750;\n    if (_747)\n    {\n        _750 = _573_flat_ambient.xyz;\n    }\n    else\n    {\n        _750 = _573_ambient.xyz;\n    }\n    float3 total = _750;\n    bool _767;\n    if (_747)\n    {\n        _767 = _573_lit.z < 1.5f;\n    }\n    else\n    {\n        _767 = _747;\n    }\n    if (_767)\n    {\n        total += (light_tex.SampleLevel(light_smp, gl_FragCoord.xy * _573_light_map.xy, 0.0f).xyz * _573_light_map.z);\n    }\n    float3 l;\n    float _887;\n    for (int i = 0; i < 16; i++)\n    {\n        bool _805;\n        if (!_747)\n        {\n            _805 = float(i) >= _573_lit.x;\n        }\n        else\n        {\n            _805 = _747;\n        }\n        if (_805)\n        {\n            break;\n        }\n        float att = 1.0f;\n        if (_573_light_pos[i].w < 0.0f)\n        {\n            l = _573_light_pos[i].xyz;\n        }\n        else\n        {\n            float2 _831 = _573_light_pos[i].xy - world_xy;\n            att = pow(clamp(1.0f - (length(_831) / max(_573_light_pos[i].w, 0.001000000047497451305389404296875f)), 0.0f, 1.0f), _573_light_color[i].w);\n            float3 _851 = float3(_831, _573_light_pos[i].z);\n            l = _851 / max(length(_851), 9.9999997473787516355514526367188e-05f).xxx;\n            if (_573_light_shadow_v[i].x >= 0.0f)\n            {\n                float param_2 = _573_light_shadow_v[i].x;\n                float param_3 = _573_light_shadow_v[i].y;\n                float2 param_4 = -_831;\n                float param_5 = _573_light_pos[i].w;\n                att *= light_shadow_sized(param_2, param_3, param_4, param_5);\n            }\n        }\n        if (_670)\n        {\n            _887 = max(dot(n, l), 0.0f);\n        }\n        else\n        {\n            _887 = 1.0f;\n        }\n        total += (_573_light_color[i].xyz * (att * _887));\n    }\n    return base.xyz * total;\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _553 = fa_srgb_to_linear(param);\n        c = _553;\n    }\n    return c;\n}\n\nfloat4 shape_color()\n{\n    float2 _915 = max(shape_half, 9.9999997473787516355514526367188e-05f.xx);\n    float2 _919 = uv * _915;\n    float _925 = _915.x;\n    float _927 = _915.y;\n    float _929 = clamp(shape_rs.x, 0.0f, min(_925, _927));\n    float2 _940 = (abs(_919) - _915) + _929.xx;\n    float d = (length(max(_940, 0.0f.xx)) + min(max(_940.x, _940.y), 0.0f)) - _929;\n    float ax = params.y;\n    bool _961 = params.y > 15.0f;\n    if (_961)\n    {\n        ax -= 20.0f;\n    }\n    float _972;\n    if (ax <= (-1.5f))\n    {\n        _972 = (-2.0f) - ax;\n    }\n    else\n    {\n        _972 = 0.0f;\n    }\n    if (_972 > 0.0f)\n    {\n        float _986 = _972 * 0.5f;\n        d = abs(d + _986) - _986;\n    }\n    float _994 = fwidth(d);\n    float _995 = max(_994, 9.9999997473787516355514526367188e-05f);\n    float _1005 = clamp(0.5f - (d / max(shape_rs.y, _995)), 0.0f, 1.0f);\n    float _1010;\n    if (shape_rs.y > _995)\n    {\n        _1010 = (_1005 * _1005) * (3.0f - (2.0f * _1005));\n    }\n    else\n    {\n        _1010 = _1005;\n    }\n    float4 c = color;\n    bool _1032 = (_972 <= 0.0f) && (ax > (-0.5f));\n    if (_1032)\n    {\n        float g;\n        if (ax > 7.0f)\n        {\n            g = length(uv);\n        }\n        else\n        {\n            float _1047 = cos(ax);\n            float _1049 = sin(ax);\n            g = ((dot(_919, float2(_1047, _1049)) / max((abs(_1047) * _925) + (abs(_1049) * _927), 9.9999997473787516355514526367188e-05f)) * 0.5f) + 0.5f;\n        }\n        g = clamp(g, 0.0f, 1.0f);\n        if (_961)\n        {\n            float4 _1092 = tex.SampleLevel(smp, float2((0.5f + (g * 255.0f)) * 0.00390625f, (floor((color2.x * 255.0f) + 0.5f) + 0.5f) * 0.00390625f), 0.0f);\n            c = _1092;\n            float3 param = _1092.xyz;\n            float param_1 = xform.y;\n            float3 _1099 = fa_tex_fix(param, param_1);\n            float4 _1795 = c;\n            _1795.x = _1099.x;\n            _1795.y = _1099.y;\n            _1795.z = _1099.z;\n            c = _1795;\n        }\n        else\n        {\n            float3 param_2 = color2.xyz;\n            float3 _1111 = scene_rgb(param_2);\n            float4 _1136 = lerp(float4(color.xyz * color.w, color.w), float4(_1111 * color2.w, color2.w), g.xxxx);\n            float _1138 = _1136.w;\n            float3 _1141;\n            if (_1138 > 9.9999997473787516355514526367188e-06f)\n            {\n                _1141 = _1136.xyz / _1138.xxx;\n            }\n            else\n            {\n                _1141 = color.xyz;\n            }\n            c = float4(_1141, _1138);\n        }\n    }\n    float4 _1804 = c;\n    _1804.w = _1804.w * _1010;\n    c = _1804;\n    if (_1032 || (shape_rs.y > 0.0f))\n    {\n        float _1182 = frac(52.98291778564453125f * frac(dot(gl_FragCoord.xy, float2(0.067110560834407806396484375f, 0.005837149918079376220703125f)))) - 0.5f;\n        if (xform.x > 0.5f)\n        {\n            float3 param_3 = c.xyz;\n            float3 _1191 = fa_linear_to_srgb(param_3);\n            float3 param_4 = _1191 + (_1182 * 0.0039215688593685626983642578125f).xxx;\n            float3 _1197 = fa_srgb_to_linear(param_4);\n            float4 _1807 = c;\n            _1807.x = _1197.x;\n            _1807.y = _1197.y;\n            _1807.z = _1197.z;\n            c = _1807;\n        }\n        else\n        {\n            float4 _1207 = c;\n            float3 _1210 = _1207.xyz + (_1182 * 0.0039215688593685626983642578125f).xxx;\n            float4 _1814 = _1207;\n            _1814.x = _1210.x;\n            _1814.y = _1210.y;\n            _1814.z = _1210.z;\n            c = _1814;\n        }\n        float4 _1819 = c;\n        _1819.w = clamp(_1819.w + ((_1182 * 0.0039215688593685626983642578125f) * step(0.001000000047497451305389404296875f, _1819.w)), 0.0f, 1.0f);\n        c = _1819;\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _579 = gl_FragCoord.xy * _573_fa_target.xy;\n    float _583 = _579.y;\n    return float2(_579.x, lerp(_583, 1.0f - _583, _573_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _622 = base_mode < 0.5f;\n    bool _633;\n    if (!_622)\n    {\n        _633 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _633 = _622;\n    }\n    float _634;\n    if (_633)\n    {\n        _634 = shape_half.x;\n    }\n    else\n    {\n        _634 = 0.0f;\n    }\n    QuadInput _1768 = { uv, color, world_xy, fa_screen_uv(), _573_fa_time.x, base_mode, 0.0f.xxxx, _634 };\n    return _1768;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _559 = scene_rgb(param);\n    return _559;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _648_tint.xyz;\n    float4 _655 = s.color;\n    float3 _657 = _655.xyz * fa_scene_rgb(param);\n    s.color.x = _657.x;\n    s.color.y = _657.y;\n    s.color.z = _657.z;\n}\n\nvoid frag_main()\n{\n    float mode = params.x;\n    bool _1237 = params.x > 31.5f;\n    if (_1237)\n    {\n        mode -= 32.0f;\n    }\n    float _1245 = mode;\n    bool _1247 = _1245 > 15.5f;\n    if (_1247)\n    {\n        mode -= 16.0f;\n    }\n    float _1255 = mode;\n    bool _1257 = _1255 > 7.5f;\n    if (_1257)\n    {\n        mode -= 8.0f;\n    }\n    if (mode < 0.5f)\n    {\n        float2 param = uv;\n        frag_color = tex_color(param) * color;\n        if (_1247)\n        {\n            float4 param_1 = frag_color;\n            float param_2 = 5.0f;\n            frag_color = float4(lit_color(param_1, param_2), frag_color.w);\n        }\n    }\n    else\n    {\n        if (mode > 6.5f)\n        {\n            frag_color = shape_color();\n            if (_1247)\n            {\n                float4 param_3 = frag_color;\n                float param_4 = 5.0f;\n                frag_color = float4(lit_color(param_3, param_4), frag_color.w);\n            }\n        }\n        else\n        {\n            if (mode > 4.5f)\n            {\n                float2 param_5 = uv;\n                float4 _1321 = tex_color(param_5) * color;\n                float4 param_6 = _1321;\n                float param_7 = mode;\n                frag_color = float4(lit_color(param_6, param_7), _1321.w);\n            }\n            else\n            {\n                if (mode > 3.5f)\n                {\n                    frag_color = float4(color.xyz, color.w * tex.Sample(smp, uv).x);\n                }\n                else\n                {\n                    float _1356 = length(uv);\n                    float _1359 = fwidth(_1356);\n                    float _1360 = max(_1359, 9.9999997473787516355514526367188e-05f);\n                    float cov;\n                    if (mode < 1.5f)\n                    {\n                        cov = clamp(((1.0f - _1356) / _1360) + 0.5f, 0.0f, 1.0f);\n                    }\n                    else\n                    {\n                        if (mode < 2.5f)\n                        {\n                            cov = clamp(((1.0f - _1356) / _1360) + 0.5f, 0.0f, 1.0f) * clamp(((_1356 - params.y) / _1360) + 0.5f, 0.0f, 1.0f);\n                        }\n                        else\n                        {\n                            float _1400 = clamp(1.0f - _1356, 0.0f, 1.0f);\n                            cov = (_1400 * _1400) * (3.0f - (2.0f * _1400));\n                        }\n                    }\n                    float3 _1409;\n                    if (_1247)\n                    {\n                        float4 param_8 = color;\n                        float param_9 = 5.0f;\n                        _1409 = lit_color(param_8, param_9);\n                    }\n                    else\n                    {\n                        _1409 = color.xyz;\n                    }\n                    frag_color = float4(_1409, color.w * cov);\n                }\n            }\n        }\n    }\n    float param_10 = mode;\n    float4 _1748 = frag_color;\n    fa_inst_load();\n    QuadInput param_11 = fa_quad_input(param_10);\n    QuadSurface _1750 = { _1748 };\n    QuadSurface param_12 = _1750;\n    fragment(param_11, param_12);\n    _1748 = param_12.color;\n    frag_color = param_12.color;\n    if (_1237)\n    {\n        float4 _1447 = frag_color;\n        float3 param_13 = color2.xyz;\n        float3 _1452 = scene_rgb(param_13);\n        float3 _1456 = lerp(_1447.xyz, _1452, color2.w.xxx);\n        frag_color.x = _1456.x;\n        frag_color.y = _1456.y;\n        frag_color.z = _1456.z;\n    }\n    if (_1257)\n    {\n        frag_color = float4(lerp(1.0f.xxx, frag_color.xyz, frag_color.w.xxx), 1.0f);\n    }\n    bool _1480 = _573_fog_col.w > 0.0f;\n    bool _1488;\n    if (!_1480)\n    {\n        _1488 = _573_fog_b.y > 0.0f;\n    }\n    else\n    {\n        _1488 = _1480;\n    }\n    if (_1488)\n    {\n        float3 _1502 = float3(world_xy, world_z) - _573_fog_eye.xyz;\n        float _1509 = dot(_1502, _573_fog_c.xyz);\n        bool _1513 = _573_fog_c.w > 0.5f;\n        float _1514;\n        if (_1513)\n        {\n            _1514 = _1509;\n        }\n        else\n        {\n            _1514 = length(_1502);\n        }\n        float _1526 = _1514 - _573_fog_b.x;\n        if (_1526 > 0.0f)\n        {\n            float _1535 = _573_fog_col.w * _1526;\n            float tau = _1535 * _1535;\n            if (_573_fog_b.y > 0.0f)\n            {\n                float _1551;\n                if (_1513)\n                {\n                    _1551 = world_xy.y - (_573_fog_c.y * _1509);\n                }\n                else\n                {\n                    _1551 = _573_fog_eye.y;\n                }\n                float _1572 = lerp(_1551, world_xy.y, clamp(_573_fog_b.x / _1514, 0.0f, 1.0f));\n                float _1576 = world_xy.y - _1572;\n                float _1581 = _1572 - _573_fog_b.z;\n                float _1586 = world_xy.y - _573_fog_b.z;\n                bool _1589 = _1581 <= 0.0f;\n                bool _1590 = !_1589;\n                bool _1596;\n                if (_1590)\n                {\n                    _1596 = _573_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1596 = _1589;\n                }\n                float _1597;\n                if (_1596)\n                {\n                    _1597 = _573_fog_b.y;\n                }\n                else\n                {\n                    _1597 = _573_fog_b.y * exp(-min(_573_fog_b.w * _1581, 80.0f));\n                }\n                bool _1624;\n                if (_1590)\n                {\n                    _1624 = _573_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1624 = _1589;\n                }\n                float _1625;\n                if (_1624)\n                {\n                    _1625 = _573_fog_b.y * _1581;\n                }\n                else\n                {\n                    _1625 = (_573_fog_b.y * (1.0f - exp(-min(_573_fog_b.w * _1581, 80.0f)))) / _573_fog_b.w;\n                }\n                bool _1650 = _1586 <= 0.0f;\n                bool _1657;\n                if (!_1650)\n                {\n                    _1657 = _573_fog_b.w < 9.9999997473787516355514526367188e-05f;\n                }\n                else\n                {\n                    _1657 = _1650;\n                }\n                float _1658;\n                if (_1657)\n                {\n                    _1658 = _573_fog_b.y * _1586;\n                }\n                else\n                {\n                    _1658 = (_573_fog_b.y * (1.0f - exp(-min(_573_fog_b.w * _1586, 80.0f)))) / _573_fog_b.w;\n                }\n                float _1685;\n                if (abs(_1576) < 0.001000000047497451305389404296875f)\n                {\n                    _1685 = _1597;\n                }\n                else\n                {\n                    _1685 = (_1658 - _1625) / _1576;\n                }\n                tau += (_1526 * max(_1685, 0.0f));\n            }\n            float4 _1708 = frag_color;\n            float3 _1716 = lerp(_1708.xyz, _573_fog_col.xyz, clamp(1.0f - exp(-clamp(tau, 0.0f, 80.0f)), 0.0f, 1.0f).xxx);\n            frag_color.x = _1716.x;\n            frag_color.y = _1716.y;\n            frag_color.z = _1716.z;\n        }\n    }\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    shape_rs = stage_input.shape_rs;\n    color2 = stage_input.color2;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_573",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_648",
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
      "fs": "struct QuadInput\n{\n    float2 uv;\n    float4 color;\n    float2 world_pos;\n    float2 screen_uv;\n    float time;\n    float mode;\n    float4 custom;\n    float life;\n};\n\nstruct QuadSurface\n{\n    float4 color;\n};\n\ncbuffer quad_fs_params : register(b1)\n{\n    float4 _153_lit : packoffset(c0);\n    float4 _153_ambient : packoffset(c1);\n    float4 _153_normal_uv : packoffset(c2);\n    float4 _153_flat_ambient : packoffset(c3);\n    float4 _153_light_map : packoffset(c4);\n    float4 _153_light_pos[16] : packoffset(c5);\n    float4 _153_light_color[16] : packoffset(c21);\n    float4 _153_light_shadow_v[16] : packoffset(c37);\n    float4 _153_fog_col : packoffset(c53);\n    float4 _153_fog_b : packoffset(c54);\n    float4 _153_fog_c : packoffset(c55);\n    float4 _153_fog_eye : packoffset(c56);\n    float4 _153_fa_time : packoffset(c57);\n    float4 _153_fa_target : packoffset(c58);\n};\n\ncbuffer fa_material : register(b5)\n{\n    float4 _235_tint : packoffset(c0);\n};\n\nTexture2D<float4> tex : register(t0);\nSamplerState smp : register(s0);\n\nstatic float4 gl_FragCoord;\nstatic float3 xform;\nstatic float2 uv;\nstatic float4 color;\nstatic float2 world_xy;\nstatic float2 shape_half;\nstatic float4 frag_color;\nstatic float2 params;\nstatic float4 color2;\nstatic float2 shape_rs;\nstatic float world_z;\n\nstruct SPIRV_Cross_Input\n{\n    float2 uv : TEXCOORD0;\n    float4 color : TEXCOORD1;\n    float2 params : TEXCOORD2;\n    float2 world_xy : TEXCOORD3;\n    float4 color2 : TEXCOORD4;\n    float2 shape_half : TEXCOORD5;\n    float2 shape_rs : TEXCOORD6;\n    float3 xform : TEXCOORD7;\n    float world_z : TEXCOORD8;\n    float4 gl_FragCoord : SV_Position;\n};\n\nstruct SPIRV_Cross_Output\n{\n    float4 frag_color : SV_Target0;\n};\n\nfloat3 fa_linear_to_srgb(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp((pow(c, 0.4166666567325592041015625f.xxx) * 1.05499994754791259765625f) - 0.054999999701976776123046875f.xxx, c * 12.9200000762939453125f, step(c, 0.003130800090730190277099609375f.xxx));\n}\n\nfloat3 fa_srgb_to_linear(inout float3 c)\n{\n    c = max(c, 0.0f.xxx);\n    return lerp(pow((c + 0.054999999701976776123046875f.xxx) * 0.947867333889007568359375f.xxx, 2.400000095367431640625f.xxx), c * 0.077399380505084991455078125f.xxx, step(c, 0.040449999272823333740234375f.xxx));\n}\n\nfloat3 fa_tex_fix(inout float3 c, float mode)\n{\n    if (mode > 1.5f)\n    {\n        float3 param = c;\n        float3 _107 = fa_linear_to_srgb(param);\n        c = _107;\n    }\n    else\n    {\n        if (mode > 0.5f)\n        {\n            float3 param_1 = c;\n            float3 _116 = fa_srgb_to_linear(param_1);\n            c = _116;\n        }\n    }\n    return c;\n}\n\nfloat2 fa_screen_uv()\n{\n    float2 _160 = gl_FragCoord.xy * _153_fa_target.xy;\n    float _165 = _160.y;\n    return float2(_160.x, lerp(_165, 1.0f - _165, _153_fa_target.z));\n}\n\nQuadInput fa_quad_input(float base_mode)\n{\n    bool _209 = base_mode < 0.5f;\n    bool _220;\n    if (!_209)\n    {\n        _220 = (base_mode > 2.5f) && (base_mode < 3.5f);\n    }\n    else\n    {\n        _220 = _209;\n    }\n    float _221;\n    if (_220)\n    {\n        _221 = shape_half.x;\n    }\n    else\n    {\n        _221 = 0.0f;\n    }\n    QuadInput _346 = { uv, color, world_xy, fa_screen_uv(), _153_fa_time.x, base_mode, 0.0f.xxxx, _221 };\n    return _346;\n}\n\nvoid fa_inst_load()\n{\n}\n\nfloat3 scene_rgb(inout float3 c)\n{\n    if (xform.x > 0.5f)\n    {\n        float3 param = c;\n        float3 _132 = fa_srgb_to_linear(param);\n        c = _132;\n    }\n    return c;\n}\n\nfloat3 fa_scene_rgb(float3 c)\n{\n    float3 param = c;\n    float3 _138 = scene_rgb(param);\n    return _138;\n}\n\nvoid fragment(QuadInput i, inout QuadSurface s)\n{\n    float3 param = _235_tint.xyz;\n    float4 _242 = s.color;\n    float3 _244 = _242.xyz * fa_scene_rgb(param);\n    s.color.x = _244.x;\n    s.color.y = _244.y;\n    s.color.z = _244.z;\n}\n\nvoid frag_main()\n{\n    float4 _263 = tex.Sample(smp, uv);\n    float3 param = _263.xyz;\n    float param_1 = xform.y;\n    float3 _272 = fa_tex_fix(param, param_1);\n    frag_color = float4(_272, _263.w) * color;\n    float param_2 = 0.0f;\n    float4 _326 = frag_color;\n    fa_inst_load();\n    QuadInput param_3 = fa_quad_input(param_2);\n    QuadSurface _328 = { _326 };\n    QuadSurface param_4 = _328;\n    fragment(param_3, param_4);\n    _326 = param_4.color;\n    frag_color = param_4.color;\n}\n\nSPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)\n{\n    gl_FragCoord = stage_input.gl_FragCoord;\n    gl_FragCoord.w = 1.0 / gl_FragCoord.w;\n    xform = stage_input.xform;\n    uv = stage_input.uv;\n    color = stage_input.color;\n    world_xy = stage_input.world_xy;\n    shape_half = stage_input.shape_half;\n    params = stage_input.params;\n    color2 = stage_input.color2;\n    shape_rs = stage_input.shape_rs;\n    world_z = stage_input.world_z;\n    frag_main();\n    SPIRV_Cross_Output stage_output;\n    stage_output.frag_color = frag_color;\n    return stage_output;\n}\n",
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
            "inst_name": "_153",
            "hlsl_register_b_n": 1
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_235",
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
