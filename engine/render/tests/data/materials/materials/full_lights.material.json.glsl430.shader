{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "bf4e2cb3aa2fb5c09a12d4cbd173f0841cd9abe2a5f3e65ca0cbd779f7342963",
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
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_light_atlas_fa_env_smp;\nlayout(binding = 2) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_full_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_full_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _375 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _388 = (c - (ru * hx)) - p;\n        vec3 _394 = ru * (2.0 * hx);\n        float _400 = max(dot(_394, _394), 9.9999999392252902907785028219223e-09);\n        float _404 = dot(_388, _394);\n        float t = clamp((-_404) / _400, 0.0, 1.0);\n        if (_375)\n        {\n            float _419 = dot(r, _394);\n            float _425 = _400 - (_419 * _419);\n            if (abs(_425) > (9.9999997473787516355514526367188e-06 * _400))\n            {\n                t = clamp(((dot(r, _388) * _419) - _404) / _425, 0.0, 1.0);\n            }\n        }\n        return (p + _388) + (_394 * t);\n    }\n    vec3 q = p;\n    float _457 = dot(r, axis);\n    bool _465;\n    if (_375)\n    {\n        _465 = abs(_457) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _465 = _375;\n    }\n    if (_465)\n    {\n        float _475 = dot(c - p, axis) / _457;\n        if (_475 > 0.0)\n        {\n            q = p + (r * _475);\n        }\n    }\n    vec3 _488 = q - c;\n    vec2 xy = vec2(dot(_488, ru), dot(_488, uu));\n    if (shape > 0.5)\n    {\n        float _503 = length(xy);\n        if (_503 > hx)\n        {\n            xy *= (hx / _503);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _155 = abs(d);\n    float _160 = _155.x;\n    float _163 = _155.y;\n    bool _164 = _160 >= _163;\n    bool _173;\n    if (_164)\n    {\n        _173 = _160 >= _155.z;\n    }\n    else\n    {\n        _173 = _164;\n    }\n    int _174;\n    if (_173)\n    {\n        _174 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _190;\n        if (_163 >= _155.z)\n        {\n            _190 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _190 = (d.z > 0.0) ? 4 : 5;\n        }\n        _174 = _190;\n    }\n    return _174;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _293 = dot(d, right);\n    float _297 = dot(d, up);\n    float _308;\n    if (((_293 * _293) + (_297 * _297)) > 1.0000000133514319600180897396058e-10)\n    {\n        _308 = atan(_297, _293) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _308 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_308 - floor(_308)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _541 = fa_light_base(param);\n    bool _545 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _541;\n    vec4 _549 = fa_light_texel(param_1);\n    int param_2 = _541 + 1;\n    vec4 _554 = fa_light_texel(param_2);\n    float _557 = _554.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _569 = _545 && (_557 > 2.5);\n    fa_light_is_area = _569;\n    bool _571 = _557 < 0.5;\n    vec3 l;\n    if (_571)\n    {\n        l = normalize(_549.xyz);\n        if (_545)\n        {\n            int param_3 = _541 + 6;\n            vec4 _586 = fa_light_texel(param_3);\n            if (_586.z > 0.5)\n            {\n                int param_4 = _541 + 4;\n                vec4 _596 = fa_light_texel(param_4);\n                int param_5 = _541 + 5;\n                vec4 _601 = fa_light_texel(param_5);\n                vec2 param_6 = _586.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _596.xyz) * _596.w, (-dot(world_pos, _601.xyz)) * _601.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _631 = _549.xyz;\n        vec3 _633 = _631 - world_pos;\n        vec3 to_light = _633;\n        float _636 = length(_633);\n        float reach = _636;\n        bool front = true;\n        if (_569)\n        {\n            int param_8 = _541 + 7;\n            reach = max(_636 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _541 + 4;\n            vec4 _660 = fa_light_texel(param_9);\n            int param_10 = _541 + 5;\n            vec4 _665 = fa_light_texel(param_10);\n            int param_11 = _541 + 6;\n            vec4 _670 = fa_light_texel(param_11);\n            float _671 = _670.w;\n            int param_12 = _541 + 2;\n            vec3 _678 = normalize(fa_light_texel(param_12).xyz);\n            bool _680 = _671 > 1.5;\n            bool _688;\n            if (!_680)\n            {\n                _688 = dot(_678, to_light) < 0.0;\n            }\n            else\n            {\n                _688 = _680;\n            }\n            front = _688;\n            vec3 r = vec3(0.0);\n            vec3 _697 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _701 = dot(n, n) > 0.5;\n            bool _709;\n            if (_701)\n            {\n                _709 = dot(_697, _697) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _709 = _701;\n            }\n            if (_709)\n            {\n                r = reflect(-normalize(_697), normalize(n));\n            }\n            vec3 param_13 = _631;\n            vec3 param_14 = _678;\n            vec3 param_15 = _660.xyz;\n            vec3 param_16 = _665.xyz;\n            float param_17 = _660.w;\n            float param_18 = _665.w;\n            float param_19 = _671;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _745 = length(to_light);\n        dist = _745;\n        l = to_light / vec3(max(_745, 9.9999997473787516355514526367188e-05));\n        float _759 = reach / max(_549.w, 0.001000000047497451305389404296875);\n        float _765 = clamp(1.0 - (_759 * _759), 0.0, 1.0);\n        float _767;\n        if (front)\n        {\n            _767 = _765 * _765;\n        }\n        else\n        {\n            _767 = 0.0;\n        }\n        atten = _767;\n        bool _778 = _557 < 2.5;\n        if ((_557 > 1.5) && _778)\n        {\n            int param_22 = _541 + 2;\n            vec4 _786 = fa_light_texel(param_22);\n            float _796 = _786.w;\n            int param_23 = _541 + 3;\n            vec4 _801 = fa_light_texel(param_23);\n            float _802 = _801.x;\n            float cos_inner = _802;\n            if (_802 > 1.5)\n            {\n                cos_inner = mix(_796, 1.0, 0.25);\n            }\n            atten *= smoothstep(_796, cos_inner, dot(-l, normalize(_786.xyz)));\n        }\n        if (_545 && (_557 < 1.5))\n        {\n            int param_24 = _541 + 6;\n            vec4 _826 = fa_light_texel(param_24);\n            if (_826.z > 0.5)\n            {\n                vec3 _834 = -to_light;\n                int param_25 = _541 + 4;\n                int param_26 = _541 + 5;\n                vec3 _848 = fa_light_texel(param_25).xyz;\n                vec3 _852 = fa_light_texel(param_26).xyz;\n                vec3 _861 = vec3(dot(_834, _848), dot(_834, _852), dot(_834, cross(_848, _852)));\n                vec3 param_27 = _861;\n                int _865 = fa_cube_face(param_27);\n                int param_28 = _865;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _892 = vec2(dot(_861, cross(param_29, param_30)), dot(_861, param_30)) / vec2(max(dot(_861, param_29), 9.9999997473787516355514526367188e-05));\n                int _896 = _865 / 3;\n                vec2 param_31 = _826.xy + (vec2(float(_865 - (_896 * 3)), float(_896)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _892.x), 0.5 - (0.5 * _892.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _541 + 7;\n            vec4 _926 = fa_light_texel(param_33);\n            if (_926.z > 0.5)\n            {\n                int param_34 = _541 + 2;\n                int param_35 = _541 + 4;\n                int param_36 = _541 + 5;\n                vec2 param_37 = _926.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_545 && _778)\n            {\n                int param_42 = _541 + 6;\n                vec4 _973 = fa_light_texel(param_42);\n                int param_43 = _541 + 7;\n                vec4 _978 = fa_light_texel(param_43);\n                bool _981 = _973.z > 0.5;\n                bool _988;\n                if (!_981)\n                {\n                    _988 = _978.z > 0.5;\n                }\n                else\n                {\n                    _988 = _981;\n                }\n                if (_988)\n                {\n                    int param_44 = _541 + 2;\n                    vec4 _995 = fa_light_texel(param_44);\n                    vec3 _999 = normalize(_995.xyz);\n                    int param_45 = _541 + 4;\n                    vec4 _1004 = fa_light_texel(param_45);\n                    int param_46 = _541 + 5;\n                    vec4 _1009 = fa_light_texel(param_46);\n                    if (_981)\n                    {\n                        vec3 _1017 = -to_light;\n                        float _1024 = _995.w;\n                        float _1040 = 0.5 / max(dot(_1017, _999) * (sqrt(max(1.0 - (_1024 * _1024), 0.0)) / max(_1024, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _973.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1017, _1004.xyz) * _1040), 0.5 - (dot(_1017, _1009.xyz) * _1040));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_978.z > 0.5)\n                    {\n                        vec2 param_49 = _978.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _999;\n                        vec3 param_52 = _1004.xyz;\n                        vec3 param_53 = _1009.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _2500 = _554.xyz * atten;\n    if (_545)\n    {\n        _2500 *= fa_light_tint;\n    }\n    int _1109;\n    if (_571)\n    {\n        _1109 = 0;\n    }\n    else\n    {\n        _1109 = ((_557 > 1.5) && (_557 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _2500, atten, 1.0, dist, _1109);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1164;\n    if (i == 0)\n    {\n        _1164 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1180;\n        if (i == 1)\n        {\n            _1180 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1188;\n            if (i == 2)\n            {\n                _1188 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1188 = fa_shadows[24].w;\n            }\n            _1180 = _1188;\n        }\n        _1164 = _1180;\n    }\n    return _1164;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1221 = fa_shadow_depth(param, param_1);\n    float _1225;\n    if (conv.x < 0.5)\n    {\n        _1225 = _1221;\n    }\n    else\n    {\n        _1225 = (conv.y * conv.z) / (conv.z - (_1221 * (conv.z - conv.y)));\n    }\n    return _1225;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1152 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1152), sin(_1152)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1271 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1280;\n        if (k < 0.0)\n        {\n            _1280 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _1280 = k;\n        }\n        float _1300 = clamp((_1280 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1271;\n            vec2 _1320 = fa_shadow_vogel(param_3, param_4, param_5) * _1300;\n            vec2 param_6 = uv + (_1320 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1332 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1332 < (zr - (length(_1320) * plane)))\n            {\n                sum += _1332;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _1358 = sum / cnt;\n        float _1368;\n        if (k < 0.0)\n        {\n            _1368 = (-k) / max(_1358, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _1368 = k;\n        }\n        radius = clamp(((max(zr - _1358, 0.0) * unit) * _1368) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1391 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1391; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1391;\n        float param_11 = _1271;\n        vec2 _1410 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1410 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1410) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1391);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1452 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1457 = clamp(dot(n, l), 0.0, 1.0);\n    float _1463 = sqrt(1.0 - (_1457 * _1457));\n    float _1471 = min(_1463 / max(_1457, 0.20000000298023223876953125), 4.0);\n    float _1476;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1476 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1476 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1501 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1476 * _1463)), 1.0);\n    float _1508 = _1501.x;\n    bool _1511 = _1508 < fa_shadows[ci * 1 + 16].x;\n    bool _1520;\n    if (!_1511)\n    {\n        _1520 = _1508 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1520 = _1511;\n    }\n    bool _1529;\n    if (!_1520)\n    {\n        _1529 = _1501.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1529 = _1520;\n    }\n    bool _1538;\n    if (!_1529)\n    {\n        _1538 = _1501.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1538 = _1529;\n    }\n    bool _1545;\n    if (!_1538)\n    {\n        _1545 = _1501.z > 1.0;\n    }\n    else\n    {\n        _1545 = _1538;\n    }\n    if (_1545)\n    {\n        return -1.0;\n    }\n    float _1553;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1553 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1553 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1501.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1501.z - ((_1553 * (1.0 + (0.5 * _1471))) / _1452);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1452;\n    float param_5 = _1452 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1471, 3.0)) * 0.5) / _1452;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1931 = int(fa_shadows[25].x + 0.5);\n    if (_1931 < 1)\n    {\n        return 1.0;\n    }\n    float _1946 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1931 - 1;\n    if (_1946 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1958 = _1931 > 1;\n    bool _1965;\n    if (_1958)\n    {\n        _1965 = _1946 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1965 = _1958;\n    }\n    if (_1965)\n    {\n        ci = 1;\n    }\n    bool _1969 = _1931 > 2;\n    bool _1976;\n    if (_1969)\n    {\n        _1976 = _1946 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1976 = _1969;\n    }\n    if (_1976)\n    {\n        ci = 2;\n    }\n    bool _1980 = _1931 > 3;\n    bool _1987;\n    if (_1980)\n    {\n        _1987 = _1946 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1987 = _1980;\n    }\n    if (_1987)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1931)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2013 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2013;\n        if (_2013 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2038;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2038 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2038 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2057 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2038, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2068 = clamp((_1946 - (fa_shadow_split_at(param_7) - _2057)) / _2057, 0.0, 1.0);\n        if (_2068 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1931)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2089 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2089;\n                if (_2089 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2068);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _1611 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1618;\n    if (!_1611)\n    {\n        _1618 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1618 = _1611;\n    }\n    if (_1618)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1631 = fa_light_texel(param);\n    float _1632 = _1631.x;\n    if (_1632 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1641 = int(_1632 + 0.5);\n    int param_1 = _1641;\n    vec4 _1645 = fa_light_texel(param_1);\n    int param_2 = _1641 + 1;\n    vec4 _1650 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1653 = _1645.y;\n    if (_1653 > 0.0)\n    {\n        float _1670 = 1.0 - smoothstep(0.75 * _1653, _1653, length(world - fa_shadows[27].xyz));\n        fade = _1670;\n        if (_1670 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1645.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _1694 = (_1641 + 2) + (face * 6);\n    int param_4 = _1694;\n    int param_5 = _1694 + 1;\n    int param_6 = _1694 + 3;\n    vec4 _1708 = fa_light_texel(param_6);\n    int param_7 = _1694 + 4;\n    vec4 _1713 = fa_light_texel(param_7);\n    int param_8 = _1694 + 5;\n    vec4 _1718 = fa_light_texel(param_8);\n    float _1730 = _1718.x * max(dot(_1708, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1735 = clamp(dot(n, l), 0.0, 1.0);\n    float _1758 = clamp(dot(n, _1708.xyz), -1.0, 1.0);\n    float _1777 = min(sqrt(1.0 - (_1758 * _1758)) / max(abs(dot(n, world - lpos)) / max(dot(_1708, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1780 = _1650.y;\n    float _1782;\n    if (_1780 > 0.0)\n    {\n        _1782 = _1780;\n    }\n    else\n    {\n        _1782 = 1.5 * _1730;\n    }\n    vec4 _1802 = vec4(world + (n * (_1782 * sqrt(1.0 - (_1735 * _1735)))), 1.0);\n    float _1806 = dot(_1708, _1802);\n    float _1809 = _1718.y;\n    if (_1806 < _1809)\n    {\n        return 1.0;\n    }\n    vec2 _1824 = vec2(dot(fa_light_texel(param_4), _1802), dot(fa_light_texel(param_5), _1802)) / vec2(_1806);\n    float _1826 = _1824.x;\n    bool _1829 = _1826 < _1713.x;\n    bool _1838;\n    if (!_1829)\n    {\n        _1838 = _1826 > _1713.z;\n    }\n    else\n    {\n        _1838 = _1829;\n    }\n    bool _1847;\n    if (!_1838)\n    {\n        _1847 = _1824.y < _1713.y;\n    }\n    else\n    {\n        _1847 = _1838;\n    }\n    bool _1856;\n    if (!_1847)\n    {\n        _1856 = _1824.y > _1713.w;\n    }\n    else\n    {\n        _1856 = _1847;\n    }\n    if (_1856)\n    {\n        return 1.0;\n    }\n    float _1862 = _1650.x;\n    float _1864;\n    if (_1862 > 0.0)\n    {\n        _1864 = _1862;\n    }\n    else\n    {\n        _1864 = 1.5 * _1730;\n    }\n    vec2 param_9 = _1824;\n    vec4 param_10 = _1713;\n    float param_11 = _1806 - (_1864 * (1.0 + (0.5 * _1777)));\n    float param_12 = _1730;\n    float param_13 = 1.0;\n    float param_14 = _1718.z * 0.25;\n    float param_15 = (_1730 * min(_1777, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1809, _1718.z);\n    int param_17 = int(_1645.z + 0.5);\n    float param_18 = _1645.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = gn;\n    LightSample _2130 = fa_light_sample_n(param, param_1, param_2);\n    vec3 _2513 = _2130.color;\n    float _2515 = _2130.shadow;\n    if ((_2130.type == 0) && (li == 0))\n    {\n        vec4 param_3 = coord;\n        vec3 param_4 = gn;\n        vec3 param_5 = _2130.direction;\n        float _2146 = fa_shadow(param_3, param_4, param_5);\n        _2515 = _2146;\n        _2513 *= _2146;\n    }\n    else\n    {\n        bool _2157 = _2130.type != 0;\n        bool _2163;\n        if (_2157)\n        {\n            _2163 = _2130.attenuation > 0.0;\n        }\n        else\n        {\n            _2163 = _2157;\n        }\n        if (_2163)\n        {\n            int param_6 = li;\n            int param_7 = fa_light_base(param_6);\n            int param_8 = li;\n            vec3 param_9 = fa_light_texel(param_7).xyz;\n            vec3 param_10 = world_pos;\n            vec3 param_11 = gn;\n            vec3 param_12 = _2130.direction;\n            float _2182 = fa_shadow_local(param_8, param_9, param_10, param_11, param_12);\n            _2515 = _2182;\n            _2513 *= _2182;\n        }\n    }\n    return LightSample(_2130.direction, _2513, _2130.attenuation, _2515, _2130._distance, _2130.type);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _2195 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2202;\n    if (!_2195)\n    {\n        _2202 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2202 = _2195;\n    }\n    if (_2202)\n    {\n        vec3 _2210 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _2217 = dot(_2210, fa_mesh_fs_params[9].xyz);\n        bool _2221 = fa_mesh_fs_params[9].w > 0.5;\n        float _2222;\n        if (_2221)\n        {\n            _2222 = _2217;\n        }\n        else\n        {\n            _2222 = length(_2210);\n        }\n        float _2234 = _2222 - fa_mesh_fs_params[8].x;\n        if (_2234 > 0.0)\n        {\n            float _2243 = fa_mesh_fs_params[7].w * _2234;\n            float tau = _2243 * _2243;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2259;\n                if (_2221)\n                {\n                    _2259 = world_pos.y - (fa_mesh_fs_params[9].y * _2217);\n                }\n                else\n                {\n                    _2259 = fa_mesh_fs_params[0].y;\n                }\n                float _2280 = mix(_2259, world_pos.y, clamp(fa_mesh_fs_params[8].x / _2222, 0.0, 1.0));\n                float _2284 = world_pos.y - _2280;\n                float _2289 = _2280 - fa_mesh_fs_params[8].z;\n                float _2294 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2297 = _2289 <= 0.0;\n                bool _2298 = !_2297;\n                bool _2304;\n                if (_2298)\n                {\n                    _2304 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2304 = _2297;\n                }\n                float _2305;\n                if (_2304)\n                {\n                    _2305 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2305 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2289, 80.0));\n                }\n                bool _2332;\n                if (_2298)\n                {\n                    _2332 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2332 = _2297;\n                }\n                float _2333;\n                if (_2332)\n                {\n                    _2333 = fa_mesh_fs_params[8].y * _2289;\n                }\n                else\n                {\n                    _2333 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2289, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2358 = _2294 <= 0.0;\n                bool _2365;\n                if (!_2358)\n                {\n                    _2365 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2365 = _2358;\n                }\n                float _2366;\n                if (_2365)\n                {\n                    _2366 = fa_mesh_fs_params[8].y * _2294;\n                }\n                else\n                {\n                    _2366 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2294, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2393;\n                if (abs(_2284) < 0.001000000047497451305389404296875)\n                {\n                    _2393 = _2305;\n                }\n                else\n                {\n                    _2393 = (_2366 - _2333) / _2284;\n                }\n                tau += (_2234 * max(_2393, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _2431 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _2431;\n        vec4 param_3 = v_shadow;\n        LightSample _2463 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _2463.color) * max(dot(_2431, _2463.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _2486 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_2486, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_1174",
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
            "inst_name": "_2438",
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
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_light_atlas_fa_env_smp;\nlayout(binding = 2) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_full_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_full_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _375 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _388 = (c - (ru * hx)) - p;\n        vec3 _394 = ru * (2.0 * hx);\n        float _400 = max(dot(_394, _394), 9.9999999392252902907785028219223e-09);\n        float _404 = dot(_388, _394);\n        float t = clamp((-_404) / _400, 0.0, 1.0);\n        if (_375)\n        {\n            float _419 = dot(r, _394);\n            float _425 = _400 - (_419 * _419);\n            if (abs(_425) > (9.9999997473787516355514526367188e-06 * _400))\n            {\n                t = clamp(((dot(r, _388) * _419) - _404) / _425, 0.0, 1.0);\n            }\n        }\n        return (p + _388) + (_394 * t);\n    }\n    vec3 q = p;\n    float _457 = dot(r, axis);\n    bool _465;\n    if (_375)\n    {\n        _465 = abs(_457) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _465 = _375;\n    }\n    if (_465)\n    {\n        float _475 = dot(c - p, axis) / _457;\n        if (_475 > 0.0)\n        {\n            q = p + (r * _475);\n        }\n    }\n    vec3 _488 = q - c;\n    vec2 xy = vec2(dot(_488, ru), dot(_488, uu));\n    if (shape > 0.5)\n    {\n        float _503 = length(xy);\n        if (_503 > hx)\n        {\n            xy *= (hx / _503);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _155 = abs(d);\n    float _160 = _155.x;\n    float _163 = _155.y;\n    bool _164 = _160 >= _163;\n    bool _173;\n    if (_164)\n    {\n        _173 = _160 >= _155.z;\n    }\n    else\n    {\n        _173 = _164;\n    }\n    int _174;\n    if (_173)\n    {\n        _174 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _190;\n        if (_163 >= _155.z)\n        {\n            _190 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _190 = (d.z > 0.0) ? 4 : 5;\n        }\n        _174 = _190;\n    }\n    return _174;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _293 = dot(d, right);\n    float _297 = dot(d, up);\n    float _308;\n    if (((_293 * _293) + (_297 * _297)) > 1.0000000133514319600180897396058e-10)\n    {\n        _308 = atan(_297, _293) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _308 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_308 - floor(_308)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _541 = fa_light_base(param);\n    bool _545 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _541;\n    vec4 _549 = fa_light_texel(param_1);\n    int param_2 = _541 + 1;\n    vec4 _554 = fa_light_texel(param_2);\n    float _557 = _554.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _569 = _545 && (_557 > 2.5);\n    fa_light_is_area = _569;\n    bool _571 = _557 < 0.5;\n    vec3 l;\n    if (_571)\n    {\n        l = normalize(_549.xyz);\n        if (_545)\n        {\n            int param_3 = _541 + 6;\n            vec4 _586 = fa_light_texel(param_3);\n            if (_586.z > 0.5)\n            {\n                int param_4 = _541 + 4;\n                vec4 _596 = fa_light_texel(param_4);\n                int param_5 = _541 + 5;\n                vec4 _601 = fa_light_texel(param_5);\n                vec2 param_6 = _586.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _596.xyz) * _596.w, (-dot(world_pos, _601.xyz)) * _601.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _631 = _549.xyz;\n        vec3 _633 = _631 - world_pos;\n        vec3 to_light = _633;\n        float _636 = length(_633);\n        float reach = _636;\n        bool front = true;\n        if (_569)\n        {\n            int param_8 = _541 + 7;\n            reach = max(_636 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _541 + 4;\n            vec4 _660 = fa_light_texel(param_9);\n            int param_10 = _541 + 5;\n            vec4 _665 = fa_light_texel(param_10);\n            int param_11 = _541 + 6;\n            vec4 _670 = fa_light_texel(param_11);\n            float _671 = _670.w;\n            int param_12 = _541 + 2;\n            vec3 _678 = normalize(fa_light_texel(param_12).xyz);\n            bool _680 = _671 > 1.5;\n            bool _688;\n            if (!_680)\n            {\n                _688 = dot(_678, to_light) < 0.0;\n            }\n            else\n            {\n                _688 = _680;\n            }\n            front = _688;\n            vec3 r = vec3(0.0);\n            vec3 _697 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _701 = dot(n, n) > 0.5;\n            bool _709;\n            if (_701)\n            {\n                _709 = dot(_697, _697) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _709 = _701;\n            }\n            if (_709)\n            {\n                r = reflect(-normalize(_697), normalize(n));\n            }\n            vec3 param_13 = _631;\n            vec3 param_14 = _678;\n            vec3 param_15 = _660.xyz;\n            vec3 param_16 = _665.xyz;\n            float param_17 = _660.w;\n            float param_18 = _665.w;\n            float param_19 = _671;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _745 = length(to_light);\n        dist = _745;\n        l = to_light / vec3(max(_745, 9.9999997473787516355514526367188e-05));\n        float _759 = reach / max(_549.w, 0.001000000047497451305389404296875);\n        float _765 = clamp(1.0 - (_759 * _759), 0.0, 1.0);\n        float _767;\n        if (front)\n        {\n            _767 = _765 * _765;\n        }\n        else\n        {\n            _767 = 0.0;\n        }\n        atten = _767;\n        bool _778 = _557 < 2.5;\n        if ((_557 > 1.5) && _778)\n        {\n            int param_22 = _541 + 2;\n            vec4 _786 = fa_light_texel(param_22);\n            float _796 = _786.w;\n            int param_23 = _541 + 3;\n            vec4 _801 = fa_light_texel(param_23);\n            float _802 = _801.x;\n            float cos_inner = _802;\n            if (_802 > 1.5)\n            {\n                cos_inner = mix(_796, 1.0, 0.25);\n            }\n            atten *= smoothstep(_796, cos_inner, dot(-l, normalize(_786.xyz)));\n        }\n        if (_545 && (_557 < 1.5))\n        {\n            int param_24 = _541 + 6;\n            vec4 _826 = fa_light_texel(param_24);\n            if (_826.z > 0.5)\n            {\n                vec3 _834 = -to_light;\n                int param_25 = _541 + 4;\n                int param_26 = _541 + 5;\n                vec3 _848 = fa_light_texel(param_25).xyz;\n                vec3 _852 = fa_light_texel(param_26).xyz;\n                vec3 _861 = vec3(dot(_834, _848), dot(_834, _852), dot(_834, cross(_848, _852)));\n                vec3 param_27 = _861;\n                int _865 = fa_cube_face(param_27);\n                int param_28 = _865;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _892 = vec2(dot(_861, cross(param_29, param_30)), dot(_861, param_30)) / vec2(max(dot(_861, param_29), 9.9999997473787516355514526367188e-05));\n                int _896 = _865 / 3;\n                vec2 param_31 = _826.xy + (vec2(float(_865 - (_896 * 3)), float(_896)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _892.x), 0.5 - (0.5 * _892.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _541 + 7;\n            vec4 _926 = fa_light_texel(param_33);\n            if (_926.z > 0.5)\n            {\n                int param_34 = _541 + 2;\n                int param_35 = _541 + 4;\n                int param_36 = _541 + 5;\n                vec2 param_37 = _926.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_545 && _778)\n            {\n                int param_42 = _541 + 6;\n                vec4 _973 = fa_light_texel(param_42);\n                int param_43 = _541 + 7;\n                vec4 _978 = fa_light_texel(param_43);\n                bool _981 = _973.z > 0.5;\n                bool _988;\n                if (!_981)\n                {\n                    _988 = _978.z > 0.5;\n                }\n                else\n                {\n                    _988 = _981;\n                }\n                if (_988)\n                {\n                    int param_44 = _541 + 2;\n                    vec4 _995 = fa_light_texel(param_44);\n                    vec3 _999 = normalize(_995.xyz);\n                    int param_45 = _541 + 4;\n                    vec4 _1004 = fa_light_texel(param_45);\n                    int param_46 = _541 + 5;\n                    vec4 _1009 = fa_light_texel(param_46);\n                    if (_981)\n                    {\n                        vec3 _1017 = -to_light;\n                        float _1024 = _995.w;\n                        float _1040 = 0.5 / max(dot(_1017, _999) * (sqrt(max(1.0 - (_1024 * _1024), 0.0)) / max(_1024, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _973.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1017, _1004.xyz) * _1040), 0.5 - (dot(_1017, _1009.xyz) * _1040));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_978.z > 0.5)\n                    {\n                        vec2 param_49 = _978.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _999;\n                        vec3 param_52 = _1004.xyz;\n                        vec3 param_53 = _1009.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _2500 = _554.xyz * atten;\n    if (_545)\n    {\n        _2500 *= fa_light_tint;\n    }\n    int _1109;\n    if (_571)\n    {\n        _1109 = 0;\n    }\n    else\n    {\n        _1109 = ((_557 > 1.5) && (_557 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _2500, atten, 1.0, dist, _1109);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1164;\n    if (i == 0)\n    {\n        _1164 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1180;\n        if (i == 1)\n        {\n            _1180 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1188;\n            if (i == 2)\n            {\n                _1188 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1188 = fa_shadows[24].w;\n            }\n            _1180 = _1188;\n        }\n        _1164 = _1180;\n    }\n    return _1164;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1221 = fa_shadow_depth(param, param_1);\n    float _1225;\n    if (conv.x < 0.5)\n    {\n        _1225 = _1221;\n    }\n    else\n    {\n        _1225 = (conv.y * conv.z) / (conv.z - (_1221 * (conv.z - conv.y)));\n    }\n    return _1225;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1152 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1152), sin(_1152)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1271 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1280;\n        if (k < 0.0)\n        {\n            _1280 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _1280 = k;\n        }\n        float _1300 = clamp((_1280 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1271;\n            vec2 _1320 = fa_shadow_vogel(param_3, param_4, param_5) * _1300;\n            vec2 param_6 = uv + (_1320 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1332 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1332 < (zr - (length(_1320) * plane)))\n            {\n                sum += _1332;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _1358 = sum / cnt;\n        float _1368;\n        if (k < 0.0)\n        {\n            _1368 = (-k) / max(_1358, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _1368 = k;\n        }\n        radius = clamp(((max(zr - _1358, 0.0) * unit) * _1368) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1391 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1391; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1391;\n        float param_11 = _1271;\n        vec2 _1410 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1410 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1410) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1391);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1452 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1457 = clamp(dot(n, l), 0.0, 1.0);\n    float _1463 = sqrt(1.0 - (_1457 * _1457));\n    float _1471 = min(_1463 / max(_1457, 0.20000000298023223876953125), 4.0);\n    float _1476;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1476 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1476 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1501 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1476 * _1463)), 1.0);\n    float _1508 = _1501.x;\n    bool _1511 = _1508 < fa_shadows[ci * 1 + 16].x;\n    bool _1520;\n    if (!_1511)\n    {\n        _1520 = _1508 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1520 = _1511;\n    }\n    bool _1529;\n    if (!_1520)\n    {\n        _1529 = _1501.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1529 = _1520;\n    }\n    bool _1538;\n    if (!_1529)\n    {\n        _1538 = _1501.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1538 = _1529;\n    }\n    bool _1545;\n    if (!_1538)\n    {\n        _1545 = _1501.z > 1.0;\n    }\n    else\n    {\n        _1545 = _1538;\n    }\n    if (_1545)\n    {\n        return -1.0;\n    }\n    float _1553;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1553 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1553 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1501.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1501.z - ((_1553 * (1.0 + (0.5 * _1471))) / _1452);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1452;\n    float param_5 = _1452 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1471, 3.0)) * 0.5) / _1452;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1931 = int(fa_shadows[25].x + 0.5);\n    if (_1931 < 1)\n    {\n        return 1.0;\n    }\n    float _1946 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1931 - 1;\n    if (_1946 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1958 = _1931 > 1;\n    bool _1965;\n    if (_1958)\n    {\n        _1965 = _1946 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1965 = _1958;\n    }\n    if (_1965)\n    {\n        ci = 1;\n    }\n    bool _1969 = _1931 > 2;\n    bool _1976;\n    if (_1969)\n    {\n        _1976 = _1946 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1976 = _1969;\n    }\n    if (_1976)\n    {\n        ci = 2;\n    }\n    bool _1980 = _1931 > 3;\n    bool _1987;\n    if (_1980)\n    {\n        _1987 = _1946 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1987 = _1980;\n    }\n    if (_1987)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1931)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2013 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2013;\n        if (_2013 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2038;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2038 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2038 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2057 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2038, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2068 = clamp((_1946 - (fa_shadow_split_at(param_7) - _2057)) / _2057, 0.0, 1.0);\n        if (_2068 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1931)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2089 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2089;\n                if (_2089 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2068);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _1611 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1618;\n    if (!_1611)\n    {\n        _1618 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1618 = _1611;\n    }\n    if (_1618)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1631 = fa_light_texel(param);\n    float _1632 = _1631.x;\n    if (_1632 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1641 = int(_1632 + 0.5);\n    int param_1 = _1641;\n    vec4 _1645 = fa_light_texel(param_1);\n    int param_2 = _1641 + 1;\n    vec4 _1650 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1653 = _1645.y;\n    if (_1653 > 0.0)\n    {\n        float _1670 = 1.0 - smoothstep(0.75 * _1653, _1653, length(world - fa_shadows[27].xyz));\n        fade = _1670;\n        if (_1670 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1645.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _1694 = (_1641 + 2) + (face * 6);\n    int param_4 = _1694;\n    int param_5 = _1694 + 1;\n    int param_6 = _1694 + 3;\n    vec4 _1708 = fa_light_texel(param_6);\n    int param_7 = _1694 + 4;\n    vec4 _1713 = fa_light_texel(param_7);\n    int param_8 = _1694 + 5;\n    vec4 _1718 = fa_light_texel(param_8);\n    float _1730 = _1718.x * max(dot(_1708, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1735 = clamp(dot(n, l), 0.0, 1.0);\n    float _1758 = clamp(dot(n, _1708.xyz), -1.0, 1.0);\n    float _1777 = min(sqrt(1.0 - (_1758 * _1758)) / max(abs(dot(n, world - lpos)) / max(dot(_1708, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1780 = _1650.y;\n    float _1782;\n    if (_1780 > 0.0)\n    {\n        _1782 = _1780;\n    }\n    else\n    {\n        _1782 = 1.5 * _1730;\n    }\n    vec4 _1802 = vec4(world + (n * (_1782 * sqrt(1.0 - (_1735 * _1735)))), 1.0);\n    float _1806 = dot(_1708, _1802);\n    float _1809 = _1718.y;\n    if (_1806 < _1809)\n    {\n        return 1.0;\n    }\n    vec2 _1824 = vec2(dot(fa_light_texel(param_4), _1802), dot(fa_light_texel(param_5), _1802)) / vec2(_1806);\n    float _1826 = _1824.x;\n    bool _1829 = _1826 < _1713.x;\n    bool _1838;\n    if (!_1829)\n    {\n        _1838 = _1826 > _1713.z;\n    }\n    else\n    {\n        _1838 = _1829;\n    }\n    bool _1847;\n    if (!_1838)\n    {\n        _1847 = _1824.y < _1713.y;\n    }\n    else\n    {\n        _1847 = _1838;\n    }\n    bool _1856;\n    if (!_1847)\n    {\n        _1856 = _1824.y > _1713.w;\n    }\n    else\n    {\n        _1856 = _1847;\n    }\n    if (_1856)\n    {\n        return 1.0;\n    }\n    float _1862 = _1650.x;\n    float _1864;\n    if (_1862 > 0.0)\n    {\n        _1864 = _1862;\n    }\n    else\n    {\n        _1864 = 1.5 * _1730;\n    }\n    vec2 param_9 = _1824;\n    vec4 param_10 = _1713;\n    float param_11 = _1806 - (_1864 * (1.0 + (0.5 * _1777)));\n    float param_12 = _1730;\n    float param_13 = 1.0;\n    float param_14 = _1718.z * 0.25;\n    float param_15 = (_1730 * min(_1777, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1809, _1718.z);\n    int param_17 = int(_1645.z + 0.5);\n    float param_18 = _1645.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = gn;\n    LightSample _2130 = fa_light_sample_n(param, param_1, param_2);\n    vec3 _2513 = _2130.color;\n    float _2515 = _2130.shadow;\n    if ((_2130.type == 0) && (li == 0))\n    {\n        vec4 param_3 = coord;\n        vec3 param_4 = gn;\n        vec3 param_5 = _2130.direction;\n        float _2146 = fa_shadow(param_3, param_4, param_5);\n        _2515 = _2146;\n        _2513 *= _2146;\n    }\n    else\n    {\n        bool _2157 = _2130.type != 0;\n        bool _2163;\n        if (_2157)\n        {\n            _2163 = _2130.attenuation > 0.0;\n        }\n        else\n        {\n            _2163 = _2157;\n        }\n        if (_2163)\n        {\n            int param_6 = li;\n            int param_7 = fa_light_base(param_6);\n            int param_8 = li;\n            vec3 param_9 = fa_light_texel(param_7).xyz;\n            vec3 param_10 = world_pos;\n            vec3 param_11 = gn;\n            vec3 param_12 = _2130.direction;\n            float _2182 = fa_shadow_local(param_8, param_9, param_10, param_11, param_12);\n            _2515 = _2182;\n            _2513 *= _2182;\n        }\n    }\n    return LightSample(_2130.direction, _2513, _2130.attenuation, _2515, _2130._distance, _2130.type);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _2195 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2202;\n    if (!_2195)\n    {\n        _2202 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2202 = _2195;\n    }\n    if (_2202)\n    {\n        vec3 _2210 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _2217 = dot(_2210, fa_mesh_fs_params[9].xyz);\n        bool _2221 = fa_mesh_fs_params[9].w > 0.5;\n        float _2222;\n        if (_2221)\n        {\n            _2222 = _2217;\n        }\n        else\n        {\n            _2222 = length(_2210);\n        }\n        float _2234 = _2222 - fa_mesh_fs_params[8].x;\n        if (_2234 > 0.0)\n        {\n            float _2243 = fa_mesh_fs_params[7].w * _2234;\n            float tau = _2243 * _2243;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2259;\n                if (_2221)\n                {\n                    _2259 = world_pos.y - (fa_mesh_fs_params[9].y * _2217);\n                }\n                else\n                {\n                    _2259 = fa_mesh_fs_params[0].y;\n                }\n                float _2280 = mix(_2259, world_pos.y, clamp(fa_mesh_fs_params[8].x / _2222, 0.0, 1.0));\n                float _2284 = world_pos.y - _2280;\n                float _2289 = _2280 - fa_mesh_fs_params[8].z;\n                float _2294 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2297 = _2289 <= 0.0;\n                bool _2298 = !_2297;\n                bool _2304;\n                if (_2298)\n                {\n                    _2304 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2304 = _2297;\n                }\n                float _2305;\n                if (_2304)\n                {\n                    _2305 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2305 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2289, 80.0));\n                }\n                bool _2332;\n                if (_2298)\n                {\n                    _2332 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2332 = _2297;\n                }\n                float _2333;\n                if (_2332)\n                {\n                    _2333 = fa_mesh_fs_params[8].y * _2289;\n                }\n                else\n                {\n                    _2333 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2289, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2358 = _2294 <= 0.0;\n                bool _2365;\n                if (!_2358)\n                {\n                    _2365 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2365 = _2358;\n                }\n                float _2366;\n                if (_2365)\n                {\n                    _2366 = fa_mesh_fs_params[8].y * _2294;\n                }\n                else\n                {\n                    _2366 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2294, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2393;\n                if (abs(_2284) < 0.001000000047497451305389404296875)\n                {\n                    _2393 = _2305;\n                }\n                else\n                {\n                    _2393 = (_2366 - _2333) / _2284;\n                }\n                tau += (_2234 * max(_2393, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _2431 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _2431;\n        vec4 param_3 = v_shadow;\n        LightSample _2463 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _2463.color) * max(dot(_2431, _2463.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _2486 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_2486, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_1174",
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
            "inst_name": "_2438",
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
