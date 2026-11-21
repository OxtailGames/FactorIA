{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "26464fc4f0156798f051141dabd7d8611900aa98ee6aafc1e1d138e30acccf17",
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
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_light_atlas_fa_env_smp;\nlayout(binding = 2) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_full_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_full_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _377 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _390 = (c - (ru * hx)) - p;\n        vec3 _396 = ru * (2.0 * hx);\n        float _402 = max(dot(_396, _396), 9.9999999392252902907785028219223e-09);\n        float _406 = dot(_390, _396);\n        float t = clamp((-_406) / _402, 0.0, 1.0);\n        if (_377)\n        {\n            float _421 = dot(r, _396);\n            float _427 = _402 - (_421 * _421);\n            if (abs(_427) > (9.9999997473787516355514526367188e-06 * _402))\n            {\n                t = clamp(((dot(r, _390) * _421) - _406) / _427, 0.0, 1.0);\n            }\n        }\n        return (p + _390) + (_396 * t);\n    }\n    vec3 q = p;\n    float _459 = dot(r, axis);\n    bool _467;\n    if (_377)\n    {\n        _467 = abs(_459) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _467 = _377;\n    }\n    if (_467)\n    {\n        float _477 = dot(c - p, axis) / _459;\n        if (_477 > 0.0)\n        {\n            q = p + (r * _477);\n        }\n    }\n    vec3 _490 = q - c;\n    vec2 xy = vec2(dot(_490, ru), dot(_490, uu));\n    if (shape > 0.5)\n    {\n        float _505 = length(xy);\n        if (_505 > hx)\n        {\n            xy *= (hx / _505);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _155 = abs(d);\n    float _160 = _155.x;\n    float _163 = _155.y;\n    bool _164 = _160 >= _163;\n    bool _173;\n    if (_164)\n    {\n        _173 = _160 >= _155.z;\n    }\n    else\n    {\n        _173 = _164;\n    }\n    int _174;\n    if (_173)\n    {\n        _174 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _190;\n        if (_163 >= _155.z)\n        {\n            _190 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _190 = (d.z > 0.0) ? 4 : 5;\n        }\n        _174 = _190;\n    }\n    return _174;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _295 = dot(d, right);\n    float _299 = dot(d, up);\n    float _310;\n    if (((_295 * _295) + (_299 * _299)) > 1.0000000133514319600180897396058e-10)\n    {\n        _310 = atan(_299, _295) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _310 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_310 - floor(_310)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _543 = fa_light_base(param);\n    bool _547 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _543;\n    vec4 _551 = fa_light_texel(param_1);\n    int param_2 = _543 + 1;\n    vec4 _556 = fa_light_texel(param_2);\n    float _559 = _556.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _571 = _547 && (_559 > 2.5);\n    fa_light_is_area = _571;\n    bool _573 = _559 < 0.5;\n    vec3 l;\n    if (_573)\n    {\n        l = normalize(_551.xyz);\n        if (_547)\n        {\n            int param_3 = _543 + 6;\n            vec4 _588 = fa_light_texel(param_3);\n            if (_588.z > 0.5)\n            {\n                int param_4 = _543 + 4;\n                vec4 _598 = fa_light_texel(param_4);\n                int param_5 = _543 + 5;\n                vec4 _603 = fa_light_texel(param_5);\n                vec2 param_6 = _588.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _598.xyz) * _598.w, (-dot(world_pos, _603.xyz)) * _603.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _633 = _551.xyz;\n        vec3 _635 = _633 - world_pos;\n        vec3 to_light = _635;\n        float _638 = length(_635);\n        float reach = _638;\n        bool front = true;\n        if (_571)\n        {\n            int param_8 = _543 + 7;\n            reach = max(_638 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _543 + 4;\n            vec4 _662 = fa_light_texel(param_9);\n            int param_10 = _543 + 5;\n            vec4 _667 = fa_light_texel(param_10);\n            int param_11 = _543 + 6;\n            vec4 _672 = fa_light_texel(param_11);\n            float _673 = _672.w;\n            int param_12 = _543 + 2;\n            vec3 _680 = normalize(fa_light_texel(param_12).xyz);\n            bool _682 = _673 > 1.5;\n            bool _690;\n            if (!_682)\n            {\n                _690 = dot(_680, to_light) < 0.0;\n            }\n            else\n            {\n                _690 = _682;\n            }\n            front = _690;\n            vec3 r = vec3(0.0);\n            vec3 _699 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _703 = dot(n, n) > 0.5;\n            bool _711;\n            if (_703)\n            {\n                _711 = dot(_699, _699) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _711 = _703;\n            }\n            if (_711)\n            {\n                r = reflect(-normalize(_699), normalize(n));\n            }\n            vec3 param_13 = _633;\n            vec3 param_14 = _680;\n            vec3 param_15 = _662.xyz;\n            vec3 param_16 = _667.xyz;\n            float param_17 = _662.w;\n            float param_18 = _667.w;\n            float param_19 = _673;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _747 = length(to_light);\n        dist = _747;\n        l = to_light / vec3(max(_747, 9.9999997473787516355514526367188e-05));\n        float _761 = reach / max(_551.w, 0.001000000047497451305389404296875);\n        float _767 = clamp(1.0 - (_761 * _761), 0.0, 1.0);\n        float _769;\n        if (front)\n        {\n            _769 = _767 * _767;\n        }\n        else\n        {\n            _769 = 0.0;\n        }\n        atten = _769;\n        bool _780 = _559 < 2.5;\n        if ((_559 > 1.5) && _780)\n        {\n            int param_22 = _543 + 2;\n            vec4 _788 = fa_light_texel(param_22);\n            float _798 = _788.w;\n            int param_23 = _543 + 3;\n            vec4 _803 = fa_light_texel(param_23);\n            float _804 = _803.x;\n            float cos_inner = _804;\n            if (_804 > 1.5)\n            {\n                cos_inner = mix(_798, 1.0, 0.25);\n            }\n            atten *= smoothstep(_798, cos_inner, dot(-l, normalize(_788.xyz)));\n        }\n        if (_547 && (_559 < 1.5))\n        {\n            int param_24 = _543 + 6;\n            vec4 _828 = fa_light_texel(param_24);\n            if (_828.z > 0.5)\n            {\n                vec3 _836 = -to_light;\n                int param_25 = _543 + 4;\n                int param_26 = _543 + 5;\n                vec3 _850 = fa_light_texel(param_25).xyz;\n                vec3 _854 = fa_light_texel(param_26).xyz;\n                vec3 _863 = vec3(dot(_836, _850), dot(_836, _854), dot(_836, cross(_850, _854)));\n                vec3 param_27 = _863;\n                int _867 = fa_cube_face(param_27);\n                int param_28 = _867;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _894 = vec2(dot(_863, cross(param_29, param_30)), dot(_863, param_30)) / vec2(max(dot(_863, param_29), 9.9999997473787516355514526367188e-05));\n                int _898 = _867 / 3;\n                vec2 param_31 = _828.xy + (vec2(float(_867 - (_898 * 3)), float(_898)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _894.x), 0.5 - (0.5 * _894.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _543 + 7;\n            vec4 _928 = fa_light_texel(param_33);\n            if (_928.z > 0.5)\n            {\n                int param_34 = _543 + 2;\n                int param_35 = _543 + 4;\n                int param_36 = _543 + 5;\n                vec2 param_37 = _928.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_547 && _780)\n            {\n                int param_42 = _543 + 6;\n                vec4 _975 = fa_light_texel(param_42);\n                int param_43 = _543 + 7;\n                vec4 _980 = fa_light_texel(param_43);\n                bool _983 = _975.z > 0.5;\n                bool _990;\n                if (!_983)\n                {\n                    _990 = _980.z > 0.5;\n                }\n                else\n                {\n                    _990 = _983;\n                }\n                if (_990)\n                {\n                    int param_44 = _543 + 2;\n                    vec4 _997 = fa_light_texel(param_44);\n                    vec3 _1001 = normalize(_997.xyz);\n                    int param_45 = _543 + 4;\n                    vec4 _1006 = fa_light_texel(param_45);\n                    int param_46 = _543 + 5;\n                    vec4 _1011 = fa_light_texel(param_46);\n                    if (_983)\n                    {\n                        vec3 _1019 = -to_light;\n                        float _1026 = _997.w;\n                        float _1042 = 0.5 / max(dot(_1019, _1001) * (sqrt(max(1.0 - (_1026 * _1026), 0.0)) / max(_1026, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _975.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1019, _1006.xyz) * _1042), 0.5 - (dot(_1019, _1011.xyz) * _1042));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_980.z > 0.5)\n                    {\n                        vec2 param_49 = _980.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1001;\n                        vec3 param_52 = _1006.xyz;\n                        vec3 param_53 = _1011.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _2500 = _556.xyz * atten;\n    if (_547)\n    {\n        _2500 *= fa_light_tint;\n    }\n    int _1111;\n    if (_573)\n    {\n        _1111 = 0;\n    }\n    else\n    {\n        _1111 = ((_559 > 1.5) && (_559 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _2500, atten, 1.0, dist, _1111);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1166;\n    if (i == 0)\n    {\n        _1166 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1182;\n        if (i == 1)\n        {\n            _1182 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1190;\n            if (i == 2)\n            {\n                _1190 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1190 = fa_shadows[24].w;\n            }\n            _1182 = _1190;\n        }\n        _1166 = _1182;\n    }\n    return _1166;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1223 = fa_shadow_depth(param, param_1);\n    float _1227;\n    if (conv.x < 0.5)\n    {\n        _1227 = _1223;\n    }\n    else\n    {\n        _1227 = (conv.y * conv.z) / (conv.z - (_1223 * (conv.z - conv.y)));\n    }\n    return _1227;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1154 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1154), sin(_1154)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1273 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1282;\n        if (k < 0.0)\n        {\n            _1282 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _1282 = k;\n        }\n        float _1302 = clamp((_1282 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1273;\n            vec2 _1322 = fa_shadow_vogel(param_3, param_4, param_5) * _1302;\n            vec2 param_6 = uv + (_1322 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1334 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1334 < (zr - (length(_1322) * plane)))\n            {\n                sum += _1334;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _1360 = sum / cnt;\n        float _1370;\n        if (k < 0.0)\n        {\n            _1370 = (-k) / max(_1360, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _1370 = k;\n        }\n        radius = clamp(((max(zr - _1360, 0.0) * unit) * _1370) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1393 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1393; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1393;\n        float param_11 = _1273;\n        vec2 _1412 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1412 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1412) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1393);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1454 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1459 = clamp(dot(n, l), 0.0, 1.0);\n    float _1465 = sqrt(1.0 - (_1459 * _1459));\n    float _1473 = min(_1465 / max(_1459, 0.20000000298023223876953125), 4.0);\n    float _1478;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1478 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1478 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1503 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1478 * _1465)), 1.0);\n    float _1510 = _1503.x;\n    bool _1513 = _1510 < fa_shadows[ci * 1 + 16].x;\n    bool _1522;\n    if (!_1513)\n    {\n        _1522 = _1510 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1522 = _1513;\n    }\n    bool _1531;\n    if (!_1522)\n    {\n        _1531 = _1503.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1531 = _1522;\n    }\n    bool _1540;\n    if (!_1531)\n    {\n        _1540 = _1503.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1540 = _1531;\n    }\n    bool _1547;\n    if (!_1540)\n    {\n        _1547 = _1503.z > 1.0;\n    }\n    else\n    {\n        _1547 = _1540;\n    }\n    if (_1547)\n    {\n        return -1.0;\n    }\n    float _1555;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1555 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1555 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1503.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1503.z - ((_1555 * (1.0 + (0.5 * _1473))) / _1454);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1454;\n    float param_5 = _1454 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1473, 3.0)) * 0.5) / _1454;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1933 = int(fa_shadows[25].x + 0.5);\n    if (_1933 < 1)\n    {\n        return 1.0;\n    }\n    float _1948 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1933 - 1;\n    if (_1948 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1960 = _1933 > 1;\n    bool _1967;\n    if (_1960)\n    {\n        _1967 = _1948 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1967 = _1960;\n    }\n    if (_1967)\n    {\n        ci = 1;\n    }\n    bool _1971 = _1933 > 2;\n    bool _1978;\n    if (_1971)\n    {\n        _1978 = _1948 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1978 = _1971;\n    }\n    if (_1978)\n    {\n        ci = 2;\n    }\n    bool _1982 = _1933 > 3;\n    bool _1989;\n    if (_1982)\n    {\n        _1989 = _1948 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1989 = _1982;\n    }\n    if (_1989)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1933)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2015 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2015;\n        if (_2015 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2040;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2040 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2040 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2059 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2040, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2070 = clamp((_1948 - (fa_shadow_split_at(param_7) - _2059)) / _2059, 0.0, 1.0);\n        if (_2070 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1933)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2091 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2091;\n                if (_2091 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2070);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _1613 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    if (_1620)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1633 = fa_light_texel(param);\n    float _1634 = _1633.x;\n    if (_1634 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1643 = int(_1634 + 0.5);\n    int param_1 = _1643;\n    vec4 _1647 = fa_light_texel(param_1);\n    int param_2 = _1643 + 1;\n    vec4 _1652 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1655 = _1647.y;\n    if (_1655 > 0.0)\n    {\n        float _1672 = 1.0 - smoothstep(0.75 * _1655, _1655, length(world - fa_shadows[27].xyz));\n        fade = _1672;\n        if (_1672 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1647.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _1696 = (_1643 + 2) + (face * 6);\n    int param_4 = _1696;\n    int param_5 = _1696 + 1;\n    int param_6 = _1696 + 3;\n    vec4 _1710 = fa_light_texel(param_6);\n    int param_7 = _1696 + 4;\n    vec4 _1715 = fa_light_texel(param_7);\n    int param_8 = _1696 + 5;\n    vec4 _1720 = fa_light_texel(param_8);\n    float _1732 = _1720.x * max(dot(_1710, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1737 = clamp(dot(n, l), 0.0, 1.0);\n    float _1760 = clamp(dot(n, _1710.xyz), -1.0, 1.0);\n    float _1779 = min(sqrt(1.0 - (_1760 * _1760)) / max(abs(dot(n, world - lpos)) / max(dot(_1710, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1782 = _1652.y;\n    float _1784;\n    if (_1782 > 0.0)\n    {\n        _1784 = _1782;\n    }\n    else\n    {\n        _1784 = 1.5 * _1732;\n    }\n    vec4 _1804 = vec4(world + (n * (_1784 * sqrt(1.0 - (_1737 * _1737)))), 1.0);\n    float _1808 = dot(_1710, _1804);\n    float _1811 = _1720.y;\n    if (_1808 < _1811)\n    {\n        return 1.0;\n    }\n    vec2 _1826 = vec2(dot(fa_light_texel(param_4), _1804), dot(fa_light_texel(param_5), _1804)) / vec2(_1808);\n    float _1828 = _1826.x;\n    bool _1831 = _1828 < _1715.x;\n    bool _1840;\n    if (!_1831)\n    {\n        _1840 = _1828 > _1715.z;\n    }\n    else\n    {\n        _1840 = _1831;\n    }\n    bool _1849;\n    if (!_1840)\n    {\n        _1849 = _1826.y < _1715.y;\n    }\n    else\n    {\n        _1849 = _1840;\n    }\n    bool _1858;\n    if (!_1849)\n    {\n        _1858 = _1826.y > _1715.w;\n    }\n    else\n    {\n        _1858 = _1849;\n    }\n    if (_1858)\n    {\n        return 1.0;\n    }\n    float _1864 = _1652.x;\n    float _1866;\n    if (_1864 > 0.0)\n    {\n        _1866 = _1864;\n    }\n    else\n    {\n        _1866 = 1.5 * _1732;\n    }\n    vec2 param_9 = _1826;\n    vec4 param_10 = _1715;\n    float param_11 = _1808 - (_1866 * (1.0 + (0.5 * _1779)));\n    float param_12 = _1732;\n    float param_13 = 1.0;\n    float param_14 = _1720.z * 0.25;\n    float param_15 = (_1732 * min(_1779, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1811, _1720.z);\n    int param_17 = int(_1647.z + 0.5);\n    float param_18 = _1647.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = gn;\n    LightSample _2132 = fa_light_sample_n(param, param_1, param_2);\n    vec3 _2513 = _2132.color;\n    float _2515 = _2132.shadow;\n    if ((_2132.type == 0) && (li == 0))\n    {\n        vec4 param_3 = coord;\n        vec3 param_4 = gn;\n        vec3 param_5 = _2132.direction;\n        float _2148 = fa_shadow(param_3, param_4, param_5);\n        _2515 = _2148;\n        _2513 *= _2148;\n    }\n    else\n    {\n        bool _2159 = _2132.type != 0;\n        bool _2165;\n        if (_2159)\n        {\n            _2165 = _2132.attenuation > 0.0;\n        }\n        else\n        {\n            _2165 = _2159;\n        }\n        if (_2165)\n        {\n            int param_6 = li;\n            int param_7 = fa_light_base(param_6);\n            int param_8 = li;\n            vec3 param_9 = fa_light_texel(param_7).xyz;\n            vec3 param_10 = world_pos;\n            vec3 param_11 = gn;\n            vec3 param_12 = _2132.direction;\n            float _2184 = fa_shadow_local(param_8, param_9, param_10, param_11, param_12);\n            _2515 = _2184;\n            _2513 *= _2184;\n        }\n    }\n    return LightSample(_2132.direction, _2513, _2132.attenuation, _2515, _2132._distance, _2132.type);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _2197 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2204;\n    if (!_2197)\n    {\n        _2204 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2204 = _2197;\n    }\n    if (_2204)\n    {\n        vec3 _2212 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _2219 = dot(_2212, fa_mesh_fs_params[9].xyz);\n        bool _2223 = fa_mesh_fs_params[9].w > 0.5;\n        float _2224;\n        if (_2223)\n        {\n            _2224 = _2219;\n        }\n        else\n        {\n            _2224 = length(_2212);\n        }\n        float _2236 = _2224 - fa_mesh_fs_params[8].x;\n        if (_2236 > 0.0)\n        {\n            float _2245 = fa_mesh_fs_params[7].w * _2236;\n            float tau = _2245 * _2245;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2261;\n                if (_2223)\n                {\n                    _2261 = world_pos.y - (fa_mesh_fs_params[9].y * _2219);\n                }\n                else\n                {\n                    _2261 = fa_mesh_fs_params[0].y;\n                }\n                float _2282 = mix(_2261, world_pos.y, clamp(fa_mesh_fs_params[8].x / _2224, 0.0, 1.0));\n                float _2286 = world_pos.y - _2282;\n                float _2291 = _2282 - fa_mesh_fs_params[8].z;\n                float _2296 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2299 = _2291 <= 0.0;\n                bool _2300 = !_2299;\n                bool _2306;\n                if (_2300)\n                {\n                    _2306 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2306 = _2299;\n                }\n                float _2307;\n                if (_2306)\n                {\n                    _2307 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2307 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2291, 80.0));\n                }\n                bool _2334;\n                if (_2300)\n                {\n                    _2334 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2334 = _2299;\n                }\n                float _2335;\n                if (_2334)\n                {\n                    _2335 = fa_mesh_fs_params[8].y * _2291;\n                }\n                else\n                {\n                    _2335 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2291, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2360 = _2296 <= 0.0;\n                bool _2367;\n                if (!_2360)\n                {\n                    _2367 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2367 = _2360;\n                }\n                float _2368;\n                if (_2367)\n                {\n                    _2368 = fa_mesh_fs_params[8].y * _2296;\n                }\n                else\n                {\n                    _2368 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2296, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2395;\n                if (abs(_2286) < 0.001000000047497451305389404296875)\n                {\n                    _2395 = _2307;\n                }\n                else\n                {\n                    _2395 = (_2368 - _2335) / _2286;\n                }\n                tau += (_2236 * max(_2395, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _2433 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _2433;\n        vec4 param_3 = v_shadow;\n        LightSample _2465 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _2465.color) * max(dot(_2433, _2465.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _2488 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_2488, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_1176",
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
            "inst_name": "_2440",
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
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_light_tex_fa_full_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_full_light_atlas_fa_env_smp;\nlayout(binding = 2) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_full_light_tex_fa_full_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_full_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_full_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _377 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _390 = (c - (ru * hx)) - p;\n        vec3 _396 = ru * (2.0 * hx);\n        float _402 = max(dot(_396, _396), 9.9999999392252902907785028219223e-09);\n        float _406 = dot(_390, _396);\n        float t = clamp((-_406) / _402, 0.0, 1.0);\n        if (_377)\n        {\n            float _421 = dot(r, _396);\n            float _427 = _402 - (_421 * _421);\n            if (abs(_427) > (9.9999997473787516355514526367188e-06 * _402))\n            {\n                t = clamp(((dot(r, _390) * _421) - _406) / _427, 0.0, 1.0);\n            }\n        }\n        return (p + _390) + (_396 * t);\n    }\n    vec3 q = p;\n    float _459 = dot(r, axis);\n    bool _467;\n    if (_377)\n    {\n        _467 = abs(_459) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _467 = _377;\n    }\n    if (_467)\n    {\n        float _477 = dot(c - p, axis) / _459;\n        if (_477 > 0.0)\n        {\n            q = p + (r * _477);\n        }\n    }\n    vec3 _490 = q - c;\n    vec2 xy = vec2(dot(_490, ru), dot(_490, uu));\n    if (shape > 0.5)\n    {\n        float _505 = length(xy);\n        if (_505 > hx)\n        {\n            xy *= (hx / _505);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _155 = abs(d);\n    float _160 = _155.x;\n    float _163 = _155.y;\n    bool _164 = _160 >= _163;\n    bool _173;\n    if (_164)\n    {\n        _173 = _160 >= _155.z;\n    }\n    else\n    {\n        _173 = _164;\n    }\n    int _174;\n    if (_173)\n    {\n        _174 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _190;\n        if (_163 >= _155.z)\n        {\n            _190 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _190 = (d.z > 0.0) ? 4 : 5;\n        }\n        _174 = _190;\n    }\n    return _174;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _295 = dot(d, right);\n    float _299 = dot(d, up);\n    float _310;\n    if (((_295 * _295) + (_299 * _299)) > 1.0000000133514319600180897396058e-10)\n    {\n        _310 = atan(_299, _295) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _310 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_310 - floor(_310)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _543 = fa_light_base(param);\n    bool _547 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _543;\n    vec4 _551 = fa_light_texel(param_1);\n    int param_2 = _543 + 1;\n    vec4 _556 = fa_light_texel(param_2);\n    float _559 = _556.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _571 = _547 && (_559 > 2.5);\n    fa_light_is_area = _571;\n    bool _573 = _559 < 0.5;\n    vec3 l;\n    if (_573)\n    {\n        l = normalize(_551.xyz);\n        if (_547)\n        {\n            int param_3 = _543 + 6;\n            vec4 _588 = fa_light_texel(param_3);\n            if (_588.z > 0.5)\n            {\n                int param_4 = _543 + 4;\n                vec4 _598 = fa_light_texel(param_4);\n                int param_5 = _543 + 5;\n                vec4 _603 = fa_light_texel(param_5);\n                vec2 param_6 = _588.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _598.xyz) * _598.w, (-dot(world_pos, _603.xyz)) * _603.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _633 = _551.xyz;\n        vec3 _635 = _633 - world_pos;\n        vec3 to_light = _635;\n        float _638 = length(_635);\n        float reach = _638;\n        bool front = true;\n        if (_571)\n        {\n            int param_8 = _543 + 7;\n            reach = max(_638 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _543 + 4;\n            vec4 _662 = fa_light_texel(param_9);\n            int param_10 = _543 + 5;\n            vec4 _667 = fa_light_texel(param_10);\n            int param_11 = _543 + 6;\n            vec4 _672 = fa_light_texel(param_11);\n            float _673 = _672.w;\n            int param_12 = _543 + 2;\n            vec3 _680 = normalize(fa_light_texel(param_12).xyz);\n            bool _682 = _673 > 1.5;\n            bool _690;\n            if (!_682)\n            {\n                _690 = dot(_680, to_light) < 0.0;\n            }\n            else\n            {\n                _690 = _682;\n            }\n            front = _690;\n            vec3 r = vec3(0.0);\n            vec3 _699 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _703 = dot(n, n) > 0.5;\n            bool _711;\n            if (_703)\n            {\n                _711 = dot(_699, _699) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _711 = _703;\n            }\n            if (_711)\n            {\n                r = reflect(-normalize(_699), normalize(n));\n            }\n            vec3 param_13 = _633;\n            vec3 param_14 = _680;\n            vec3 param_15 = _662.xyz;\n            vec3 param_16 = _667.xyz;\n            float param_17 = _662.w;\n            float param_18 = _667.w;\n            float param_19 = _673;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _747 = length(to_light);\n        dist = _747;\n        l = to_light / vec3(max(_747, 9.9999997473787516355514526367188e-05));\n        float _761 = reach / max(_551.w, 0.001000000047497451305389404296875);\n        float _767 = clamp(1.0 - (_761 * _761), 0.0, 1.0);\n        float _769;\n        if (front)\n        {\n            _769 = _767 * _767;\n        }\n        else\n        {\n            _769 = 0.0;\n        }\n        atten = _769;\n        bool _780 = _559 < 2.5;\n        if ((_559 > 1.5) && _780)\n        {\n            int param_22 = _543 + 2;\n            vec4 _788 = fa_light_texel(param_22);\n            float _798 = _788.w;\n            int param_23 = _543 + 3;\n            vec4 _803 = fa_light_texel(param_23);\n            float _804 = _803.x;\n            float cos_inner = _804;\n            if (_804 > 1.5)\n            {\n                cos_inner = mix(_798, 1.0, 0.25);\n            }\n            atten *= smoothstep(_798, cos_inner, dot(-l, normalize(_788.xyz)));\n        }\n        if (_547 && (_559 < 1.5))\n        {\n            int param_24 = _543 + 6;\n            vec4 _828 = fa_light_texel(param_24);\n            if (_828.z > 0.5)\n            {\n                vec3 _836 = -to_light;\n                int param_25 = _543 + 4;\n                int param_26 = _543 + 5;\n                vec3 _850 = fa_light_texel(param_25).xyz;\n                vec3 _854 = fa_light_texel(param_26).xyz;\n                vec3 _863 = vec3(dot(_836, _850), dot(_836, _854), dot(_836, cross(_850, _854)));\n                vec3 param_27 = _863;\n                int _867 = fa_cube_face(param_27);\n                int param_28 = _867;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _894 = vec2(dot(_863, cross(param_29, param_30)), dot(_863, param_30)) / vec2(max(dot(_863, param_29), 9.9999997473787516355514526367188e-05));\n                int _898 = _867 / 3;\n                vec2 param_31 = _828.xy + (vec2(float(_867 - (_898 * 3)), float(_898)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _894.x), 0.5 - (0.5 * _894.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _543 + 7;\n            vec4 _928 = fa_light_texel(param_33);\n            if (_928.z > 0.5)\n            {\n                int param_34 = _543 + 2;\n                int param_35 = _543 + 4;\n                int param_36 = _543 + 5;\n                vec2 param_37 = _928.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_547 && _780)\n            {\n                int param_42 = _543 + 6;\n                vec4 _975 = fa_light_texel(param_42);\n                int param_43 = _543 + 7;\n                vec4 _980 = fa_light_texel(param_43);\n                bool _983 = _975.z > 0.5;\n                bool _990;\n                if (!_983)\n                {\n                    _990 = _980.z > 0.5;\n                }\n                else\n                {\n                    _990 = _983;\n                }\n                if (_990)\n                {\n                    int param_44 = _543 + 2;\n                    vec4 _997 = fa_light_texel(param_44);\n                    vec3 _1001 = normalize(_997.xyz);\n                    int param_45 = _543 + 4;\n                    vec4 _1006 = fa_light_texel(param_45);\n                    int param_46 = _543 + 5;\n                    vec4 _1011 = fa_light_texel(param_46);\n                    if (_983)\n                    {\n                        vec3 _1019 = -to_light;\n                        float _1026 = _997.w;\n                        float _1042 = 0.5 / max(dot(_1019, _1001) * (sqrt(max(1.0 - (_1026 * _1026), 0.0)) / max(_1026, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _975.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1019, _1006.xyz) * _1042), 0.5 - (dot(_1019, _1011.xyz) * _1042));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_980.z > 0.5)\n                    {\n                        vec2 param_49 = _980.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1001;\n                        vec3 param_52 = _1006.xyz;\n                        vec3 param_53 = _1011.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _2500 = _556.xyz * atten;\n    if (_547)\n    {\n        _2500 *= fa_light_tint;\n    }\n    int _1111;\n    if (_573)\n    {\n        _1111 = 0;\n    }\n    else\n    {\n        _1111 = ((_559 > 1.5) && (_559 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _2500, atten, 1.0, dist, _1111);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1166;\n    if (i == 0)\n    {\n        _1166 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1182;\n        if (i == 1)\n        {\n            _1182 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1190;\n            if (i == 2)\n            {\n                _1190 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1190 = fa_shadows[24].w;\n            }\n            _1182 = _1190;\n        }\n        _1166 = _1182;\n    }\n    return _1166;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1223 = fa_shadow_depth(param, param_1);\n    float _1227;\n    if (conv.x < 0.5)\n    {\n        _1227 = _1223;\n    }\n    else\n    {\n        _1227 = (conv.y * conv.z) / (conv.z - (_1223 * (conv.z - conv.y)));\n    }\n    return _1227;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1154 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1154), sin(_1154)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1273 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1282;\n        if (k < 0.0)\n        {\n            _1282 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _1282 = k;\n        }\n        float _1302 = clamp((_1282 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1273;\n            vec2 _1322 = fa_shadow_vogel(param_3, param_4, param_5) * _1302;\n            vec2 param_6 = uv + (_1322 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1334 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1334 < (zr - (length(_1322) * plane)))\n            {\n                sum += _1334;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _1360 = sum / cnt;\n        float _1370;\n        if (k < 0.0)\n        {\n            _1370 = (-k) / max(_1360, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _1370 = k;\n        }\n        radius = clamp(((max(zr - _1360, 0.0) * unit) * _1370) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1393 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1393; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1393;\n        float param_11 = _1273;\n        vec2 _1412 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1412 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1412) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1393);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1454 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1459 = clamp(dot(n, l), 0.0, 1.0);\n    float _1465 = sqrt(1.0 - (_1459 * _1459));\n    float _1473 = min(_1465 / max(_1459, 0.20000000298023223876953125), 4.0);\n    float _1478;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1478 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1478 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1503 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1478 * _1465)), 1.0);\n    float _1510 = _1503.x;\n    bool _1513 = _1510 < fa_shadows[ci * 1 + 16].x;\n    bool _1522;\n    if (!_1513)\n    {\n        _1522 = _1510 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1522 = _1513;\n    }\n    bool _1531;\n    if (!_1522)\n    {\n        _1531 = _1503.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1531 = _1522;\n    }\n    bool _1540;\n    if (!_1531)\n    {\n        _1540 = _1503.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1540 = _1531;\n    }\n    bool _1547;\n    if (!_1540)\n    {\n        _1547 = _1503.z > 1.0;\n    }\n    else\n    {\n        _1547 = _1540;\n    }\n    if (_1547)\n    {\n        return -1.0;\n    }\n    float _1555;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1555 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1555 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1503.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1503.z - ((_1555 * (1.0 + (0.5 * _1473))) / _1454);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1454;\n    float param_5 = _1454 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1473, 3.0)) * 0.5) / _1454;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1933 = int(fa_shadows[25].x + 0.5);\n    if (_1933 < 1)\n    {\n        return 1.0;\n    }\n    float _1948 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1933 - 1;\n    if (_1948 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1960 = _1933 > 1;\n    bool _1967;\n    if (_1960)\n    {\n        _1967 = _1948 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1967 = _1960;\n    }\n    if (_1967)\n    {\n        ci = 1;\n    }\n    bool _1971 = _1933 > 2;\n    bool _1978;\n    if (_1971)\n    {\n        _1978 = _1948 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1978 = _1971;\n    }\n    if (_1978)\n    {\n        ci = 2;\n    }\n    bool _1982 = _1933 > 3;\n    bool _1989;\n    if (_1982)\n    {\n        _1989 = _1948 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1989 = _1982;\n    }\n    if (_1989)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1933)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2015 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2015;\n        if (_2015 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2040;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2040 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2040 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2059 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2040, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2070 = clamp((_1948 - (fa_shadow_split_at(param_7) - _2059)) / _2059, 0.0, 1.0);\n        if (_2070 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1933)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2091 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2091;\n                if (_2091 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2070);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _1613 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    if (_1620)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1633 = fa_light_texel(param);\n    float _1634 = _1633.x;\n    if (_1634 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1643 = int(_1634 + 0.5);\n    int param_1 = _1643;\n    vec4 _1647 = fa_light_texel(param_1);\n    int param_2 = _1643 + 1;\n    vec4 _1652 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1655 = _1647.y;\n    if (_1655 > 0.0)\n    {\n        float _1672 = 1.0 - smoothstep(0.75 * _1655, _1655, length(world - fa_shadows[27].xyz));\n        fade = _1672;\n        if (_1672 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1647.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _1696 = (_1643 + 2) + (face * 6);\n    int param_4 = _1696;\n    int param_5 = _1696 + 1;\n    int param_6 = _1696 + 3;\n    vec4 _1710 = fa_light_texel(param_6);\n    int param_7 = _1696 + 4;\n    vec4 _1715 = fa_light_texel(param_7);\n    int param_8 = _1696 + 5;\n    vec4 _1720 = fa_light_texel(param_8);\n    float _1732 = _1720.x * max(dot(_1710, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1737 = clamp(dot(n, l), 0.0, 1.0);\n    float _1760 = clamp(dot(n, _1710.xyz), -1.0, 1.0);\n    float _1779 = min(sqrt(1.0 - (_1760 * _1760)) / max(abs(dot(n, world - lpos)) / max(dot(_1710, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1782 = _1652.y;\n    float _1784;\n    if (_1782 > 0.0)\n    {\n        _1784 = _1782;\n    }\n    else\n    {\n        _1784 = 1.5 * _1732;\n    }\n    vec4 _1804 = vec4(world + (n * (_1784 * sqrt(1.0 - (_1737 * _1737)))), 1.0);\n    float _1808 = dot(_1710, _1804);\n    float _1811 = _1720.y;\n    if (_1808 < _1811)\n    {\n        return 1.0;\n    }\n    vec2 _1826 = vec2(dot(fa_light_texel(param_4), _1804), dot(fa_light_texel(param_5), _1804)) / vec2(_1808);\n    float _1828 = _1826.x;\n    bool _1831 = _1828 < _1715.x;\n    bool _1840;\n    if (!_1831)\n    {\n        _1840 = _1828 > _1715.z;\n    }\n    else\n    {\n        _1840 = _1831;\n    }\n    bool _1849;\n    if (!_1840)\n    {\n        _1849 = _1826.y < _1715.y;\n    }\n    else\n    {\n        _1849 = _1840;\n    }\n    bool _1858;\n    if (!_1849)\n    {\n        _1858 = _1826.y > _1715.w;\n    }\n    else\n    {\n        _1858 = _1849;\n    }\n    if (_1858)\n    {\n        return 1.0;\n    }\n    float _1864 = _1652.x;\n    float _1866;\n    if (_1864 > 0.0)\n    {\n        _1866 = _1864;\n    }\n    else\n    {\n        _1866 = 1.5 * _1732;\n    }\n    vec2 param_9 = _1826;\n    vec4 param_10 = _1715;\n    float param_11 = _1808 - (_1866 * (1.0 + (0.5 * _1779)));\n    float param_12 = _1732;\n    float param_13 = 1.0;\n    float param_14 = _1720.z * 0.25;\n    float param_15 = (_1732 * min(_1779, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1811, _1720.z);\n    int param_17 = int(_1647.z + 0.5);\n    float param_18 = _1647.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = gn;\n    LightSample _2132 = fa_light_sample_n(param, param_1, param_2);\n    vec3 _2513 = _2132.color;\n    float _2515 = _2132.shadow;\n    if ((_2132.type == 0) && (li == 0))\n    {\n        vec4 param_3 = coord;\n        vec3 param_4 = gn;\n        vec3 param_5 = _2132.direction;\n        float _2148 = fa_shadow(param_3, param_4, param_5);\n        _2515 = _2148;\n        _2513 *= _2148;\n    }\n    else\n    {\n        bool _2159 = _2132.type != 0;\n        bool _2165;\n        if (_2159)\n        {\n            _2165 = _2132.attenuation > 0.0;\n        }\n        else\n        {\n            _2165 = _2159;\n        }\n        if (_2165)\n        {\n            int param_6 = li;\n            int param_7 = fa_light_base(param_6);\n            int param_8 = li;\n            vec3 param_9 = fa_light_texel(param_7).xyz;\n            vec3 param_10 = world_pos;\n            vec3 param_11 = gn;\n            vec3 param_12 = _2132.direction;\n            float _2184 = fa_shadow_local(param_8, param_9, param_10, param_11, param_12);\n            _2515 = _2184;\n            _2513 *= _2184;\n        }\n    }\n    return LightSample(_2132.direction, _2513, _2132.attenuation, _2515, _2132._distance, _2132.type);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _2197 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2204;\n    if (!_2197)\n    {\n        _2204 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2204 = _2197;\n    }\n    if (_2204)\n    {\n        vec3 _2212 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _2219 = dot(_2212, fa_mesh_fs_params[9].xyz);\n        bool _2223 = fa_mesh_fs_params[9].w > 0.5;\n        float _2224;\n        if (_2223)\n        {\n            _2224 = _2219;\n        }\n        else\n        {\n            _2224 = length(_2212);\n        }\n        float _2236 = _2224 - fa_mesh_fs_params[8].x;\n        if (_2236 > 0.0)\n        {\n            float _2245 = fa_mesh_fs_params[7].w * _2236;\n            float tau = _2245 * _2245;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2261;\n                if (_2223)\n                {\n                    _2261 = world_pos.y - (fa_mesh_fs_params[9].y * _2219);\n                }\n                else\n                {\n                    _2261 = fa_mesh_fs_params[0].y;\n                }\n                float _2282 = mix(_2261, world_pos.y, clamp(fa_mesh_fs_params[8].x / _2224, 0.0, 1.0));\n                float _2286 = world_pos.y - _2282;\n                float _2291 = _2282 - fa_mesh_fs_params[8].z;\n                float _2296 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2299 = _2291 <= 0.0;\n                bool _2300 = !_2299;\n                bool _2306;\n                if (_2300)\n                {\n                    _2306 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2306 = _2299;\n                }\n                float _2307;\n                if (_2306)\n                {\n                    _2307 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2307 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2291, 80.0));\n                }\n                bool _2334;\n                if (_2300)\n                {\n                    _2334 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2334 = _2299;\n                }\n                float _2335;\n                if (_2334)\n                {\n                    _2335 = fa_mesh_fs_params[8].y * _2291;\n                }\n                else\n                {\n                    _2335 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2291, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2360 = _2296 <= 0.0;\n                bool _2367;\n                if (!_2360)\n                {\n                    _2367 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2367 = _2360;\n                }\n                float _2368;\n                if (_2367)\n                {\n                    _2368 = fa_mesh_fs_params[8].y * _2296;\n                }\n                else\n                {\n                    _2368 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2296, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2395;\n                if (abs(_2286) < 0.001000000047497451305389404296875)\n                {\n                    _2395 = _2307;\n                }\n                else\n                {\n                    _2395 = (_2368 - _2335) / _2286;\n                }\n                tau += (_2236 * max(_2395, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _2433 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _2433;\n        vec4 param_3 = v_shadow;\n        LightSample _2465 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _2465.color) * max(dot(_2433, _2465.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _2488 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_2488, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_1176",
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
            "inst_name": "_2440",
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
