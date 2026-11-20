{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b612c93917ef2f2ca09ed7d7ebb5d582b3c039f51369a75c84a9a8e9083bd53a",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_mesh_fs_params[14];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 6) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1465 = fa_linear_to_srgb(param);\n        c = _1465;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1473 = fa_srgb_to_linear(param_1);\n            c = _1473;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _152;\n    if (i.front_facing)\n    {\n        _152 = i.world_normal;\n    }\n    else\n    {\n        _152 = -i.world_normal;\n    }\n    vec3 _176 = normalize(i.world_tangent.xyz - (_152 * dot(_152, i.world_tangent.xyz)));\n    vec3 _204 = normalize(((_176 * m.x) + ((cross(_152, _176) * i.world_tangent.w) * m.y)) + (_152 * m.z));\n    vec3 _207;\n    if (i.front_facing)\n    {\n        _207 = _204;\n    }\n    else\n    {\n        _207 = -_204;\n    }\n    return _207;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1504 = fa_tex_fix(param_2, param_3);\n    vec4 _2148 = base_t;\n    _2148.x = _1504.x;\n    _2148.y = _1504.y;\n    _2148.z = _1504.z;\n    base_t = _2148;\n    vec4 _1518 = (_2148 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2116 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1550 = fa_tex_fix(param_6, param_7);\n        vec3 _1554 = (_1550 * 2.0) - vec3(1.0);\n        vec2 _1559 = _1554.xy * fa_mesh_fs_params[6].x;\n        vec3 _2156 = _1554;\n        _2156.x = _1559.x;\n        _2156.y = _1559.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2156;\n        _2116 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1588 = fa_tex_fix(param_12, param_13);\n    vec4 _2159 = mrt;\n    _2159.x = _1588.x;\n    _2159.y = _1588.y;\n    _2159.z = _1588.z;\n    mrt = _2159;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1627 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1654 = fa_tex_fix(param_20, param_21);\n    return Surface(_1518.xyz, _1518.w, _2116, clamp(fa_mesh_fs_params[5].x * _1588.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1588.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1627.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1654));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _235 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_235)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _253 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _255 = length(_253);\n        dist = _255;\n        l = _253 / vec3(max(_255, 9.9999997473787516355514526367188e-05));\n        float _271 = _255 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _277 = clamp(1.0 - (_271 * _271), 0.0, 1.0);\n        atten = _277 * _277;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _328;\n    if (_235)\n    {\n        _328 = 0;\n    }\n    else\n    {\n        _328 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _328);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1305 = n < 0;\n    bool _1312;\n    if (!_1305)\n    {\n        _1312 = n >= fa_light_count();\n    }\n    else\n    {\n        _1312 = _1305;\n    }\n    if (_1312)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    vec3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _380;\n    if (i == 0)\n    {\n        _380 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _396;\n        if (i == 1)\n        {\n            _396 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _404;\n            if (i == 2)\n            {\n                _404 = fa_shadows[24].z;\n            }\n            else\n            {\n                _404 = fa_shadows[24].w;\n            }\n            _396 = _404;\n        }\n        _380 = _396;\n    }\n    return _380;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _368 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_368), sin(_368)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _448 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _453 = clamp(dot(n, l), 0.0, 1.0);\n    float _459 = sqrt(1.0 - (_453 * _453));\n    float _467 = min(_459 / max(_453, 0.20000000298023223876953125), 4.0);\n    float _472;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _472 = fa_shadows[26].y;\n    }\n    else\n    {\n        _472 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _497 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_472 * _459)), 1.0);\n    float _504 = _497.x;\n    bool _507 = _504 < fa_shadows[ci * 1 + 16].x;\n    bool _516;\n    if (!_507)\n    {\n        _516 = _504 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _516 = _507;\n    }\n    bool _525;\n    if (!_516)\n    {\n        _525 = _497.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _525 = _516;\n    }\n    bool _534;\n    if (!_525)\n    {\n        _534 = _497.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _534 = _525;\n    }\n    bool _541;\n    if (!_534)\n    {\n        _541 = _497.z > 1.0;\n    }\n    else\n    {\n        _541 = _534;\n    }\n    if (_541)\n    {\n        return -1.0;\n    }\n    float _550;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _550 = fa_shadows[26].x;\n    }\n    else\n    {\n        _550 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _569 = _497.z - ((_550 * (1.0 + (0.5 * _467))) / _448);\n    float _578 = ((fa_shadows[ci * 1 + 20].x * min(_467, 3.0)) * 0.5) / _448;\n    int _587 = int(fa_shadows[25].z + 0.5);\n    if (_587 == 1)\n    {\n        vec2 param = _497.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _598 = fa_shadow_depth(param, param_1);\n        return float(_569 <= _598);\n    }\n    float _605 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _608 = _587 == 2;\n    if (_608)\n    {\n        float _622 = clamp(((fa_shadows[25].w * _448) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _605;\n            vec2 _642 = fa_shadow_vogel(param_2, param_3, param_4) * _622;\n            vec2 param_5 = _497.xy + (_642 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _653 = fa_shadow_depth(param_5, param_6);\n            if (_653 < (_569 - (length(_642) * _578)))\n            {\n                sum += _653;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_569 - (sum / cnt), 0.0) * _448) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _697 = _608 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _697; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _697;\n        float param_9 = _605;\n        vec2 _716 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _497.xy + (_716 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _727 = fa_shadow_depth(param_10, param_11);\n        lit += float((_569 - (length(_716) * _578)) <= _727);\n    }\n    return lit / float(_697);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _760 = int(fa_shadows[25].x + 0.5);\n    if (_760 < 1)\n    {\n        return 1.0;\n    }\n    float _776 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _760 - 1;\n    if (_776 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _788 = _760 > 1;\n    bool _795;\n    if (_788)\n    {\n        _795 = _776 > fa_shadows[24].x;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        ci = 1;\n    }\n    bool _799 = _760 > 2;\n    bool _806;\n    if (_799)\n    {\n        _806 = _776 > fa_shadows[24].y;\n    }\n    else\n    {\n        _806 = _799;\n    }\n    if (_806)\n    {\n        ci = 2;\n    }\n    bool _810 = _760 > 3;\n    bool _817;\n    if (_810)\n    {\n        _817 = _776 > fa_shadows[24].z;\n    }\n    else\n    {\n        _817 = _810;\n    }\n    if (_817)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _760)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _843 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _843;\n        if (_843 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _868;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _868 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _868 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _887 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _868, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _898 = clamp((_776 - (fa_shadow_split_at(param_7) - _887)) / _887, 0.0, 1.0);\n        if (_898 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _760)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _919 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _919;\n                if (_919 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _898);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1242 = fa_light_sample(param, param_1);\n    vec3 _2092 = _1242.direction;\n    vec3 _2087 = _1242.color;\n    float _2094 = _1242.attenuation;\n    float _2089 = _1242.shadow;\n    int _2097 = _1242.type;\n    if ((_2097 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2092;\n        float _1256 = fa_shadow_factor(param_2, param_3);\n        _2089 = _1256;\n        _2087 = fa_lights[li * 1 + 32].xyz * (_2094 * _1256);\n    }\n    return LightSample(_2092, _2087, _2094, _2089, _1242._distance, _2097);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1281 = n < 0;\n    bool _1288;\n    if (!_1281)\n    {\n        _1288 = n >= fa_light_count();\n    }\n    else\n    {\n        _1288 = _1281;\n    }\n    if (_1288)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    vec3 param_1 = i.world_pos;\n    vec3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1133 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1136 = _1133.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1136 * _1136, exp2((-9.27999973297119140625) * ndv)) * _1136) + _1133.y)) + _1133.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1056 = rough * rough;\n    float _1086 = 0.60000002384185791015625 * _1056;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1056)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1086, 0.0500000007450580596923828125 + _1086, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1056 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1175 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1175.x) + vec3(_1175.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    vec3 param = normalize(s.normal);\n    vec3 param_1 = i.view_dir;\n    vec3 param_2 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1350 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1350 > bestPower)\n        {\n            bestPower = _1350;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1379 = fa_light(param_2, param_3);\n        float _1387;\n        if (dot(s.normal, _1379.direction) > 0.5)\n        {\n            _1387 = 1.0;\n        }\n        else\n        {\n            _1387 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _1379.color) * _1387);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _943 = int(fa_shadows[25].x + 0.5);\n    float _953 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _958 = _943 > 0;\n    bool _967;\n    if (_958)\n    {\n        int param = _943 - 1;\n        _967 = _953 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _967 = _958;\n    }\n    if (_967)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _974 = _943 > 1;\n        bool _981;\n        if (_974)\n        {\n            _981 = _953 > fa_shadows[24].x;\n        }\n        else\n        {\n            _981 = _974;\n        }\n        if (_981)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _987 = _943 > 2;\n        bool _994;\n        if (_987)\n        {\n            _994 = _953 > fa_shadows[24].y;\n        }\n        else\n        {\n            _994 = _987;\n        }\n        if (_994)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1000 = _943 > 3;\n        bool _1007;\n        if (_1000)\n        {\n            _1007 = _953 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1007 = _1000;\n        }\n        if (_1007)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _1992 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1992 = -_1992;\n    }\n    vec3 _1697 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing);\n    Surface _1702 = fa_standard_surface(param);\n    vec3 _2023 = _1702.albedo;\n    float _2024 = _1702.alpha;\n    vec3 _2025 = _1702.normal;\n    float _2026 = _1702.metallic;\n    float _2027 = _1702.roughness;\n    float _2028 = _1702.occlusion;\n    vec3 _2029 = _1702.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing);\n    Surface param_2 = _1702;\n    surface(param_1, param_2);\n    _2023 = param_2.albedo;\n    _2024 = param_2.alpha;\n    _2025 = param_2.normal;\n    _2026 = param_2.metallic;\n    _2027 = param_2.roughness;\n    _2028 = param_2.occlusion;\n    _2029 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2023;\n    }\n    else\n    {\n        vec3 _1723 = _2025;\n        vec3 _1724 = normalize(_1723);\n        _2025 = _1724;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing);\n        Surface param_4 = Surface(_2023, _2024, _1724, _2026, _2027, _2028, _2029);\n        result = lighting(param_3, param_4);\n    }\n    vec3 _1739 = result;\n    vec3 _1740 = _1739 + _2029;\n    result = _1740;\n    vec3 param_5 = _1740;\n    vec3 param_6 = fa_world_pos;\n    result = fa_shadow_debug(param_5, param_6);\n    bool _1749 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1757;\n    if (!_1749)\n    {\n        _1757 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1757 = _1749;\n    }\n    if (_1757)\n    {\n        vec3 _1766 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1773 = dot(_1766, fa_mesh_fs_params[9].xyz);\n        bool _1777 = fa_mesh_fs_params[9].w > 0.5;\n        float _1778;\n        if (_1777)\n        {\n            _1778 = _1773;\n        }\n        else\n        {\n            _1778 = length(_1766);\n        }\n        float _1790 = _1778 - fa_mesh_fs_params[8].x;\n        if (_1790 > 0.0)\n        {\n            float _1799 = fa_mesh_fs_params[7].w * _1790;\n            float tau = _1799 * _1799;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1815;\n                if (_1777)\n                {\n                    _1815 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1773);\n                }\n                else\n                {\n                    _1815 = fa_mesh_fs_params[0].y;\n                }\n                float _1836 = mix(_1815, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1778, 0.0, 1.0));\n                float _1840 = fa_world_pos.y - _1836;\n                float _1845 = _1836 - fa_mesh_fs_params[8].z;\n                float _1850 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1853 = _1845 <= 0.0;\n                bool _1854 = !_1853;\n                bool _1860;\n                if (_1854)\n                {\n                    _1860 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1860 = _1853;\n                }\n                float _1861;\n                if (_1860)\n                {\n                    _1861 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1861 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1845, 80.0));\n                }\n                bool _1888;\n                if (_1854)\n                {\n                    _1888 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1888 = _1853;\n                }\n                float _1889;\n                if (_1888)\n                {\n                    _1889 = fa_mesh_fs_params[8].y * _1845;\n                }\n                else\n                {\n                    _1889 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1845, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1914 = _1850 <= 0.0;\n                bool _1921;\n                if (!_1914)\n                {\n                    _1921 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1921 = _1914;\n                }\n                float _1922;\n                if (_1921)\n                {\n                    _1922 = fa_mesh_fs_params[8].y * _1850;\n                }\n                else\n                {\n                    _1922 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1850, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1949;\n                if (abs(_1840) < 0.001000000047497451305389404296875)\n                {\n                    _1949 = _1861;\n                }\n                else\n                {\n                    _1949 = (_1922 - _1889) / _1840;\n                }\n                tau += (_1790 * max(_1949, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2024);\n}\n\n",
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
            "inst_name": "_131",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_224",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_390",
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
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_749",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1393",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_389, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_mesh_fs_params[14];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 6) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1465 = fa_linear_to_srgb(param);\n        c = _1465;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1473 = fa_srgb_to_linear(param_1);\n            c = _1473;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _152;\n    if (i.front_facing)\n    {\n        _152 = i.world_normal;\n    }\n    else\n    {\n        _152 = -i.world_normal;\n    }\n    vec3 _176 = normalize(i.world_tangent.xyz - (_152 * dot(_152, i.world_tangent.xyz)));\n    vec3 _204 = normalize(((_176 * m.x) + ((cross(_152, _176) * i.world_tangent.w) * m.y)) + (_152 * m.z));\n    vec3 _207;\n    if (i.front_facing)\n    {\n        _207 = _204;\n    }\n    else\n    {\n        _207 = -_204;\n    }\n    return _207;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1504 = fa_tex_fix(param_2, param_3);\n    vec4 _2148 = base_t;\n    _2148.x = _1504.x;\n    _2148.y = _1504.y;\n    _2148.z = _1504.z;\n    base_t = _2148;\n    vec4 _1518 = (_2148 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2116 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1550 = fa_tex_fix(param_6, param_7);\n        vec3 _1554 = (_1550 * 2.0) - vec3(1.0);\n        vec2 _1559 = _1554.xy * fa_mesh_fs_params[6].x;\n        vec3 _2156 = _1554;\n        _2156.x = _1559.x;\n        _2156.y = _1559.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2156;\n        _2116 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1588 = fa_tex_fix(param_12, param_13);\n    vec4 _2159 = mrt;\n    _2159.x = _1588.x;\n    _2159.y = _1588.y;\n    _2159.z = _1588.z;\n    mrt = _2159;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1627 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1654 = fa_tex_fix(param_20, param_21);\n    return Surface(_1518.xyz, _1518.w, _2116, clamp(fa_mesh_fs_params[5].x * _1588.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1588.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1627.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1654));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _235 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_235)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _253 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _255 = length(_253);\n        dist = _255;\n        l = _253 / vec3(max(_255, 9.9999997473787516355514526367188e-05));\n        float _271 = _255 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _277 = clamp(1.0 - (_271 * _271), 0.0, 1.0);\n        atten = _277 * _277;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _328;\n    if (_235)\n    {\n        _328 = 0;\n    }\n    else\n    {\n        _328 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _328);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1305 = n < 0;\n    bool _1312;\n    if (!_1305)\n    {\n        _1312 = n >= fa_light_count();\n    }\n    else\n    {\n        _1312 = _1305;\n    }\n    if (_1312)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    vec3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _380;\n    if (i == 0)\n    {\n        _380 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _396;\n        if (i == 1)\n        {\n            _396 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _404;\n            if (i == 2)\n            {\n                _404 = fa_shadows[24].z;\n            }\n            else\n            {\n                _404 = fa_shadows[24].w;\n            }\n            _396 = _404;\n        }\n        _380 = _396;\n    }\n    return _380;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _368 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_368), sin(_368)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _448 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _453 = clamp(dot(n, l), 0.0, 1.0);\n    float _459 = sqrt(1.0 - (_453 * _453));\n    float _467 = min(_459 / max(_453, 0.20000000298023223876953125), 4.0);\n    float _472;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _472 = fa_shadows[26].y;\n    }\n    else\n    {\n        _472 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _497 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_472 * _459)), 1.0);\n    float _504 = _497.x;\n    bool _507 = _504 < fa_shadows[ci * 1 + 16].x;\n    bool _516;\n    if (!_507)\n    {\n        _516 = _504 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _516 = _507;\n    }\n    bool _525;\n    if (!_516)\n    {\n        _525 = _497.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _525 = _516;\n    }\n    bool _534;\n    if (!_525)\n    {\n        _534 = _497.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _534 = _525;\n    }\n    bool _541;\n    if (!_534)\n    {\n        _541 = _497.z > 1.0;\n    }\n    else\n    {\n        _541 = _534;\n    }\n    if (_541)\n    {\n        return -1.0;\n    }\n    float _550;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _550 = fa_shadows[26].x;\n    }\n    else\n    {\n        _550 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _569 = _497.z - ((_550 * (1.0 + (0.5 * _467))) / _448);\n    float _578 = ((fa_shadows[ci * 1 + 20].x * min(_467, 3.0)) * 0.5) / _448;\n    int _587 = int(fa_shadows[25].z + 0.5);\n    if (_587 == 1)\n    {\n        vec2 param = _497.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _598 = fa_shadow_depth(param, param_1);\n        return float(_569 <= _598);\n    }\n    float _605 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _608 = _587 == 2;\n    if (_608)\n    {\n        float _622 = clamp(((fa_shadows[25].w * _448) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _605;\n            vec2 _642 = fa_shadow_vogel(param_2, param_3, param_4) * _622;\n            vec2 param_5 = _497.xy + (_642 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _653 = fa_shadow_depth(param_5, param_6);\n            if (_653 < (_569 - (length(_642) * _578)))\n            {\n                sum += _653;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_569 - (sum / cnt), 0.0) * _448) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _697 = _608 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _697; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _697;\n        float param_9 = _605;\n        vec2 _716 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _497.xy + (_716 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _727 = fa_shadow_depth(param_10, param_11);\n        lit += float((_569 - (length(_716) * _578)) <= _727);\n    }\n    return lit / float(_697);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _760 = int(fa_shadows[25].x + 0.5);\n    if (_760 < 1)\n    {\n        return 1.0;\n    }\n    float _776 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _760 - 1;\n    if (_776 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _788 = _760 > 1;\n    bool _795;\n    if (_788)\n    {\n        _795 = _776 > fa_shadows[24].x;\n    }\n    else\n    {\n        _795 = _788;\n    }\n    if (_795)\n    {\n        ci = 1;\n    }\n    bool _799 = _760 > 2;\n    bool _806;\n    if (_799)\n    {\n        _806 = _776 > fa_shadows[24].y;\n    }\n    else\n    {\n        _806 = _799;\n    }\n    if (_806)\n    {\n        ci = 2;\n    }\n    bool _810 = _760 > 3;\n    bool _817;\n    if (_810)\n    {\n        _817 = _776 > fa_shadows[24].z;\n    }\n    else\n    {\n        _817 = _810;\n    }\n    if (_817)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _760)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _843 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _843;\n        if (_843 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _868;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _868 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _868 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _887 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _868, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _898 = clamp((_776 - (fa_shadow_split_at(param_7) - _887)) / _887, 0.0, 1.0);\n        if (_898 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _760)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _919 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _919;\n                if (_919 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _898);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1242 = fa_light_sample(param, param_1);\n    vec3 _2092 = _1242.direction;\n    vec3 _2087 = _1242.color;\n    float _2094 = _1242.attenuation;\n    float _2089 = _1242.shadow;\n    int _2097 = _1242.type;\n    if ((_2097 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2092;\n        float _1256 = fa_shadow_factor(param_2, param_3);\n        _2089 = _1256;\n        _2087 = fa_lights[li * 1 + 32].xyz * (_2094 * _1256);\n    }\n    return LightSample(_2092, _2087, _2094, _2089, _1242._distance, _2097);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1281 = n < 0;\n    bool _1288;\n    if (!_1281)\n    {\n        _1288 = n >= fa_light_count();\n    }\n    else\n    {\n        _1288 = _1281;\n    }\n    if (_1288)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    vec3 param_1 = i.world_pos;\n    vec3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1133 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1136 = _1133.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1136 * _1136, exp2((-9.27999973297119140625) * ndv)) * _1136) + _1133.y)) + _1133.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1056 = rough * rough;\n    float _1086 = 0.60000002384185791015625 * _1056;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1056)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1086, 0.0500000007450580596923828125 + _1086, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1056 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1175 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1175.x) + vec3(_1175.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    vec3 param = normalize(s.normal);\n    vec3 param_1 = i.view_dir;\n    vec3 param_2 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(clamp(s.metallic, 0.0, 1.0)));\n    float param_3 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    return fa_sky_reflection(param, param_1, param_2, param_3) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1350 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1350 > bestPower)\n        {\n            bestPower = _1350;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1379 = fa_light(param_2, param_3);\n        float _1387;\n        if (dot(s.normal, _1379.direction) > 0.5)\n        {\n            _1387 = 1.0;\n        }\n        else\n        {\n            _1387 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _1379.color) * _1387);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _943 = int(fa_shadows[25].x + 0.5);\n    float _953 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _958 = _943 > 0;\n    bool _967;\n    if (_958)\n    {\n        int param = _943 - 1;\n        _967 = _953 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _967 = _958;\n    }\n    if (_967)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _974 = _943 > 1;\n        bool _981;\n        if (_974)\n        {\n            _981 = _953 > fa_shadows[24].x;\n        }\n        else\n        {\n            _981 = _974;\n        }\n        if (_981)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _987 = _943 > 2;\n        bool _994;\n        if (_987)\n        {\n            _994 = _953 > fa_shadows[24].y;\n        }\n        else\n        {\n            _994 = _987;\n        }\n        if (_994)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1000 = _943 > 3;\n        bool _1007;\n        if (_1000)\n        {\n            _1007 = _953 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1007 = _1000;\n        }\n        if (_1007)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _1992 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _1992 = -_1992;\n    }\n    vec3 _1697 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing);\n    Surface _1702 = fa_standard_surface(param);\n    vec3 _2023 = _1702.albedo;\n    float _2024 = _1702.alpha;\n    vec3 _2025 = _1702.normal;\n    float _2026 = _1702.metallic;\n    float _2027 = _1702.roughness;\n    float _2028 = _1702.occlusion;\n    vec3 _2029 = _1702.emission;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing);\n    Surface param_2 = _1702;\n    surface(param_1, param_2);\n    _2023 = param_2.albedo;\n    _2024 = param_2.alpha;\n    _2025 = param_2.normal;\n    _2026 = param_2.metallic;\n    _2027 = param_2.roughness;\n    _2028 = param_2.occlusion;\n    _2029 = param_2.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2023;\n    }\n    else\n    {\n        vec3 _1723 = _2025;\n        vec3 _1724 = normalize(_1723);\n        _2025 = _1724;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _1992, fa_world_tangent, fa_uv, fa_vertex_color, _1697, gl_FrontFacing);\n        Surface param_4 = Surface(_2023, _2024, _1724, _2026, _2027, _2028, _2029);\n        result = lighting(param_3, param_4);\n    }\n    vec3 _1739 = result;\n    vec3 _1740 = _1739 + _2029;\n    result = _1740;\n    vec3 param_5 = _1740;\n    vec3 param_6 = fa_world_pos;\n    result = fa_shadow_debug(param_5, param_6);\n    bool _1749 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1757;\n    if (!_1749)\n    {\n        _1757 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1757 = _1749;\n    }\n    if (_1757)\n    {\n        vec3 _1766 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1773 = dot(_1766, fa_mesh_fs_params[9].xyz);\n        bool _1777 = fa_mesh_fs_params[9].w > 0.5;\n        float _1778;\n        if (_1777)\n        {\n            _1778 = _1773;\n        }\n        else\n        {\n            _1778 = length(_1766);\n        }\n        float _1790 = _1778 - fa_mesh_fs_params[8].x;\n        if (_1790 > 0.0)\n        {\n            float _1799 = fa_mesh_fs_params[7].w * _1790;\n            float tau = _1799 * _1799;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1815;\n                if (_1777)\n                {\n                    _1815 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1773);\n                }\n                else\n                {\n                    _1815 = fa_mesh_fs_params[0].y;\n                }\n                float _1836 = mix(_1815, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1778, 0.0, 1.0));\n                float _1840 = fa_world_pos.y - _1836;\n                float _1845 = _1836 - fa_mesh_fs_params[8].z;\n                float _1850 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1853 = _1845 <= 0.0;\n                bool _1854 = !_1853;\n                bool _1860;\n                if (_1854)\n                {\n                    _1860 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1860 = _1853;\n                }\n                float _1861;\n                if (_1860)\n                {\n                    _1861 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1861 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1845, 80.0));\n                }\n                bool _1888;\n                if (_1854)\n                {\n                    _1888 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1888 = _1853;\n                }\n                float _1889;\n                if (_1888)\n                {\n                    _1889 = fa_mesh_fs_params[8].y * _1845;\n                }\n                else\n                {\n                    _1889 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1845, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1914 = _1850 <= 0.0;\n                bool _1921;\n                if (!_1914)\n                {\n                    _1921 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1921 = _1914;\n                }\n                float _1922;\n                if (_1921)\n                {\n                    _1922 = fa_mesh_fs_params[8].y * _1850;\n                }\n                else\n                {\n                    _1922 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1850, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1949;\n                if (abs(_1840) < 0.001000000047497451305389404296875)\n                {\n                    _1949 = _1861;\n                }\n                else\n                {\n                    _1949 = (_1922 - _1889) / _1840;\n                }\n                tau += (_1790 * max(_1949, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2024);\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_224",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_390",
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
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_749",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1393",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[14];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _589 = base_t;\n    _589.x = _225.x;\n    _589.y = _225.y;\n    _589.z = _225.z;\n    base_t = _589;\n    vec4 _241 = (_589 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _570 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _597 = _279;\n        _597.x = _284.x;\n        _597.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _597;\n        _570 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _600 = mrt;\n    _600.x = _313.x;\n    _600.y = _313.y;\n    _600.z = _313.z;\n    mrt = _600;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _570, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _517 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _517 = -_517;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _517, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _517, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_131",
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
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[14];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _589 = base_t;\n    _589.x = _225.x;\n    _589.y = _225.y;\n    _589.z = _225.z;\n    base_t = _589;\n    vec4 _241 = (_589 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _570 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _597 = _279;\n        _597.x = _284.x;\n        _597.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _597;\n        _570 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _600 = mrt;\n    _600.x = _313.x;\n    _600.y = _313.y;\n    _600.z = _313.z;\n    mrt = _600;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _570, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _517 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _517 = -_517;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _517, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _517, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_183",
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
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    }
  }
}
