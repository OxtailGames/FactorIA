{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "f6bab862063fc78fa36c872857ecf1496db0539b9f7c615323d4db57d82028e1",
  "slang": "glsl430",
  "params": [
    "base"
  ],
  "textures": [],
  "full": true,
  "shadow": "none",
  "prepass": false,
  "passes": [
    {
      "name": "main",
      "cull": "back",
      "depthTest": true,
      "depthWrite": true,
      "blend": "none",
      "program": "mesh",
      "programSkin": "mesh_skin"
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _109 = fa_world_position(param);\n    v_pos = _109;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _109;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_109, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _135 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _142 = fa_light_texel(param_1);\n    float _147 = _142.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _155 = _147 < 0.5;\n    vec3 l;\n    if (_155)\n    {\n        l = normalize(_135.xyz);\n    }\n    else\n    {\n        vec3 _167 = _135.xyz - world_pos;\n        float _169 = length(_167);\n        dist = _169;\n        l = _167 / vec3(max(_169, 9.9999997473787516355514526367188e-05));\n        float _184 = _169 / max(_135.w, 0.001000000047497451305389404296875);\n        float _190 = clamp(1.0 - (_184 * _184), 0.0, 1.0);\n        atten = _190 * _190;\n        if (_147 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _205 = fa_light_texel(param_2);\n            float _215 = _205.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _222 = fa_light_texel(param_3);\n            float _224 = _222.x;\n            float cos_inner = _224;\n            if (_224 > 1.5)\n            {\n                cos_inner = mix(_215, 1.0, 0.25);\n            }\n            atten *= smoothstep(_215, cos_inner, dot(-l, normalize(_205.xyz)));\n        }\n    }\n    int _255;\n    if (_155)\n    {\n        _255 = 0;\n    }\n    else\n    {\n        _255 = (_147 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _142.xyz * atten, atten, 1.0, dist, _255);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _307;\n    if (i == 0)\n    {\n        _307 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _324;\n        if (i == 1)\n        {\n            _324 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _333;\n            if (i == 2)\n            {\n                _333 = fa_shadows[24].z;\n            }\n            else\n            {\n                _333 = fa_shadows[24].w;\n            }\n            _324 = _333;\n        }\n        _307 = _324;\n    }\n    return _307;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _367 = fa_shadow_depth(param, param_1);\n    float _371;\n    if (conv.x < 0.5)\n    {\n        _371 = _367;\n    }\n    else\n    {\n        _371 = (conv.y * conv.z) / (conv.z - (_367 * (conv.z - conv.y)));\n    }\n    return _371;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _295 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_295), sin(_295)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _418 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _432 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _418;\n            vec2 _452 = fa_shadow_vogel(param_3, param_4, param_5) * _432;\n            vec2 param_6 = uv + (_452 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _464 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_464 < (zr - (length(_452) * plane)))\n            {\n                sum += _464;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _508 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _508; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _508;\n        float param_11 = _418;\n        vec2 _527 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_527 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_527) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_508);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _569 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _574 = clamp(dot(n, l), 0.0, 1.0);\n    float _580 = sqrt(1.0 - (_574 * _574));\n    float _588 = min(_580 / max(_574, 0.20000000298023223876953125), 4.0);\n    float _593;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _593 = fa_shadows[26].y;\n    }\n    else\n    {\n        _593 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _618 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_593 * _580)), 1.0);\n    float _625 = _618.x;\n    bool _628 = _625 < fa_shadows[ci * 1 + 16].x;\n    bool _637;\n    if (!_628)\n    {\n        _637 = _625 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _637 = _628;\n    }\n    bool _646;\n    if (!_637)\n    {\n        _646 = _618.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _646 = _637;\n    }\n    bool _655;\n    if (!_646)\n    {\n        _655 = _618.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _655 = _646;\n    }\n    bool _662;\n    if (!_655)\n    {\n        _662 = _618.z > 1.0;\n    }\n    else\n    {\n        _662 = _655;\n    }\n    if (_662)\n    {\n        return -1.0;\n    }\n    float _671;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _671 = fa_shadows[26].x;\n    }\n    else\n    {\n        _671 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _618.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _618.z - ((_671 * (1.0 + (0.5 * _588))) / _569);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _569;\n    float param_5 = _569 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_588, 3.0)) * 0.5) / _569;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1069 = int(fa_shadows[25].x + 0.5);\n    if (_1069 < 1)\n    {\n        return 1.0;\n    }\n    float _1085 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1069 - 1;\n    if (_1085 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1097 = _1069 > 1;\n    bool _1104;\n    if (_1097)\n    {\n        _1104 = _1085 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1104 = _1097;\n    }\n    if (_1104)\n    {\n        ci = 1;\n    }\n    bool _1108 = _1069 > 2;\n    bool _1115;\n    if (_1108)\n    {\n        _1115 = _1085 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1115 = _1108;\n    }\n    if (_1115)\n    {\n        ci = 2;\n    }\n    bool _1119 = _1069 > 3;\n    bool _1126;\n    if (_1119)\n    {\n        _1126 = _1085 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1126 = _1119;\n    }\n    if (_1126)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1069)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1152 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1152;\n        if (_1152 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1177 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1177 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1196 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1177, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1207 = clamp((_1085 - (fa_shadow_split_at(param_7) - _1196)) / _1196, 0.0, 1.0);\n        if (_1207 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1069)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1228 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1228;\n                if (_1228 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1207);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _733 = fa_mesh_fs_params[5].z < 0.5;\n    bool _741;\n    if (!_733)\n    {\n        _741 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _741 = _733;\n    }\n    if (_741)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _754 = fa_light_texel(param);\n    float _755 = _754.x;\n    if (_755 < 0.0)\n    {\n        return 1.0;\n    }\n    int _764 = int(_755 + 0.5);\n    int param_1 = _764;\n    vec4 _768 = fa_light_texel(param_1);\n    int param_2 = _764 + 1;\n    vec4 _773 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _776 = _768.y;\n    if (_776 > 0.0)\n    {\n        float _794 = 1.0 - smoothstep(0.75 * _776, _776, length(world - fa_shadows[27].xyz));\n        fade = _794;\n        if (_794 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_768.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _813 = world - fa_light_texel(param_3).xyz;\n        vec3 _816 = abs(_813);\n        float _818 = _816.x;\n        float _820 = _816.y;\n        bool _821 = _818 >= _820;\n        bool _829;\n        if (_821)\n        {\n            _829 = _818 >= _816.z;\n        }\n        else\n        {\n            _829 = _821;\n        }\n        int _830;\n        if (_829)\n        {\n            _830 = (_813.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _843;\n            if (_820 >= _816.z)\n            {\n                _843 = (_813.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _843 = (_813.z > 0.0) ? 4 : 5;\n            }\n            _830 = _843;\n        }\n        face = _830;\n    }\n    int _862 = (_764 + 2) + (face * 6);\n    int param_4 = _862;\n    int param_5 = _862 + 1;\n    int param_6 = _862 + 3;\n    vec4 _876 = fa_light_texel(param_6);\n    int param_7 = _862 + 4;\n    vec4 _881 = fa_light_texel(param_7);\n    int param_8 = _862 + 5;\n    vec4 _886 = fa_light_texel(param_8);\n    float _898 = _886.x * max(dot(_876, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _903 = clamp(dot(n, l), 0.0, 1.0);\n    float _909 = sqrt(1.0 - (_903 * _903));\n    float _915 = min(_909 / max(_903, 0.20000000298023223876953125), 4.0);\n    float _918 = _773.y;\n    float _920;\n    if (_918 > 0.0)\n    {\n        _920 = _918;\n    }\n    else\n    {\n        _920 = 1.5 * _898;\n    }\n    vec4 _940 = vec4(world + (n * (_920 * _909)), 1.0);\n    float _944 = dot(_876, _940);\n    float _947 = _886.y;\n    if (_944 < _947)\n    {\n        return 1.0;\n    }\n    vec2 _962 = vec2(dot(fa_light_texel(param_4), _940), dot(fa_light_texel(param_5), _940)) / vec2(_944);\n    float _964 = _962.x;\n    bool _967 = _964 < _881.x;\n    bool _976;\n    if (!_967)\n    {\n        _976 = _964 > _881.z;\n    }\n    else\n    {\n        _976 = _967;\n    }\n    bool _985;\n    if (!_976)\n    {\n        _985 = _962.y < _881.y;\n    }\n    else\n    {\n        _985 = _976;\n    }\n    bool _994;\n    if (!_985)\n    {\n        _994 = _962.y > _881.w;\n    }\n    else\n    {\n        _994 = _985;\n    }\n    if (_994)\n    {\n        return 1.0;\n    }\n    float _1000 = _773.x;\n    float _1002;\n    if (_1000 > 0.0)\n    {\n        _1002 = _1000;\n    }\n    else\n    {\n        _1002 = 1.5 * _898;\n    }\n    vec2 param_9 = _962;\n    vec4 param_10 = _881;\n    float param_11 = _944 - (_1002 * (1.0 + (0.5 * _915)));\n    float param_12 = _898;\n    float param_13 = 1.0;\n    float param_14 = _886.z * 0.25;\n    float param_15 = (_898 * min(_915, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _947, _886.z);\n    int param_17 = int(_768.z + 0.5);\n    float param_18 = _768.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1267 = fa_light_sample(param, param_1);\n    vec3 _1649 = _1267.direction;\n    vec3 _1644 = _1267.color;\n    float _1651 = _1267.attenuation;\n    float _1646 = _1267.shadow;\n    int _1654 = _1267.type;\n    if ((_1654 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _1649;\n        float _1283 = fa_shadow(param_2, param_3, param_4);\n        _1646 = _1283;\n        _1644 *= _1283;\n    }\n    else\n    {\n        bool _1294 = _1654 != 0;\n        bool _1300;\n        if (_1294)\n        {\n            _1300 = _1651 > 0.0;\n        }\n        else\n        {\n            _1300 = _1294;\n        }\n        if (_1300)\n        {\n            int param_5 = li;\n            vec3 param_6 = world_pos;\n            vec3 param_7 = gn;\n            vec3 param_8 = _1649;\n            float _1312 = fa_shadow_local(param_5, param_6, param_7, param_8);\n            _1646 = _1312;\n            _1644 *= _1312;\n        }\n    }\n    return LightSample(_1649, _1644, _1651, _1646, _1267._distance, _1654);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _1325 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1332;\n    if (!_1325)\n    {\n        _1332 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1332 = _1325;\n    }\n    if (_1332)\n    {\n        vec3 _1340 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _1347 = dot(_1340, fa_mesh_fs_params[9].xyz);\n        bool _1351 = fa_mesh_fs_params[9].w > 0.5;\n        float _1352;\n        if (_1351)\n        {\n            _1352 = _1347;\n        }\n        else\n        {\n            _1352 = length(_1340);\n        }\n        float _1364 = _1352 - fa_mesh_fs_params[8].x;\n        if (_1364 > 0.0)\n        {\n            float _1373 = fa_mesh_fs_params[7].w * _1364;\n            float tau = _1373 * _1373;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1389;\n                if (_1351)\n                {\n                    _1389 = world_pos.y - (fa_mesh_fs_params[9].y * _1347);\n                }\n                else\n                {\n                    _1389 = fa_mesh_fs_params[0].y;\n                }\n                float _1410 = mix(_1389, world_pos.y, clamp(fa_mesh_fs_params[8].x / _1352, 0.0, 1.0));\n                float _1414 = world_pos.y - _1410;\n                float _1419 = _1410 - fa_mesh_fs_params[8].z;\n                float _1424 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1427 = _1419 <= 0.0;\n                bool _1428 = !_1427;\n                bool _1434;\n                if (_1428)\n                {\n                    _1434 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1434 = _1427;\n                }\n                float _1435;\n                if (_1434)\n                {\n                    _1435 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1435 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1419, 80.0));\n                }\n                bool _1462;\n                if (_1428)\n                {\n                    _1462 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1462 = _1427;\n                }\n                float _1463;\n                if (_1462)\n                {\n                    _1463 = fa_mesh_fs_params[8].y * _1419;\n                }\n                else\n                {\n                    _1463 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1419, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1488 = _1424 <= 0.0;\n                bool _1495;\n                if (!_1488)\n                {\n                    _1495 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1495 = _1488;\n                }\n                float _1496;\n                if (_1495)\n                {\n                    _1496 = fa_mesh_fs_params[8].y * _1424;\n                }\n                else\n                {\n                    _1496 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1424, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1523;\n                if (abs(_1414) < 0.001000000047497451305389404296875)\n                {\n                    _1523 = _1435;\n                }\n                else\n                {\n                    _1523 = (_1496 - _1463) / _1414;\n                }\n                tau += (_1364 * max(_1523, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _1561 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _1561;\n        vec4 param_3 = v_shadow;\n        LightSample _1593 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _1593.color) * max(dot(_1561, _1593.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _1616 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_1616, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_317",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_730",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1568",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_full_light_tex_fa_full_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_61 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_61 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_61 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _227 = fa_world_position(param);\n    v_pos = _227;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_227, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _135 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _142 = fa_light_texel(param_1);\n    float _147 = _142.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _155 = _147 < 0.5;\n    vec3 l;\n    if (_155)\n    {\n        l = normalize(_135.xyz);\n    }\n    else\n    {\n        vec3 _167 = _135.xyz - world_pos;\n        float _169 = length(_167);\n        dist = _169;\n        l = _167 / vec3(max(_169, 9.9999997473787516355514526367188e-05));\n        float _184 = _169 / max(_135.w, 0.001000000047497451305389404296875);\n        float _190 = clamp(1.0 - (_184 * _184), 0.0, 1.0);\n        atten = _190 * _190;\n        if (_147 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _205 = fa_light_texel(param_2);\n            float _215 = _205.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _222 = fa_light_texel(param_3);\n            float _224 = _222.x;\n            float cos_inner = _224;\n            if (_224 > 1.5)\n            {\n                cos_inner = mix(_215, 1.0, 0.25);\n            }\n            atten *= smoothstep(_215, cos_inner, dot(-l, normalize(_205.xyz)));\n        }\n    }\n    int _255;\n    if (_155)\n    {\n        _255 = 0;\n    }\n    else\n    {\n        _255 = (_147 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _142.xyz * atten, atten, 1.0, dist, _255);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _307;\n    if (i == 0)\n    {\n        _307 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _324;\n        if (i == 1)\n        {\n            _324 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _333;\n            if (i == 2)\n            {\n                _333 = fa_shadows[24].z;\n            }\n            else\n            {\n                _333 = fa_shadows[24].w;\n            }\n            _324 = _333;\n        }\n        _307 = _324;\n    }\n    return _307;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _367 = fa_shadow_depth(param, param_1);\n    float _371;\n    if (conv.x < 0.5)\n    {\n        _371 = _367;\n    }\n    else\n    {\n        _371 = (conv.y * conv.z) / (conv.z - (_367 * (conv.z - conv.y)));\n    }\n    return _371;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _295 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_295), sin(_295)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _418 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _432 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _418;\n            vec2 _452 = fa_shadow_vogel(param_3, param_4, param_5) * _432;\n            vec2 param_6 = uv + (_452 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _464 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_464 < (zr - (length(_452) * plane)))\n            {\n                sum += _464;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _508 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _508; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _508;\n        float param_11 = _418;\n        vec2 _527 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_527 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_527) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_508);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _569 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _574 = clamp(dot(n, l), 0.0, 1.0);\n    float _580 = sqrt(1.0 - (_574 * _574));\n    float _588 = min(_580 / max(_574, 0.20000000298023223876953125), 4.0);\n    float _593;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _593 = fa_shadows[26].y;\n    }\n    else\n    {\n        _593 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _618 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_593 * _580)), 1.0);\n    float _625 = _618.x;\n    bool _628 = _625 < fa_shadows[ci * 1 + 16].x;\n    bool _637;\n    if (!_628)\n    {\n        _637 = _625 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _637 = _628;\n    }\n    bool _646;\n    if (!_637)\n    {\n        _646 = _618.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _646 = _637;\n    }\n    bool _655;\n    if (!_646)\n    {\n        _655 = _618.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _655 = _646;\n    }\n    bool _662;\n    if (!_655)\n    {\n        _662 = _618.z > 1.0;\n    }\n    else\n    {\n        _662 = _655;\n    }\n    if (_662)\n    {\n        return -1.0;\n    }\n    float _671;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _671 = fa_shadows[26].x;\n    }\n    else\n    {\n        _671 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _618.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _618.z - ((_671 * (1.0 + (0.5 * _588))) / _569);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _569;\n    float param_5 = _569 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_588, 3.0)) * 0.5) / _569;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1069 = int(fa_shadows[25].x + 0.5);\n    if (_1069 < 1)\n    {\n        return 1.0;\n    }\n    float _1085 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1069 - 1;\n    if (_1085 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1097 = _1069 > 1;\n    bool _1104;\n    if (_1097)\n    {\n        _1104 = _1085 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1104 = _1097;\n    }\n    if (_1104)\n    {\n        ci = 1;\n    }\n    bool _1108 = _1069 > 2;\n    bool _1115;\n    if (_1108)\n    {\n        _1115 = _1085 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1115 = _1108;\n    }\n    if (_1115)\n    {\n        ci = 2;\n    }\n    bool _1119 = _1069 > 3;\n    bool _1126;\n    if (_1119)\n    {\n        _1126 = _1085 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1126 = _1119;\n    }\n    if (_1126)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1069)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1152 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1152;\n        if (_1152 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1177;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1177 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1177 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1196 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1177, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1207 = clamp((_1085 - (fa_shadow_split_at(param_7) - _1196)) / _1196, 0.0, 1.0);\n        if (_1207 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1069)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1228 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1228;\n                if (_1228 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1207);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _733 = fa_mesh_fs_params[5].z < 0.5;\n    bool _741;\n    if (!_733)\n    {\n        _741 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _741 = _733;\n    }\n    if (_741)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _754 = fa_light_texel(param);\n    float _755 = _754.x;\n    if (_755 < 0.0)\n    {\n        return 1.0;\n    }\n    int _764 = int(_755 + 0.5);\n    int param_1 = _764;\n    vec4 _768 = fa_light_texel(param_1);\n    int param_2 = _764 + 1;\n    vec4 _773 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _776 = _768.y;\n    if (_776 > 0.0)\n    {\n        float _794 = 1.0 - smoothstep(0.75 * _776, _776, length(world - fa_shadows[27].xyz));\n        fade = _794;\n        if (_794 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_768.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _813 = world - fa_light_texel(param_3).xyz;\n        vec3 _816 = abs(_813);\n        float _818 = _816.x;\n        float _820 = _816.y;\n        bool _821 = _818 >= _820;\n        bool _829;\n        if (_821)\n        {\n            _829 = _818 >= _816.z;\n        }\n        else\n        {\n            _829 = _821;\n        }\n        int _830;\n        if (_829)\n        {\n            _830 = (_813.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _843;\n            if (_820 >= _816.z)\n            {\n                _843 = (_813.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _843 = (_813.z > 0.0) ? 4 : 5;\n            }\n            _830 = _843;\n        }\n        face = _830;\n    }\n    int _862 = (_764 + 2) + (face * 6);\n    int param_4 = _862;\n    int param_5 = _862 + 1;\n    int param_6 = _862 + 3;\n    vec4 _876 = fa_light_texel(param_6);\n    int param_7 = _862 + 4;\n    vec4 _881 = fa_light_texel(param_7);\n    int param_8 = _862 + 5;\n    vec4 _886 = fa_light_texel(param_8);\n    float _898 = _886.x * max(dot(_876, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _903 = clamp(dot(n, l), 0.0, 1.0);\n    float _909 = sqrt(1.0 - (_903 * _903));\n    float _915 = min(_909 / max(_903, 0.20000000298023223876953125), 4.0);\n    float _918 = _773.y;\n    float _920;\n    if (_918 > 0.0)\n    {\n        _920 = _918;\n    }\n    else\n    {\n        _920 = 1.5 * _898;\n    }\n    vec4 _940 = vec4(world + (n * (_920 * _909)), 1.0);\n    float _944 = dot(_876, _940);\n    float _947 = _886.y;\n    if (_944 < _947)\n    {\n        return 1.0;\n    }\n    vec2 _962 = vec2(dot(fa_light_texel(param_4), _940), dot(fa_light_texel(param_5), _940)) / vec2(_944);\n    float _964 = _962.x;\n    bool _967 = _964 < _881.x;\n    bool _976;\n    if (!_967)\n    {\n        _976 = _964 > _881.z;\n    }\n    else\n    {\n        _976 = _967;\n    }\n    bool _985;\n    if (!_976)\n    {\n        _985 = _962.y < _881.y;\n    }\n    else\n    {\n        _985 = _976;\n    }\n    bool _994;\n    if (!_985)\n    {\n        _994 = _962.y > _881.w;\n    }\n    else\n    {\n        _994 = _985;\n    }\n    if (_994)\n    {\n        return 1.0;\n    }\n    float _1000 = _773.x;\n    float _1002;\n    if (_1000 > 0.0)\n    {\n        _1002 = _1000;\n    }\n    else\n    {\n        _1002 = 1.5 * _898;\n    }\n    vec2 param_9 = _962;\n    vec4 param_10 = _881;\n    float param_11 = _944 - (_1002 * (1.0 + (0.5 * _915)));\n    float param_12 = _898;\n    float param_13 = 1.0;\n    float param_14 = _886.z * 0.25;\n    float param_15 = (_898 * min(_915, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _947, _886.z);\n    int param_17 = int(_768.z + 0.5);\n    float param_18 = _768.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1267 = fa_light_sample(param, param_1);\n    vec3 _1649 = _1267.direction;\n    vec3 _1644 = _1267.color;\n    float _1651 = _1267.attenuation;\n    float _1646 = _1267.shadow;\n    int _1654 = _1267.type;\n    if ((_1654 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _1649;\n        float _1283 = fa_shadow(param_2, param_3, param_4);\n        _1646 = _1283;\n        _1644 *= _1283;\n    }\n    else\n    {\n        bool _1294 = _1654 != 0;\n        bool _1300;\n        if (_1294)\n        {\n            _1300 = _1651 > 0.0;\n        }\n        else\n        {\n            _1300 = _1294;\n        }\n        if (_1300)\n        {\n            int param_5 = li;\n            vec3 param_6 = world_pos;\n            vec3 param_7 = gn;\n            vec3 param_8 = _1649;\n            float _1312 = fa_shadow_local(param_5, param_6, param_7, param_8);\n            _1646 = _1312;\n            _1644 *= _1312;\n        }\n    }\n    return LightSample(_1649, _1644, _1651, _1646, _1267._distance, _1654);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _1325 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1332;\n    if (!_1325)\n    {\n        _1332 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1332 = _1325;\n    }\n    if (_1332)\n    {\n        vec3 _1340 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _1347 = dot(_1340, fa_mesh_fs_params[9].xyz);\n        bool _1351 = fa_mesh_fs_params[9].w > 0.5;\n        float _1352;\n        if (_1351)\n        {\n            _1352 = _1347;\n        }\n        else\n        {\n            _1352 = length(_1340);\n        }\n        float _1364 = _1352 - fa_mesh_fs_params[8].x;\n        if (_1364 > 0.0)\n        {\n            float _1373 = fa_mesh_fs_params[7].w * _1364;\n            float tau = _1373 * _1373;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1389;\n                if (_1351)\n                {\n                    _1389 = world_pos.y - (fa_mesh_fs_params[9].y * _1347);\n                }\n                else\n                {\n                    _1389 = fa_mesh_fs_params[0].y;\n                }\n                float _1410 = mix(_1389, world_pos.y, clamp(fa_mesh_fs_params[8].x / _1352, 0.0, 1.0));\n                float _1414 = world_pos.y - _1410;\n                float _1419 = _1410 - fa_mesh_fs_params[8].z;\n                float _1424 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1427 = _1419 <= 0.0;\n                bool _1428 = !_1427;\n                bool _1434;\n                if (_1428)\n                {\n                    _1434 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1434 = _1427;\n                }\n                float _1435;\n                if (_1434)\n                {\n                    _1435 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1435 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1419, 80.0));\n                }\n                bool _1462;\n                if (_1428)\n                {\n                    _1462 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1462 = _1427;\n                }\n                float _1463;\n                if (_1462)\n                {\n                    _1463 = fa_mesh_fs_params[8].y * _1419;\n                }\n                else\n                {\n                    _1463 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1419, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1488 = _1424 <= 0.0;\n                bool _1495;\n                if (!_1488)\n                {\n                    _1495 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1495 = _1488;\n                }\n                float _1496;\n                if (_1495)\n                {\n                    _1496 = fa_mesh_fs_params[8].y * _1424;\n                }\n                else\n                {\n                    _1496 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1424, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1523;\n                if (abs(_1414) < 0.001000000047497451305389404296875)\n                {\n                    _1523 = _1435;\n                }\n                else\n                {\n                    _1523 = (_1496 - _1463) / _1414;\n                }\n                tau += (_1364 * max(_1523, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _1561 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _1561;\n        vec4 param_3 = v_shadow;\n        LightSample _1593 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _1593.color) * max(dot(_1561, _1593.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _1616 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_1616, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_247",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_317",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_730",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1568",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_full_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_light_tex_fa_full_shadow_smp",
            "view_name": "fa_full_light_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_full_light_tex_fa_full_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    }
  }
}
