{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "142eb0b65529d068a92ca38457d0560f5a5e559241bda385ede47eaf9b1c4238",
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
      "vs": "#version 430\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _109 = fa_world_position(param);\n    v_pos = _109;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _109;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_109, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_light_atlas_fa_env_smp;\nlayout(binding = 2) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_full_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_full_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _373 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _386 = (c - (ru * hx)) - p;\n        vec3 _392 = ru * (2.0 * hx);\n        float _398 = max(dot(_392, _392), 9.9999999392252902907785028219223e-09);\n        float _402 = dot(_386, _392);\n        float t = clamp((-_402) / _398, 0.0, 1.0);\n        if (_373)\n        {\n            float _417 = dot(r, _392);\n            float _423 = _398 - (_417 * _417);\n            if (abs(_423) > (9.9999997473787516355514526367188e-06 * _398))\n            {\n                t = clamp(((dot(r, _386) * _417) - _402) / _423, 0.0, 1.0);\n            }\n        }\n        return (p + _386) + (_392 * t);\n    }\n    vec3 q = p;\n    float _455 = dot(r, axis);\n    bool _463;\n    if (_373)\n    {\n        _463 = abs(_455) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _463 = _373;\n    }\n    if (_463)\n    {\n        float _473 = dot(c - p, axis) / _455;\n        if (_473 > 0.0)\n        {\n            q = p + (r * _473);\n        }\n    }\n    vec3 _486 = q - c;\n    vec2 xy = vec2(dot(_486, ru), dot(_486, uu));\n    if (shape > 0.5)\n    {\n        float _501 = length(xy);\n        if (_501 > hx)\n        {\n            xy *= (hx / _501);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _288 = abs(d);\n    float _290 = _288.x;\n    float _293 = _288.y;\n    bool _294 = _290 >= _293;\n    bool _303;\n    if (_294)\n    {\n        _303 = _290 >= _288.z;\n    }\n    else\n    {\n        _303 = _294;\n    }\n    int _304;\n    if (_303)\n    {\n        _304 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _317;\n        if (_293 >= _288.z)\n        {\n            _317 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _317 = (d.z > 0.0) ? 4 : 5;\n        }\n        _304 = _317;\n    }\n    return _304;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _240 = dot(d, right);\n    float _244 = dot(d, up);\n    float _255;\n    if (((_240 * _240) + (_244 * _244)) > 1.0000000133514319600180897396058e-10)\n    {\n        _255 = atan(_244, _240) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _255 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_255 - floor(_255)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _539 = fa_light_base(param);\n    bool _543 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _539;\n    vec4 _547 = fa_light_texel(param_1);\n    int param_2 = _539 + 1;\n    vec4 _552 = fa_light_texel(param_2);\n    float _555 = _552.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _567 = _543 && (_555 > 2.5);\n    fa_light_is_area = _567;\n    bool _569 = _555 < 0.5;\n    vec3 l;\n    if (_569)\n    {\n        l = normalize(_547.xyz);\n        if (_543)\n        {\n            int param_3 = _539 + 6;\n            vec4 _584 = fa_light_texel(param_3);\n            if (_584.z > 0.5)\n            {\n                int param_4 = _539 + 4;\n                vec4 _594 = fa_light_texel(param_4);\n                int param_5 = _539 + 5;\n                vec4 _599 = fa_light_texel(param_5);\n                vec2 param_6 = _584.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _594.xyz) * _594.w, (-dot(world_pos, _599.xyz)) * _599.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _629 = _547.xyz;\n        vec3 _631 = _629 - world_pos;\n        vec3 to_light = _631;\n        float _634 = length(_631);\n        float reach = _634;\n        bool front = true;\n        if (_567)\n        {\n            int param_8 = _539 + 7;\n            reach = max(_634 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _539 + 4;\n            vec4 _658 = fa_light_texel(param_9);\n            int param_10 = _539 + 5;\n            vec4 _663 = fa_light_texel(param_10);\n            int param_11 = _539 + 6;\n            vec4 _668 = fa_light_texel(param_11);\n            float _669 = _668.w;\n            int param_12 = _539 + 2;\n            vec3 _676 = normalize(fa_light_texel(param_12).xyz);\n            bool _678 = _669 > 1.5;\n            bool _686;\n            if (!_678)\n            {\n                _686 = dot(_676, to_light) < 0.0;\n            }\n            else\n            {\n                _686 = _678;\n            }\n            front = _686;\n            vec3 r = vec3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-normalize(fa_mesh_fs_params[0].xyz - world_pos), normalize(n));\n            }\n            vec3 param_13 = _629;\n            vec3 param_14 = _676;\n            vec3 param_15 = _658.xyz;\n            vec3 param_16 = _663.xyz;\n            float param_17 = _658.w;\n            float param_18 = _663.w;\n            float param_19 = _669;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _733 = length(to_light);\n        dist = _733;\n        l = to_light / vec3(max(_733, 9.9999997473787516355514526367188e-05));\n        float _747 = reach / max(_547.w, 0.001000000047497451305389404296875);\n        float _753 = clamp(1.0 - (_747 * _747), 0.0, 1.0);\n        float _755;\n        if (front)\n        {\n            _755 = _753 * _753;\n        }\n        else\n        {\n            _755 = 0.0;\n        }\n        atten = _755;\n        bool _766 = _555 < 2.5;\n        if ((_555 > 1.5) && _766)\n        {\n            int param_22 = _539 + 2;\n            vec4 _774 = fa_light_texel(param_22);\n            float _784 = _774.w;\n            int param_23 = _539 + 3;\n            vec4 _789 = fa_light_texel(param_23);\n            float _790 = _789.x;\n            float cos_inner = _790;\n            if (_790 > 1.5)\n            {\n                cos_inner = mix(_784, 1.0, 0.25);\n            }\n            atten *= smoothstep(_784, cos_inner, dot(-l, normalize(_774.xyz)));\n        }\n        if (_543 && (_555 < 1.5))\n        {\n            int param_24 = _539 + 6;\n            vec4 _814 = fa_light_texel(param_24);\n            if (_814.z > 0.5)\n            {\n                vec3 _822 = -to_light;\n                int param_25 = _539 + 4;\n                int param_26 = _539 + 5;\n                vec3 _836 = fa_light_texel(param_25).xyz;\n                vec3 _840 = fa_light_texel(param_26).xyz;\n                vec3 _849 = vec3(dot(_822, _836), dot(_822, _840), dot(_822, cross(_836, _840)));\n                vec3 param_27 = _849;\n                int _853 = fa_cube_face(param_27);\n                int param_28 = _853;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _880 = vec2(dot(_849, cross(param_29, param_30)), dot(_849, param_30)) / vec2(max(dot(_849, param_29), 9.9999997473787516355514526367188e-05));\n                int _884 = _853 / 3;\n                vec2 param_31 = _814.xy + (vec2(float(_853 - (_884 * 3)), float(_884)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _880.x), 0.5 - (0.5 * _880.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _539 + 7;\n            vec4 _914 = fa_light_texel(param_33);\n            if (_914.z > 0.5)\n            {\n                int param_34 = _539 + 2;\n                int param_35 = _539 + 4;\n                int param_36 = _539 + 5;\n                vec2 param_37 = _914.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_543 && _766)\n            {\n                int param_42 = _539 + 6;\n                vec4 _961 = fa_light_texel(param_42);\n                int param_43 = _539 + 7;\n                vec4 _966 = fa_light_texel(param_43);\n                bool _969 = _961.z > 0.5;\n                bool _976;\n                if (!_969)\n                {\n                    _976 = _966.z > 0.5;\n                }\n                else\n                {\n                    _976 = _969;\n                }\n                if (_976)\n                {\n                    int param_44 = _539 + 2;\n                    vec4 _983 = fa_light_texel(param_44);\n                    vec3 _987 = normalize(_983.xyz);\n                    int param_45 = _539 + 4;\n                    vec4 _992 = fa_light_texel(param_45);\n                    int param_46 = _539 + 5;\n                    vec4 _997 = fa_light_texel(param_46);\n                    if (_969)\n                    {\n                        vec3 _1005 = -to_light;\n                        float _1012 = _983.w;\n                        float _1028 = 0.5 / max(dot(_1005, _987) * (sqrt(max(1.0 - (_1012 * _1012), 0.0)) / max(_1012, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _961.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1005, _992.xyz) * _1028), 0.5 - (dot(_1005, _997.xyz) * _1028));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_966.z > 0.5)\n                    {\n                        vec2 param_49 = _966.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _987;\n                        vec3 param_52 = _992.xyz;\n                        vec3 param_53 = _997.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _2492 = _552.xyz * atten;\n    if (_543)\n    {\n        _2492 *= fa_light_tint;\n    }\n    int _1097;\n    if (_569)\n    {\n        _1097 = 0;\n    }\n    else\n    {\n        _1097 = ((_555 > 1.5) && (_555 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _2492, atten, 1.0, dist, _1097);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1152;\n    if (i == 0)\n    {\n        _1152 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1168;\n        if (i == 1)\n        {\n            _1168 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1176;\n            if (i == 2)\n            {\n                _1176 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1176 = fa_shadows[24].w;\n            }\n            _1168 = _1176;\n        }\n        _1152 = _1168;\n    }\n    return _1152;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1209 = fa_shadow_depth(param, param_1);\n    float _1213;\n    if (conv.x < 0.5)\n    {\n        _1213 = _1209;\n    }\n    else\n    {\n        _1213 = (conv.y * conv.z) / (conv.z - (_1209 * (conv.z - conv.y)));\n    }\n    return _1213;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1140 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1140), sin(_1140)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1259 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1268;\n        if (k < 0.0)\n        {\n            _1268 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _1268 = k;\n        }\n        float _1288 = clamp((_1268 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1259;\n            vec2 _1308 = fa_shadow_vogel(param_3, param_4, param_5) * _1288;\n            vec2 param_6 = uv + (_1308 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1320 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1320 < (zr - (length(_1308) * plane)))\n            {\n                sum += _1320;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _1346 = sum / cnt;\n        float _1356;\n        if (k < 0.0)\n        {\n            _1356 = (-k) / max(_1346, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _1356 = k;\n        }\n        radius = clamp(((max(zr - _1346, 0.0) * unit) * _1356) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1379 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1379; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1379;\n        float param_11 = _1259;\n        vec2 _1398 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1398 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1398) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1379);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1440 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1445 = clamp(dot(n, l), 0.0, 1.0);\n    float _1451 = sqrt(1.0 - (_1445 * _1445));\n    float _1459 = min(_1451 / max(_1445, 0.20000000298023223876953125), 4.0);\n    float _1464;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1464 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1464 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1489 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1464 * _1451)), 1.0);\n    float _1496 = _1489.x;\n    bool _1499 = _1496 < fa_shadows[ci * 1 + 16].x;\n    bool _1508;\n    if (!_1499)\n    {\n        _1508 = _1496 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1508 = _1499;\n    }\n    bool _1517;\n    if (!_1508)\n    {\n        _1517 = _1489.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1517 = _1508;\n    }\n    bool _1526;\n    if (!_1517)\n    {\n        _1526 = _1489.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1526 = _1517;\n    }\n    bool _1533;\n    if (!_1526)\n    {\n        _1533 = _1489.z > 1.0;\n    }\n    else\n    {\n        _1533 = _1526;\n    }\n    if (_1533)\n    {\n        return -1.0;\n    }\n    float _1541;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1541 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1541 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1489.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1489.z - ((_1541 * (1.0 + (0.5 * _1459))) / _1440);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1440;\n    float param_5 = _1440 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1459, 3.0)) * 0.5) / _1440;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1929 = int(fa_shadows[25].x + 0.5);\n    if (_1929 < 1)\n    {\n        return 1.0;\n    }\n    float _1944 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1929 - 1;\n    if (_1944 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1956 = _1929 > 1;\n    bool _1963;\n    if (_1956)\n    {\n        _1963 = _1944 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1963 = _1956;\n    }\n    if (_1963)\n    {\n        ci = 1;\n    }\n    bool _1967 = _1929 > 2;\n    bool _1974;\n    if (_1967)\n    {\n        _1974 = _1944 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1974 = _1967;\n    }\n    if (_1974)\n    {\n        ci = 2;\n    }\n    bool _1978 = _1929 > 3;\n    bool _1985;\n    if (_1978)\n    {\n        _1985 = _1944 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1985 = _1978;\n    }\n    if (_1985)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1929)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2011 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2011;\n        if (_2011 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2036;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2036 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2036 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2055 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2036, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2066 = clamp((_1944 - (fa_shadow_split_at(param_7) - _2055)) / _2055, 0.0, 1.0);\n        if (_2066 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1929)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2087 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2087;\n                if (_2087 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2066);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1599 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1606;\n    if (!_1599)\n    {\n        _1606 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1606 = _1599;\n    }\n    if (_1606)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1619 = fa_light_texel(param);\n    float _1620 = _1619.x;\n    if (_1620 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1629 = int(_1620 + 0.5);\n    int param_1 = _1629;\n    vec4 _1633 = fa_light_texel(param_1);\n    int param_2 = _1629 + 1;\n    vec4 _1638 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1641 = _1633.y;\n    if (_1641 > 0.0)\n    {\n        float _1658 = 1.0 - smoothstep(0.75 * _1641, _1641, length(world - fa_shadows[27].xyz));\n        fade = _1658;\n        if (_1658 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1633.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _1687 = (_1629 + 2) + (face * 6);\n    int param_6 = _1687;\n    int param_7 = _1687 + 1;\n    int param_8 = _1687 + 3;\n    vec4 _1701 = fa_light_texel(param_8);\n    int param_9 = _1687 + 4;\n    vec4 _1706 = fa_light_texel(param_9);\n    int param_10 = _1687 + 5;\n    vec4 _1711 = fa_light_texel(param_10);\n    float _1723 = _1711.x * max(dot(_1701, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1728 = clamp(dot(n, l), 0.0, 1.0);\n    float _1751 = clamp(dot(n, _1701.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _1775 = min(sqrt(1.0 - (_1751 * _1751)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_1701, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1778 = _1638.y;\n    float _1780;\n    if (_1778 > 0.0)\n    {\n        _1780 = _1778;\n    }\n    else\n    {\n        _1780 = 1.5 * _1723;\n    }\n    vec4 _1800 = vec4(world + (n * (_1780 * sqrt(1.0 - (_1728 * _1728)))), 1.0);\n    float _1804 = dot(_1701, _1800);\n    float _1807 = _1711.y;\n    if (_1804 < _1807)\n    {\n        return 1.0;\n    }\n    vec2 _1822 = vec2(dot(fa_light_texel(param_6), _1800), dot(fa_light_texel(param_7), _1800)) / vec2(_1804);\n    float _1824 = _1822.x;\n    bool _1827 = _1824 < _1706.x;\n    bool _1836;\n    if (!_1827)\n    {\n        _1836 = _1824 > _1706.z;\n    }\n    else\n    {\n        _1836 = _1827;\n    }\n    bool _1845;\n    if (!_1836)\n    {\n        _1845 = _1822.y < _1706.y;\n    }\n    else\n    {\n        _1845 = _1836;\n    }\n    bool _1854;\n    if (!_1845)\n    {\n        _1854 = _1822.y > _1706.w;\n    }\n    else\n    {\n        _1854 = _1845;\n    }\n    if (_1854)\n    {\n        return 1.0;\n    }\n    float _1860 = _1638.x;\n    float _1862;\n    if (_1860 > 0.0)\n    {\n        _1862 = _1860;\n    }\n    else\n    {\n        _1862 = 1.5 * _1723;\n    }\n    vec2 param_13 = _1822;\n    vec4 param_14 = _1706;\n    float param_15 = _1804 - (_1862 * (1.0 + (0.5 * _1775)));\n    float param_16 = _1723;\n    float param_17 = 1.0;\n    float param_18 = _1711.z * 0.25;\n    float param_19 = (_1723 * min(_1775, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _1807, _1711.z);\n    int param_21 = int(_1633.z + 0.5);\n    float param_22 = _1633.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = gn;\n    LightSample _2128 = fa_light_sample_n(param, param_1, param_2);\n    vec3 _2505 = _2128.color;\n    float _2507 = _2128.shadow;\n    if ((_2128.type == 0) && (li == 0))\n    {\n        vec4 param_3 = coord;\n        vec3 param_4 = gn;\n        vec3 param_5 = _2128.direction;\n        float _2144 = fa_shadow(param_3, param_4, param_5);\n        _2507 = _2144;\n        _2505 *= _2144;\n    }\n    else\n    {\n        bool _2155 = _2128.type != 0;\n        bool _2161;\n        if (_2155)\n        {\n            _2161 = _2128.attenuation > 0.0;\n        }\n        else\n        {\n            _2161 = _2155;\n        }\n        if (_2161)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _2128.direction;\n            float _2173 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _2507 = _2173;\n            _2505 *= _2173;\n        }\n    }\n    return LightSample(_2128.direction, _2505, _2128.attenuation, _2507, _2128._distance, _2128.type);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _2186 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2193;\n    if (!_2186)\n    {\n        _2193 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2193 = _2186;\n    }\n    if (_2193)\n    {\n        vec3 _2201 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _2208 = dot(_2201, fa_mesh_fs_params[9].xyz);\n        bool _2212 = fa_mesh_fs_params[9].w > 0.5;\n        float _2213;\n        if (_2212)\n        {\n            _2213 = _2208;\n        }\n        else\n        {\n            _2213 = length(_2201);\n        }\n        float _2225 = _2213 - fa_mesh_fs_params[8].x;\n        if (_2225 > 0.0)\n        {\n            float _2234 = fa_mesh_fs_params[7].w * _2225;\n            float tau = _2234 * _2234;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2250;\n                if (_2212)\n                {\n                    _2250 = world_pos.y - (fa_mesh_fs_params[9].y * _2208);\n                }\n                else\n                {\n                    _2250 = fa_mesh_fs_params[0].y;\n                }\n                float _2271 = mix(_2250, world_pos.y, clamp(fa_mesh_fs_params[8].x / _2213, 0.0, 1.0));\n                float _2275 = world_pos.y - _2271;\n                float _2280 = _2271 - fa_mesh_fs_params[8].z;\n                float _2285 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2288 = _2280 <= 0.0;\n                bool _2289 = !_2288;\n                bool _2295;\n                if (_2289)\n                {\n                    _2295 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2295 = _2288;\n                }\n                float _2296;\n                if (_2295)\n                {\n                    _2296 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2296 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2280, 80.0));\n                }\n                bool _2323;\n                if (_2289)\n                {\n                    _2323 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2323 = _2288;\n                }\n                float _2324;\n                if (_2323)\n                {\n                    _2324 = fa_mesh_fs_params[8].y * _2280;\n                }\n                else\n                {\n                    _2324 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2280, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2349 = _2285 <= 0.0;\n                bool _2356;\n                if (!_2349)\n                {\n                    _2356 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2356 = _2349;\n                }\n                float _2357;\n                if (_2356)\n                {\n                    _2357 = fa_mesh_fs_params[8].y * _2285;\n                }\n                else\n                {\n                    _2357 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2285, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2384;\n                if (abs(_2275) < 0.001000000047497451305389404296875)\n                {\n                    _2384 = _2296;\n                }\n                else\n                {\n                    _2384 = (_2357 - _2324) / _2275;\n                }\n                tau += (_2225 * max(_2384, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _2422 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _2422;\n        vec4 param_3 = v_shadow;\n        LightSample _2454 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _2454.color) * max(dot(_2422, _2454.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _2477 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_2477, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
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
            "inst_name": "_154",
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
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1162",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2429",
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
      "vs": "#version 430\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_61 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_61 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_61 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _227 = fa_world_position(param);\n    v_pos = _227;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_227, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_light_atlas_fa_env_smp;\nlayout(binding = 2) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_full_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_full_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _373 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _386 = (c - (ru * hx)) - p;\n        vec3 _392 = ru * (2.0 * hx);\n        float _398 = max(dot(_392, _392), 9.9999999392252902907785028219223e-09);\n        float _402 = dot(_386, _392);\n        float t = clamp((-_402) / _398, 0.0, 1.0);\n        if (_373)\n        {\n            float _417 = dot(r, _392);\n            float _423 = _398 - (_417 * _417);\n            if (abs(_423) > (9.9999997473787516355514526367188e-06 * _398))\n            {\n                t = clamp(((dot(r, _386) * _417) - _402) / _423, 0.0, 1.0);\n            }\n        }\n        return (p + _386) + (_392 * t);\n    }\n    vec3 q = p;\n    float _455 = dot(r, axis);\n    bool _463;\n    if (_373)\n    {\n        _463 = abs(_455) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _463 = _373;\n    }\n    if (_463)\n    {\n        float _473 = dot(c - p, axis) / _455;\n        if (_473 > 0.0)\n        {\n            q = p + (r * _473);\n        }\n    }\n    vec3 _486 = q - c;\n    vec2 xy = vec2(dot(_486, ru), dot(_486, uu));\n    if (shape > 0.5)\n    {\n        float _501 = length(xy);\n        if (_501 > hx)\n        {\n            xy *= (hx / _501);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _288 = abs(d);\n    float _290 = _288.x;\n    float _293 = _288.y;\n    bool _294 = _290 >= _293;\n    bool _303;\n    if (_294)\n    {\n        _303 = _290 >= _288.z;\n    }\n    else\n    {\n        _303 = _294;\n    }\n    int _304;\n    if (_303)\n    {\n        _304 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _317;\n        if (_293 >= _288.z)\n        {\n            _317 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _317 = (d.z > 0.0) ? 4 : 5;\n        }\n        _304 = _317;\n    }\n    return _304;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _240 = dot(d, right);\n    float _244 = dot(d, up);\n    float _255;\n    if (((_240 * _240) + (_244 * _244)) > 1.0000000133514319600180897396058e-10)\n    {\n        _255 = atan(_244, _240) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _255 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_255 - floor(_255)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _539 = fa_light_base(param);\n    bool _543 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _539;\n    vec4 _547 = fa_light_texel(param_1);\n    int param_2 = _539 + 1;\n    vec4 _552 = fa_light_texel(param_2);\n    float _555 = _552.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _567 = _543 && (_555 > 2.5);\n    fa_light_is_area = _567;\n    bool _569 = _555 < 0.5;\n    vec3 l;\n    if (_569)\n    {\n        l = normalize(_547.xyz);\n        if (_543)\n        {\n            int param_3 = _539 + 6;\n            vec4 _584 = fa_light_texel(param_3);\n            if (_584.z > 0.5)\n            {\n                int param_4 = _539 + 4;\n                vec4 _594 = fa_light_texel(param_4);\n                int param_5 = _539 + 5;\n                vec4 _599 = fa_light_texel(param_5);\n                vec2 param_6 = _584.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _594.xyz) * _594.w, (-dot(world_pos, _599.xyz)) * _599.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _629 = _547.xyz;\n        vec3 _631 = _629 - world_pos;\n        vec3 to_light = _631;\n        float _634 = length(_631);\n        float reach = _634;\n        bool front = true;\n        if (_567)\n        {\n            int param_8 = _539 + 7;\n            reach = max(_634 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _539 + 4;\n            vec4 _658 = fa_light_texel(param_9);\n            int param_10 = _539 + 5;\n            vec4 _663 = fa_light_texel(param_10);\n            int param_11 = _539 + 6;\n            vec4 _668 = fa_light_texel(param_11);\n            float _669 = _668.w;\n            int param_12 = _539 + 2;\n            vec3 _676 = normalize(fa_light_texel(param_12).xyz);\n            bool _678 = _669 > 1.5;\n            bool _686;\n            if (!_678)\n            {\n                _686 = dot(_676, to_light) < 0.0;\n            }\n            else\n            {\n                _686 = _678;\n            }\n            front = _686;\n            vec3 r = vec3(0.0);\n            if (dot(n, n) > 0.5)\n            {\n                r = reflect(-normalize(fa_mesh_fs_params[0].xyz - world_pos), normalize(n));\n            }\n            vec3 param_13 = _629;\n            vec3 param_14 = _676;\n            vec3 param_15 = _658.xyz;\n            vec3 param_16 = _663.xyz;\n            float param_17 = _658.w;\n            float param_18 = _663.w;\n            float param_19 = _669;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _733 = length(to_light);\n        dist = _733;\n        l = to_light / vec3(max(_733, 9.9999997473787516355514526367188e-05));\n        float _747 = reach / max(_547.w, 0.001000000047497451305389404296875);\n        float _753 = clamp(1.0 - (_747 * _747), 0.0, 1.0);\n        float _755;\n        if (front)\n        {\n            _755 = _753 * _753;\n        }\n        else\n        {\n            _755 = 0.0;\n        }\n        atten = _755;\n        bool _766 = _555 < 2.5;\n        if ((_555 > 1.5) && _766)\n        {\n            int param_22 = _539 + 2;\n            vec4 _774 = fa_light_texel(param_22);\n            float _784 = _774.w;\n            int param_23 = _539 + 3;\n            vec4 _789 = fa_light_texel(param_23);\n            float _790 = _789.x;\n            float cos_inner = _790;\n            if (_790 > 1.5)\n            {\n                cos_inner = mix(_784, 1.0, 0.25);\n            }\n            atten *= smoothstep(_784, cos_inner, dot(-l, normalize(_774.xyz)));\n        }\n        if (_543 && (_555 < 1.5))\n        {\n            int param_24 = _539 + 6;\n            vec4 _814 = fa_light_texel(param_24);\n            if (_814.z > 0.5)\n            {\n                vec3 _822 = -to_light;\n                int param_25 = _539 + 4;\n                int param_26 = _539 + 5;\n                vec3 _836 = fa_light_texel(param_25).xyz;\n                vec3 _840 = fa_light_texel(param_26).xyz;\n                vec3 _849 = vec3(dot(_822, _836), dot(_822, _840), dot(_822, cross(_836, _840)));\n                vec3 param_27 = _849;\n                int _853 = fa_cube_face(param_27);\n                int param_28 = _853;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _880 = vec2(dot(_849, cross(param_29, param_30)), dot(_849, param_30)) / vec2(max(dot(_849, param_29), 9.9999997473787516355514526367188e-05));\n                int _884 = _853 / 3;\n                vec2 param_31 = _814.xy + (vec2(float(_853 - (_884 * 3)), float(_884)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _880.x), 0.5 - (0.5 * _880.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _539 + 7;\n            vec4 _914 = fa_light_texel(param_33);\n            if (_914.z > 0.5)\n            {\n                int param_34 = _539 + 2;\n                int param_35 = _539 + 4;\n                int param_36 = _539 + 5;\n                vec2 param_37 = _914.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_543 && _766)\n            {\n                int param_42 = _539 + 6;\n                vec4 _961 = fa_light_texel(param_42);\n                int param_43 = _539 + 7;\n                vec4 _966 = fa_light_texel(param_43);\n                bool _969 = _961.z > 0.5;\n                bool _976;\n                if (!_969)\n                {\n                    _976 = _966.z > 0.5;\n                }\n                else\n                {\n                    _976 = _969;\n                }\n                if (_976)\n                {\n                    int param_44 = _539 + 2;\n                    vec4 _983 = fa_light_texel(param_44);\n                    vec3 _987 = normalize(_983.xyz);\n                    int param_45 = _539 + 4;\n                    vec4 _992 = fa_light_texel(param_45);\n                    int param_46 = _539 + 5;\n                    vec4 _997 = fa_light_texel(param_46);\n                    if (_969)\n                    {\n                        vec3 _1005 = -to_light;\n                        float _1012 = _983.w;\n                        float _1028 = 0.5 / max(dot(_1005, _987) * (sqrt(max(1.0 - (_1012 * _1012), 0.0)) / max(_1012, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _961.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1005, _992.xyz) * _1028), 0.5 - (dot(_1005, _997.xyz) * _1028));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_966.z > 0.5)\n                    {\n                        vec2 param_49 = _966.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _987;\n                        vec3 param_52 = _992.xyz;\n                        vec3 param_53 = _997.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _2492 = _552.xyz * atten;\n    if (_543)\n    {\n        _2492 *= fa_light_tint;\n    }\n    int _1097;\n    if (_569)\n    {\n        _1097 = 0;\n    }\n    else\n    {\n        _1097 = ((_555 > 1.5) && (_555 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _2492, atten, 1.0, dist, _1097);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1152;\n    if (i == 0)\n    {\n        _1152 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1168;\n        if (i == 1)\n        {\n            _1168 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1176;\n            if (i == 2)\n            {\n                _1176 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1176 = fa_shadows[24].w;\n            }\n            _1168 = _1176;\n        }\n        _1152 = _1168;\n    }\n    return _1152;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1209 = fa_shadow_depth(param, param_1);\n    float _1213;\n    if (conv.x < 0.5)\n    {\n        _1213 = _1209;\n    }\n    else\n    {\n        _1213 = (conv.y * conv.z) / (conv.z - (_1209 * (conv.z - conv.y)));\n    }\n    return _1213;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1140 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1140), sin(_1140)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1259 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1268;\n        if (k < 0.0)\n        {\n            _1268 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _1268 = k;\n        }\n        float _1288 = clamp((_1268 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1259;\n            vec2 _1308 = fa_shadow_vogel(param_3, param_4, param_5) * _1288;\n            vec2 param_6 = uv + (_1308 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1320 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1320 < (zr - (length(_1308) * plane)))\n            {\n                sum += _1320;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _1346 = sum / cnt;\n        float _1356;\n        if (k < 0.0)\n        {\n            _1356 = (-k) / max(_1346, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _1356 = k;\n        }\n        radius = clamp(((max(zr - _1346, 0.0) * unit) * _1356) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1379 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1379; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1379;\n        float param_11 = _1259;\n        vec2 _1398 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1398 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1398) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1379);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1440 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1445 = clamp(dot(n, l), 0.0, 1.0);\n    float _1451 = sqrt(1.0 - (_1445 * _1445));\n    float _1459 = min(_1451 / max(_1445, 0.20000000298023223876953125), 4.0);\n    float _1464;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1464 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1464 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1489 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1464 * _1451)), 1.0);\n    float _1496 = _1489.x;\n    bool _1499 = _1496 < fa_shadows[ci * 1 + 16].x;\n    bool _1508;\n    if (!_1499)\n    {\n        _1508 = _1496 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1508 = _1499;\n    }\n    bool _1517;\n    if (!_1508)\n    {\n        _1517 = _1489.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1517 = _1508;\n    }\n    bool _1526;\n    if (!_1517)\n    {\n        _1526 = _1489.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1526 = _1517;\n    }\n    bool _1533;\n    if (!_1526)\n    {\n        _1533 = _1489.z > 1.0;\n    }\n    else\n    {\n        _1533 = _1526;\n    }\n    if (_1533)\n    {\n        return -1.0;\n    }\n    float _1541;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1541 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1541 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1489.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1489.z - ((_1541 * (1.0 + (0.5 * _1459))) / _1440);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1440;\n    float param_5 = _1440 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1459, 3.0)) * 0.5) / _1440;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1929 = int(fa_shadows[25].x + 0.5);\n    if (_1929 < 1)\n    {\n        return 1.0;\n    }\n    float _1944 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1929 - 1;\n    if (_1944 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1956 = _1929 > 1;\n    bool _1963;\n    if (_1956)\n    {\n        _1963 = _1944 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1963 = _1956;\n    }\n    if (_1963)\n    {\n        ci = 1;\n    }\n    bool _1967 = _1929 > 2;\n    bool _1974;\n    if (_1967)\n    {\n        _1974 = _1944 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1974 = _1967;\n    }\n    if (_1974)\n    {\n        ci = 2;\n    }\n    bool _1978 = _1929 > 3;\n    bool _1985;\n    if (_1978)\n    {\n        _1985 = _1944 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1985 = _1978;\n    }\n    if (_1985)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1929)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2011 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2011;\n        if (_2011 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2036;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2036 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2036 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2055 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2036, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2066 = clamp((_1944 - (fa_shadow_split_at(param_7) - _2055)) / _2055, 0.0, 1.0);\n        if (_2066 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1929)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2087 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2087;\n                if (_2087 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2066);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1599 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1606;\n    if (!_1599)\n    {\n        _1606 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1606 = _1599;\n    }\n    if (_1606)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1619 = fa_light_texel(param);\n    float _1620 = _1619.x;\n    if (_1620 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1629 = int(_1620 + 0.5);\n    int param_1 = _1629;\n    vec4 _1633 = fa_light_texel(param_1);\n    int param_2 = _1629 + 1;\n    vec4 _1638 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1641 = _1633.y;\n    if (_1641 > 0.0)\n    {\n        float _1658 = 1.0 - smoothstep(0.75 * _1641, _1641, length(world - fa_shadows[27].xyz));\n        fade = _1658;\n        if (_1658 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1633.x > 1.5)\n    {\n        int param_3 = li;\n        int param_4 = fa_light_base(param_3);\n        vec3 param_5 = world - fa_light_texel(param_4).xyz;\n        face = fa_cube_face(param_5);\n    }\n    int _1687 = (_1629 + 2) + (face * 6);\n    int param_6 = _1687;\n    int param_7 = _1687 + 1;\n    int param_8 = _1687 + 3;\n    vec4 _1701 = fa_light_texel(param_8);\n    int param_9 = _1687 + 4;\n    vec4 _1706 = fa_light_texel(param_9);\n    int param_10 = _1687 + 5;\n    vec4 _1711 = fa_light_texel(param_10);\n    float _1723 = _1711.x * max(dot(_1701, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1728 = clamp(dot(n, l), 0.0, 1.0);\n    float _1751 = clamp(dot(n, _1701.xyz), -1.0, 1.0);\n    int param_11 = li;\n    int param_12 = fa_light_base(param_11);\n    float _1775 = min(sqrt(1.0 - (_1751 * _1751)) / max(abs(dot(n, world - fa_light_texel(param_12).xyz)) / max(dot(_1701, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1778 = _1638.y;\n    float _1780;\n    if (_1778 > 0.0)\n    {\n        _1780 = _1778;\n    }\n    else\n    {\n        _1780 = 1.5 * _1723;\n    }\n    vec4 _1800 = vec4(world + (n * (_1780 * sqrt(1.0 - (_1728 * _1728)))), 1.0);\n    float _1804 = dot(_1701, _1800);\n    float _1807 = _1711.y;\n    if (_1804 < _1807)\n    {\n        return 1.0;\n    }\n    vec2 _1822 = vec2(dot(fa_light_texel(param_6), _1800), dot(fa_light_texel(param_7), _1800)) / vec2(_1804);\n    float _1824 = _1822.x;\n    bool _1827 = _1824 < _1706.x;\n    bool _1836;\n    if (!_1827)\n    {\n        _1836 = _1824 > _1706.z;\n    }\n    else\n    {\n        _1836 = _1827;\n    }\n    bool _1845;\n    if (!_1836)\n    {\n        _1845 = _1822.y < _1706.y;\n    }\n    else\n    {\n        _1845 = _1836;\n    }\n    bool _1854;\n    if (!_1845)\n    {\n        _1854 = _1822.y > _1706.w;\n    }\n    else\n    {\n        _1854 = _1845;\n    }\n    if (_1854)\n    {\n        return 1.0;\n    }\n    float _1860 = _1638.x;\n    float _1862;\n    if (_1860 > 0.0)\n    {\n        _1862 = _1860;\n    }\n    else\n    {\n        _1862 = 1.5 * _1723;\n    }\n    vec2 param_13 = _1822;\n    vec4 param_14 = _1706;\n    float param_15 = _1804 - (_1862 * (1.0 + (0.5 * _1775)));\n    float param_16 = _1723;\n    float param_17 = 1.0;\n    float param_18 = _1711.z * 0.25;\n    float param_19 = (_1723 * min(_1775, 3.0)) * 0.5;\n    vec3 param_20 = vec3(1.0, _1807, _1711.z);\n    int param_21 = int(_1633.z + 0.5);\n    float param_22 = _1633.w;\n    return mix(1.0, fa_shadow_filter(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22), fade);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = gn;\n    LightSample _2128 = fa_light_sample_n(param, param_1, param_2);\n    vec3 _2505 = _2128.color;\n    float _2507 = _2128.shadow;\n    if ((_2128.type == 0) && (li == 0))\n    {\n        vec4 param_3 = coord;\n        vec3 param_4 = gn;\n        vec3 param_5 = _2128.direction;\n        float _2144 = fa_shadow(param_3, param_4, param_5);\n        _2507 = _2144;\n        _2505 *= _2144;\n    }\n    else\n    {\n        bool _2155 = _2128.type != 0;\n        bool _2161;\n        if (_2155)\n        {\n            _2161 = _2128.attenuation > 0.0;\n        }\n        else\n        {\n            _2161 = _2155;\n        }\n        if (_2161)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _2128.direction;\n            float _2173 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _2507 = _2173;\n            _2505 *= _2173;\n        }\n    }\n    return LightSample(_2128.direction, _2505, _2128.attenuation, _2507, _2128._distance, _2128.type);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _2186 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2193;\n    if (!_2186)\n    {\n        _2193 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2193 = _2186;\n    }\n    if (_2193)\n    {\n        vec3 _2201 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _2208 = dot(_2201, fa_mesh_fs_params[9].xyz);\n        bool _2212 = fa_mesh_fs_params[9].w > 0.5;\n        float _2213;\n        if (_2212)\n        {\n            _2213 = _2208;\n        }\n        else\n        {\n            _2213 = length(_2201);\n        }\n        float _2225 = _2213 - fa_mesh_fs_params[8].x;\n        if (_2225 > 0.0)\n        {\n            float _2234 = fa_mesh_fs_params[7].w * _2225;\n            float tau = _2234 * _2234;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2250;\n                if (_2212)\n                {\n                    _2250 = world_pos.y - (fa_mesh_fs_params[9].y * _2208);\n                }\n                else\n                {\n                    _2250 = fa_mesh_fs_params[0].y;\n                }\n                float _2271 = mix(_2250, world_pos.y, clamp(fa_mesh_fs_params[8].x / _2213, 0.0, 1.0));\n                float _2275 = world_pos.y - _2271;\n                float _2280 = _2271 - fa_mesh_fs_params[8].z;\n                float _2285 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2288 = _2280 <= 0.0;\n                bool _2289 = !_2288;\n                bool _2295;\n                if (_2289)\n                {\n                    _2295 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2295 = _2288;\n                }\n                float _2296;\n                if (_2295)\n                {\n                    _2296 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2296 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2280, 80.0));\n                }\n                bool _2323;\n                if (_2289)\n                {\n                    _2323 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2323 = _2288;\n                }\n                float _2324;\n                if (_2323)\n                {\n                    _2324 = fa_mesh_fs_params[8].y * _2280;\n                }\n                else\n                {\n                    _2324 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2280, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2349 = _2285 <= 0.0;\n                bool _2356;\n                if (!_2349)\n                {\n                    _2356 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2356 = _2349;\n                }\n                float _2357;\n                if (_2356)\n                {\n                    _2357 = fa_mesh_fs_params[8].y * _2285;\n                }\n                else\n                {\n                    _2357 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2285, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2384;\n                if (abs(_2275) < 0.001000000047497451305389404296875)\n                {\n                    _2384 = _2296;\n                }\n                else\n                {\n                    _2384 = (_2357 - _2324) / _2275;\n                }\n                tau += (_2225 * max(_2384, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _2422 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _2422;\n        vec4 param_3 = v_shadow;\n        LightSample _2454 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _2454.color) * max(dot(_2422, _2454.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _2477 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_2477, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_247",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
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
            "inst_name": "_154",
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
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_1162",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2429",
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
