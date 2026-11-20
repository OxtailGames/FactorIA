{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "988cfc1c160a2406bf9dc799340ab0aac9eeed94208cd8193e37bfb0d2577a5b",
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
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_light_atlas_fa_env_smp;\nlayout(binding = 2) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_full_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_full_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _191 = dot(d, right);\n    float _195 = dot(d, up);\n    float _206;\n    if (((_191 * _191) + (_195 * _195)) > 1.0000000133514319600180897396058e-10)\n    {\n        _206 = atan(_195, _191) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _206 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_206 - floor(_206)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _240 = fa_light_base(param);\n    bool _245 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _240;\n    vec4 _249 = fa_light_texel(param_1);\n    int param_2 = _240 + 1;\n    vec4 _255 = fa_light_texel(param_2);\n    float _259 = _255.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _271 = _245 && (_259 > 2.5);\n    fa_light_is_area = _271;\n    bool _274 = _259 < 0.5;\n    vec3 l;\n    if (_274)\n    {\n        l = normalize(_249.xyz);\n        if (_245)\n        {\n            int param_3 = _240 + 6;\n            vec4 _289 = fa_light_texel(param_3);\n            if (_289.z > 0.5)\n            {\n                int param_4 = _240 + 4;\n                vec4 _300 = fa_light_texel(param_4);\n                int param_5 = _240 + 5;\n                vec4 _306 = fa_light_texel(param_5);\n                vec2 param_6 = _289.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _300.xyz) * _300.w, (-dot(world_pos, _306.xyz)) * _306.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _338 = _249.xyz - world_pos;\n        float _340 = length(_338);\n        dist = _340;\n        l = _338 / vec3(max(_340, 9.9999997473787516355514526367188e-05));\n        float reach = _340;\n        if (_271)\n        {\n            int param_8 = _240 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _372 = reach / max(_249.w, 0.001000000047497451305389404296875);\n        float _378 = clamp(1.0 - (_372 * _372), 0.0, 1.0);\n        atten = _378 * _378;\n        bool _386 = _259 < 2.5;\n        if ((_259 > 1.5) && _386)\n        {\n            int param_9 = _240 + 2;\n            vec4 _395 = fa_light_texel(param_9);\n            float _405 = _395.w;\n            int param_10 = _240 + 3;\n            vec4 _411 = fa_light_texel(param_10);\n            float _412 = _411.x;\n            float cos_inner = _412;\n            if (_412 > 1.5)\n            {\n                cos_inner = mix(_405, 1.0, 0.25);\n            }\n            atten *= smoothstep(_405, cos_inner, dot(-l, normalize(_395.xyz)));\n        }\n        if (_245 && _386)\n        {\n            int param_11 = _240 + 6;\n            vec4 _436 = fa_light_texel(param_11);\n            int param_12 = _240 + 7;\n            vec4 _441 = fa_light_texel(param_12);\n            bool _444 = _436.z > 0.5;\n            bool _451;\n            if (!_444)\n            {\n                _451 = _441.z > 0.5;\n            }\n            else\n            {\n                _451 = _444;\n            }\n            if (_451)\n            {\n                int param_13 = _240 + 2;\n                vec4 _458 = fa_light_texel(param_13);\n                vec3 _462 = normalize(_458.xyz);\n                int param_14 = _240 + 4;\n                vec4 _467 = fa_light_texel(param_14);\n                int param_15 = _240 + 5;\n                vec4 _472 = fa_light_texel(param_15);\n                if (_444)\n                {\n                    vec3 _480 = -_338;\n                    float _487 = _458.w;\n                    float _503 = 0.5 / max(dot(_480, _462) * (sqrt(max(1.0 - (_487 * _487), 0.0)) / max(_487, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _436.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_480, _467.xyz) * _503), 0.5 - (dot(_480, _472.xyz) * _503));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_441.z > 0.5)\n                {\n                    vec2 param_18 = _441.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _462;\n                    vec3 param_21 = _467.xyz;\n                    vec3 param_22 = _472.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _1529 = _255.xyz * atten;\n    if (_245)\n    {\n        _1529 *= fa_light_tint;\n    }\n    int _572;\n    if (_274)\n    {\n        _572 = 0;\n    }\n    else\n    {\n        _572 = ((_259 > 1.5) && (_259 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _1529, atten, 1.0, dist, _572);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _627;\n    if (i == 0)\n    {\n        _627 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _643;\n        if (i == 1)\n        {\n            _643 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _651;\n            if (i == 2)\n            {\n                _651 = fa_shadows[24].z;\n            }\n            else\n            {\n                _651 = fa_shadows[24].w;\n            }\n            _643 = _651;\n        }\n        _627 = _643;\n    }\n    return _627;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _615 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_615), sin(_615)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _690 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _695 = clamp(dot(n, l), 0.0, 1.0);\n    float _701 = sqrt(1.0 - (_695 * _695));\n    float _709 = min(_701 / max(_695, 0.20000000298023223876953125), 4.0);\n    float _714;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _714 = fa_shadows[26].y;\n    }\n    else\n    {\n        _714 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _739 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_714 * _701)), 1.0);\n    float _746 = _739.x;\n    bool _749 = _746 < fa_shadows[ci * 1 + 16].x;\n    bool _758;\n    if (!_749)\n    {\n        _758 = _746 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _758 = _749;\n    }\n    bool _767;\n    if (!_758)\n    {\n        _767 = _739.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _767 = _758;\n    }\n    bool _776;\n    if (!_767)\n    {\n        _776 = _739.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _776 = _767;\n    }\n    bool _783;\n    if (!_776)\n    {\n        _783 = _739.z > 1.0;\n    }\n    else\n    {\n        _783 = _776;\n    }\n    if (_783)\n    {\n        return -1.0;\n    }\n    float _791;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _791 = fa_shadows[26].x;\n    }\n    else\n    {\n        _791 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _810 = _739.z - ((_791 * (1.0 + (0.5 * _709))) / _690);\n    float _819 = ((fa_shadows[ci * 1 + 20].x * min(_709, 3.0)) * 0.5) / _690;\n    int _828 = int(fa_shadows[25].z + 0.5);\n    if (_828 == 1)\n    {\n        vec2 param = _739.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _839 = fa_shadow_depth(param, param_1);\n        return float(_810 <= _839);\n    }\n    float _846 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _849 = _828 == 2;\n    if (_849)\n    {\n        float _863 = clamp(((fa_shadows[25].w * _690) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _846;\n            vec2 _883 = fa_shadow_vogel(param_2, param_3, param_4) * _863;\n            vec2 param_5 = _739.xy + (_883 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _894 = fa_shadow_depth(param_5, param_6);\n            if (_894 < (_810 - (length(_883) * _819)))\n            {\n                sum += _894;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_810 - (sum / cnt), 0.0) * _690) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _938 = _849 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _938; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _938;\n        float param_9 = _846;\n        vec2 _957 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _739.xy + (_957 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _968 = fa_shadow_depth(param_10, param_11);\n        lit += float((_810 - (length(_957) * _819)) <= _968);\n    }\n    return lit / float(_938);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _998 = int(fa_shadows[25].x + 0.5);\n    if (_998 < 1)\n    {\n        return 1.0;\n    }\n    float _1013 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _998 - 1;\n    if (_1013 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1025 = _998 > 1;\n    bool _1032;\n    if (_1025)\n    {\n        _1032 = _1013 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1032 = _1025;\n    }\n    if (_1032)\n    {\n        ci = 1;\n    }\n    bool _1036 = _998 > 2;\n    bool _1043;\n    if (_1036)\n    {\n        _1043 = _1013 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        ci = 2;\n    }\n    bool _1047 = _998 > 3;\n    bool _1054;\n    if (_1047)\n    {\n        _1054 = _1013 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1054 = _1047;\n    }\n    if (_1054)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _998)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1080 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1080;\n        if (_1080 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1105;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1105 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1105 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1124 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1105, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1135 = clamp((_1013 - (fa_shadow_split_at(param_7) - _1124)) / _1124, 0.0, 1.0);\n        if (_1135 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _998)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1156 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1156;\n                if (_1156 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1135);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1195 = fa_light_sample(param, param_1);\n    vec3 _1542 = _1195.color;\n    float _1544 = _1195.shadow;\n    if ((_1195.type == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _1195.direction;\n        float _1211 = fa_shadow(param_2, param_3, param_4);\n        _1544 = _1211;\n        _1542 *= _1211;\n    }\n    return LightSample(_1195.direction, _1542, _1195.attenuation, _1544, _1195._distance, _1195.type);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _1224 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1231;\n    if (!_1224)\n    {\n        _1231 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1231 = _1224;\n    }\n    if (_1231)\n    {\n        vec3 _1239 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _1246 = dot(_1239, fa_mesh_fs_params[9].xyz);\n        bool _1250 = fa_mesh_fs_params[9].w > 0.5;\n        float _1251;\n        if (_1250)\n        {\n            _1251 = _1246;\n        }\n        else\n        {\n            _1251 = length(_1239);\n        }\n        float _1263 = _1251 - fa_mesh_fs_params[8].x;\n        if (_1263 > 0.0)\n        {\n            float _1272 = fa_mesh_fs_params[7].w * _1263;\n            float tau = _1272 * _1272;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1288;\n                if (_1250)\n                {\n                    _1288 = world_pos.y - (fa_mesh_fs_params[9].y * _1246);\n                }\n                else\n                {\n                    _1288 = fa_mesh_fs_params[0].y;\n                }\n                float _1309 = mix(_1288, world_pos.y, clamp(fa_mesh_fs_params[8].x / _1251, 0.0, 1.0));\n                float _1313 = world_pos.y - _1309;\n                float _1318 = _1309 - fa_mesh_fs_params[8].z;\n                float _1323 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1326 = _1318 <= 0.0;\n                bool _1327 = !_1326;\n                bool _1333;\n                if (_1327)\n                {\n                    _1333 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1333 = _1326;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1334 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1318, 80.0));\n                }\n                bool _1361;\n                if (_1327)\n                {\n                    _1361 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1361 = _1326;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = fa_mesh_fs_params[8].y * _1318;\n                }\n                else\n                {\n                    _1362 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1318, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1387 = _1323 <= 0.0;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                float _1395;\n                if (_1394)\n                {\n                    _1395 = fa_mesh_fs_params[8].y * _1323;\n                }\n                else\n                {\n                    _1395 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1323, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1422;\n                if (abs(_1313) < 0.001000000047497451305389404296875)\n                {\n                    _1422 = _1334;\n                }\n                else\n                {\n                    _1422 = (_1395 - _1362) / _1313;\n                }\n                tau += (_1263 * max(_1422, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _1460 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _1460;\n        vec4 param_3 = v_shadow;\n        LightSample _1492 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _1492.color) * max(dot(_1460, _1492.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _1515 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_1515, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_106",
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
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_637",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1467",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_full_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
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
            "name": "fa_full_light_atlas_fa_env_smp",
            "view_name": "fa_full_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_full_light_atlas_fa_env_smp"
          },
          {
            "slot": 2,
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
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_light_atlas_fa_env_smp;\nlayout(binding = 2) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[10].y > 4.5) ? 8 : 4);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_full_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_full_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _191 = dot(d, right);\n    float _195 = dot(d, up);\n    float _206;\n    if (((_191 * _191) + (_195 * _195)) > 1.0000000133514319600180897396058e-10)\n    {\n        _206 = atan(_195, _191) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _206 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_206 - floor(_206)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li;\n    int _240 = fa_light_base(param);\n    bool _245 = fa_mesh_fs_params[10].y > 4.5;\n    int param_1 = _240;\n    vec4 _249 = fa_light_texel(param_1);\n    int param_2 = _240 + 1;\n    vec4 _255 = fa_light_texel(param_2);\n    float _259 = _255.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _271 = _245 && (_259 > 2.5);\n    fa_light_is_area = _271;\n    bool _274 = _259 < 0.5;\n    vec3 l;\n    if (_274)\n    {\n        l = normalize(_249.xyz);\n        if (_245)\n        {\n            int param_3 = _240 + 6;\n            vec4 _289 = fa_light_texel(param_3);\n            if (_289.z > 0.5)\n            {\n                int param_4 = _240 + 4;\n                vec4 _300 = fa_light_texel(param_4);\n                int param_5 = _240 + 5;\n                vec4 _306 = fa_light_texel(param_5);\n                vec2 param_6 = _289.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _300.xyz) * _300.w, (-dot(world_pos, _306.xyz)) * _306.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _338 = _249.xyz - world_pos;\n        float _340 = length(_338);\n        dist = _340;\n        l = _338 / vec3(max(_340, 9.9999997473787516355514526367188e-05));\n        float reach = _340;\n        if (_271)\n        {\n            int param_8 = _240 + 7;\n            reach = max(dist - fa_light_texel(param_8).w, 0.0);\n        }\n        float _372 = reach / max(_249.w, 0.001000000047497451305389404296875);\n        float _378 = clamp(1.0 - (_372 * _372), 0.0, 1.0);\n        atten = _378 * _378;\n        bool _386 = _259 < 2.5;\n        if ((_259 > 1.5) && _386)\n        {\n            int param_9 = _240 + 2;\n            vec4 _395 = fa_light_texel(param_9);\n            float _405 = _395.w;\n            int param_10 = _240 + 3;\n            vec4 _411 = fa_light_texel(param_10);\n            float _412 = _411.x;\n            float cos_inner = _412;\n            if (_412 > 1.5)\n            {\n                cos_inner = mix(_405, 1.0, 0.25);\n            }\n            atten *= smoothstep(_405, cos_inner, dot(-l, normalize(_395.xyz)));\n        }\n        if (_245 && _386)\n        {\n            int param_11 = _240 + 6;\n            vec4 _436 = fa_light_texel(param_11);\n            int param_12 = _240 + 7;\n            vec4 _441 = fa_light_texel(param_12);\n            bool _444 = _436.z > 0.5;\n            bool _451;\n            if (!_444)\n            {\n                _451 = _441.z > 0.5;\n            }\n            else\n            {\n                _451 = _444;\n            }\n            if (_451)\n            {\n                int param_13 = _240 + 2;\n                vec4 _458 = fa_light_texel(param_13);\n                vec3 _462 = normalize(_458.xyz);\n                int param_14 = _240 + 4;\n                vec4 _467 = fa_light_texel(param_14);\n                int param_15 = _240 + 5;\n                vec4 _472 = fa_light_texel(param_15);\n                if (_444)\n                {\n                    vec3 _480 = -_338;\n                    float _487 = _458.w;\n                    float _503 = 0.5 / max(dot(_480, _462) * (sqrt(max(1.0 - (_487 * _487), 0.0)) / max(_487, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                    vec2 param_16 = _436.xy;\n                    vec2 param_17 = vec2(0.5 + (dot(_480, _467.xyz) * _503), 0.5 - (dot(_480, _472.xyz) * _503));\n                    fa_light_tint = fa_cookie_sample(param_16, param_17);\n                }\n                if (_441.z > 0.5)\n                {\n                    vec2 param_18 = _441.xy;\n                    vec3 param_19 = -l;\n                    vec3 param_20 = _462;\n                    vec3 param_21 = _467.xyz;\n                    vec3 param_22 = _472.xyz;\n                    atten *= fa_ies_sample(param_18, param_19, param_20, param_21, param_22);\n                }\n            }\n        }\n    }\n    vec3 _1529 = _255.xyz * atten;\n    if (_245)\n    {\n        _1529 *= fa_light_tint;\n    }\n    int _572;\n    if (_274)\n    {\n        _572 = 0;\n    }\n    else\n    {\n        _572 = ((_259 > 1.5) && (_259 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _1529, atten, 1.0, dist, _572);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _627;\n    if (i == 0)\n    {\n        _627 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _643;\n        if (i == 1)\n        {\n            _643 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _651;\n            if (i == 2)\n            {\n                _651 = fa_shadows[24].z;\n            }\n            else\n            {\n                _651 = fa_shadows[24].w;\n            }\n            _643 = _651;\n        }\n        _627 = _643;\n    }\n    return _627;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _615 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_615), sin(_615)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _690 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _695 = clamp(dot(n, l), 0.0, 1.0);\n    float _701 = sqrt(1.0 - (_695 * _695));\n    float _709 = min(_701 / max(_695, 0.20000000298023223876953125), 4.0);\n    float _714;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _714 = fa_shadows[26].y;\n    }\n    else\n    {\n        _714 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _739 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_714 * _701)), 1.0);\n    float _746 = _739.x;\n    bool _749 = _746 < fa_shadows[ci * 1 + 16].x;\n    bool _758;\n    if (!_749)\n    {\n        _758 = _746 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _758 = _749;\n    }\n    bool _767;\n    if (!_758)\n    {\n        _767 = _739.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _767 = _758;\n    }\n    bool _776;\n    if (!_767)\n    {\n        _776 = _739.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _776 = _767;\n    }\n    bool _783;\n    if (!_776)\n    {\n        _783 = _739.z > 1.0;\n    }\n    else\n    {\n        _783 = _776;\n    }\n    if (_783)\n    {\n        return -1.0;\n    }\n    float _791;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _791 = fa_shadows[26].x;\n    }\n    else\n    {\n        _791 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _810 = _739.z - ((_791 * (1.0 + (0.5 * _709))) / _690);\n    float _819 = ((fa_shadows[ci * 1 + 20].x * min(_709, 3.0)) * 0.5) / _690;\n    int _828 = int(fa_shadows[25].z + 0.5);\n    if (_828 == 1)\n    {\n        vec2 param = _739.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _839 = fa_shadow_depth(param, param_1);\n        return float(_810 <= _839);\n    }\n    float _846 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _849 = _828 == 2;\n    if (_849)\n    {\n        float _863 = clamp(((fa_shadows[25].w * _690) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _846;\n            vec2 _883 = fa_shadow_vogel(param_2, param_3, param_4) * _863;\n            vec2 param_5 = _739.xy + (_883 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _894 = fa_shadow_depth(param_5, param_6);\n            if (_894 < (_810 - (length(_883) * _819)))\n            {\n                sum += _894;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_810 - (sum / cnt), 0.0) * _690) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _938 = _849 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _938; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _938;\n        float param_9 = _846;\n        vec2 _957 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _739.xy + (_957 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _968 = fa_shadow_depth(param_10, param_11);\n        lit += float((_810 - (length(_957) * _819)) <= _968);\n    }\n    return lit / float(_938);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _998 = int(fa_shadows[25].x + 0.5);\n    if (_998 < 1)\n    {\n        return 1.0;\n    }\n    float _1013 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _998 - 1;\n    if (_1013 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1025 = _998 > 1;\n    bool _1032;\n    if (_1025)\n    {\n        _1032 = _1013 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1032 = _1025;\n    }\n    if (_1032)\n    {\n        ci = 1;\n    }\n    bool _1036 = _998 > 2;\n    bool _1043;\n    if (_1036)\n    {\n        _1043 = _1013 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1043 = _1036;\n    }\n    if (_1043)\n    {\n        ci = 2;\n    }\n    bool _1047 = _998 > 3;\n    bool _1054;\n    if (_1047)\n    {\n        _1054 = _1013 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1054 = _1047;\n    }\n    if (_1054)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _998)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1080 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1080;\n        if (_1080 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1105;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1105 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1105 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1124 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1105, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1135 = clamp((_1013 - (fa_shadow_split_at(param_7) - _1124)) / _1124, 0.0, 1.0);\n        if (_1135 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _998)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1156 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1156;\n                if (_1156 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1135);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1195 = fa_light_sample(param, param_1);\n    vec3 _1542 = _1195.color;\n    float _1544 = _1195.shadow;\n    if ((_1195.type == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _1195.direction;\n        float _1211 = fa_shadow(param_2, param_3, param_4);\n        _1544 = _1211;\n        _1542 *= _1211;\n    }\n    return LightSample(_1195.direction, _1542, _1195.attenuation, _1544, _1195._distance, _1195.type);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _1224 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1231;\n    if (!_1224)\n    {\n        _1231 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1231 = _1224;\n    }\n    if (_1231)\n    {\n        vec3 _1239 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _1246 = dot(_1239, fa_mesh_fs_params[9].xyz);\n        bool _1250 = fa_mesh_fs_params[9].w > 0.5;\n        float _1251;\n        if (_1250)\n        {\n            _1251 = _1246;\n        }\n        else\n        {\n            _1251 = length(_1239);\n        }\n        float _1263 = _1251 - fa_mesh_fs_params[8].x;\n        if (_1263 > 0.0)\n        {\n            float _1272 = fa_mesh_fs_params[7].w * _1263;\n            float tau = _1272 * _1272;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1288;\n                if (_1250)\n                {\n                    _1288 = world_pos.y - (fa_mesh_fs_params[9].y * _1246);\n                }\n                else\n                {\n                    _1288 = fa_mesh_fs_params[0].y;\n                }\n                float _1309 = mix(_1288, world_pos.y, clamp(fa_mesh_fs_params[8].x / _1251, 0.0, 1.0));\n                float _1313 = world_pos.y - _1309;\n                float _1318 = _1309 - fa_mesh_fs_params[8].z;\n                float _1323 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1326 = _1318 <= 0.0;\n                bool _1327 = !_1326;\n                bool _1333;\n                if (_1327)\n                {\n                    _1333 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1333 = _1326;\n                }\n                float _1334;\n                if (_1333)\n                {\n                    _1334 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1334 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1318, 80.0));\n                }\n                bool _1361;\n                if (_1327)\n                {\n                    _1361 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1361 = _1326;\n                }\n                float _1362;\n                if (_1361)\n                {\n                    _1362 = fa_mesh_fs_params[8].y * _1318;\n                }\n                else\n                {\n                    _1362 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1318, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1387 = _1323 <= 0.0;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                float _1395;\n                if (_1394)\n                {\n                    _1395 = fa_mesh_fs_params[8].y * _1323;\n                }\n                else\n                {\n                    _1395 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1323, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1422;\n                if (abs(_1313) < 0.001000000047497451305389404296875)\n                {\n                    _1422 = _1334;\n                }\n                else\n                {\n                    _1422 = (_1395 - _1362) / _1313;\n                }\n                tau += (_1263 * max(_1422, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _1460 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _1460;\n        vec4 param_3 = v_shadow;\n        LightSample _1492 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _1492.color) * max(dot(_1460, _1492.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _1515 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_1515, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "slot": 1,
            "stage": "fragment",
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_106",
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
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_637",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1467",
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
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_full_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
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
            "name": "fa_full_light_atlas_fa_env_smp",
            "view_name": "fa_full_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_full_light_atlas_fa_env_smp"
          },
          {
            "slot": 2,
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
