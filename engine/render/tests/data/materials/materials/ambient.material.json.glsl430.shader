{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _463 = fa_mesh_fs_params[19].x < 0.0;\n    bool _470;\n    if (!_463)\n    {\n        _470 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _478;\n    if (!_470)\n    {\n        _478 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _478 = _470;\n    }\n    bool _485;\n    if (!_478)\n    {\n        _485 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _485 = _478;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    if (_492)\n    {\n        return vec4(0.0);\n    }\n    vec4 _502 = vec4(world_pos, 1.0);\n    float _509 = dot(fa_mesh_fs_params[16], _502);\n    if (!(_509 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _531 = vec2(dot(fa_mesh_fs_params[14], _502), dot(fa_mesh_fs_params[15], _502)) / vec2(_509);\n    int _535 = int(fa_mesh_fs_params[18].x);\n    int _539 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _539) + clamp(int(floor(((_531.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _539 - 1)) * _535)) + clamp(int(floor(((_531.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _535 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _615 = fa_cluster_texel(param);\n    return ivec2(int(_615.x), int(_615.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2420 = fa_cluster_lookup(param);\n    fa_cl_slot = _2420.x;\n    fa_cl_local = _2420.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2573 = fa_linear_to_srgb(param);\n        c = _2573;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2581 = fa_srgb_to_linear(param_1);\n            c = _2581;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _223;\n    if (i.front_facing)\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    vec3 _247 = normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    vec3 _274 = normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    vec3 _277;\n    if (i.front_facing)\n    {\n        _277 = _274;\n    }\n    else\n    {\n        _277 = -_274;\n    }\n    return _277;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2612 = fa_tex_fix(param_2, param_3);\n    vec4 _3647 = base_t;\n    _3647.x = _2612.x;\n    _3647.y = _2612.y;\n    _3647.z = _2612.z;\n    base_t = _3647;\n    vec4 _2626 = (_3647 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3527 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2658 = fa_tex_fix(param_6, param_7);\n        vec3 _2661 = (_2658 * 2.0) - vec3(1.0);\n        vec2 _2666 = _2661.xy * fa_mesh_fs_params[6].x;\n        vec3 _3655 = _2661;\n        _3655.x = _2666.x;\n        _3655.y = _2666.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3655;\n        _3527 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2695 = fa_tex_fix(param_12, param_13);\n    vec4 _3658 = mrt;\n    _3658.x = _2695.x;\n    _3658.y = _2695.y;\n    _3658.z = _2695.z;\n    mrt = _3658;\n    vec4 _2723 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2723.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2735 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2765 = fa_tex_fix(param_20, param_21);\n    float _3532 = fa_mesh_fs_params[20].x;\n    float _3533 = fa_mesh_fs_params[20].y;\n    float _3536 = fa_mesh_fs_params[20].z;\n    float _3535 = fa_mesh_fs_params[21].w;\n    float _3538 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3532 *= _2735.y;\n            _3533 *= _2735.z;\n            _3535 *= _2723.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3536 *= mrt.x;\n            _3538 *= mrt.w;\n        }\n    }\n    return Surface(_2626.xyz, _2626.w, _3527, clamp(fa_mesh_fs_params[5].x * _2695.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2695.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2735.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2765), _3532, _3533, fa_mesh_fs_params[21].xyz, _3535, _3536, fa_mesh_fs_params[20].w, _3538, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _696 = rect.zw - rect.xy;\n    vec2 _700 = _696 * atlas;\n    vec2 _704 = ddx * _700;\n    vec2 _708 = ddy * _700;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _696), clamp(0.5 * log2(max(max(dot(_704, _704), dot(_708, _708)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _743 = fa_mesh_fs_params[10].y < 0.5;\n    bool _750;\n    if (!_743)\n    {\n        _750 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return;\n    }\n    vec3 _756 = dFdx(world_pos);\n    vec3 _759 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _763 = fa_cluster_texel(param);\n    int _767 = int(_763.w);\n    if (_767 < 1)\n    {\n        return;\n    }\n    int _777 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _777;\n    vec4 _781 = fa_light_texel(param_1);\n    vec2 _784 = _781.yz;\n    int _788 = int(_781.w);\n    int param_2 = _777 + 1;\n    vec4 _793 = fa_light_texel(param_2);\n    float _794 = _793.x;\n    int _800 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _804 = int(_763.z);\n    vec3 _1070;\n    for (int k = 0; k < _767; k++)\n    {\n        int _817 = _804 + k;\n        int param_3 = _788 + (_817 >> 2);\n        int _835 = (_777 + 2) + (int(fa_light_texel(param_3)[_817 & 3]) * 7);\n        int param_4 = _835 + 6;\n        vec4 _840 = fa_light_texel(param_4);\n        if (((int(_840.w + 0.5) >> _800) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _835;\n        vec4 _855 = fa_light_texel(param_5);\n        int param_6 = _835 + 1;\n        vec4 _860 = fa_light_texel(param_6);\n        int param_7 = _835 + 2;\n        vec4 _865 = fa_light_texel(param_7);\n        vec3 _868 = _855.xyz;\n        float _873 = dot(_868, world_pos) + _855.w;\n        vec3 _875 = _860.xyz;\n        float _880 = dot(_875, world_pos) + _860.w;\n        vec3 _882 = _865.xyz;\n        float _887 = dot(_882, world_pos) + _865.w;\n        bool _892 = abs(_873) > 0.5;\n        bool _900;\n        if (!_892)\n        {\n            _900 = abs(_880) > 0.5;\n        }\n        else\n        {\n            _900 = _892;\n        }\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_887) > 0.5;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        if (_908)\n        {\n            continue;\n        }\n        float _923 = clamp(dot(geo_normal, normalize(_882)) * _840.z, 0.0, 1.0);\n        if (_923 <= 0.0)\n        {\n            continue;\n        }\n        float _943 = (clamp((0.5 - abs(_887)) * 10.0, 0.0, 1.0) * _923) * _840.x;\n        vec2 _951 = vec2(_873 + 0.5, 0.5 - _880);\n        vec2 _961 = vec2(dot(_868, _756), dot(_875, _756));\n        vec2 _971 = vec2(dot(_868, _759), dot(_875, _759));\n        int param_8 = _835 + 5;\n        vec4 _976 = fa_light_texel(param_8);\n        int param_9 = _835 + 3;\n        vec4 _981 = fa_light_texel(param_9);\n        int param_10 = _835 + 4;\n        vec4 _986 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _976.xyz;\n        bool _996 = _981.z > _981.x;\n        if (_996)\n        {\n            vec4 param_11 = _981;\n            vec2 param_12 = _951;\n            vec2 param_13 = _784;\n            vec2 param_14 = _961;\n            vec2 param_15 = _971;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_794 > 0.5) && (_794 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1022 = fa_dc_to_linear(param_16);\n                vec4 _3583 = tx;\n                _3583.x = _1022.x;\n                _3583.y = _1022.y;\n                _3583.z = _1022.z;\n                tx = _3583;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_943 * tex_a) * _976.w, 0.0, 1.0)));\n        if (_986.z > _986.x)\n        {\n            vec4 param_17 = _986;\n            vec2 param_18 = _951;\n            vec2 param_19 = _784;\n            vec2 param_20 = _961;\n            vec2 param_21 = _971;\n            vec4 _1066 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_794 > 1.5)\n            {\n                vec3 param_22 = _1066.xyz;\n                vec3 _1076 = fa_dc_to_srgb(param_22);\n                _1070 = _1076;\n            }\n            else\n            {\n                _1070 = _1066.xyz;\n            }\n            vec3 _1086 = (_1070 * 2.0) - vec3(1.0);\n            vec2 _1091 = _1086.xy * _840.y;\n            vec3 _1113 = (normalize(_868) * _1091.x) + (normalize(_875) * _1091.y);\n            vec3 _1116 = normalize(normal);\n            normal = normalize(mix(_1116, normalize((_1116 * max(_1086.z, 0.0500000007450580596923828125)) + (_1113 - (_1116 * dot(_1116, _1113)))), vec3(clamp(_943 * (_996 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2333 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2333;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _333 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _339 = fa_light_texel(param_1);\n    float _342 = _339.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _348 = _342 < 0.5;\n    vec3 l;\n    if (_348)\n    {\n        l = normalize(_333.xyz);\n    }\n    else\n    {\n        vec3 _360 = _333.xyz - world_pos;\n        float _362 = length(_360);\n        dist = _362;\n        l = _360 / vec3(max(_362, 9.9999997473787516355514526367188e-05));\n        float _377 = _362 / max(_333.w, 0.001000000047497451305389404296875);\n        float _383 = clamp(1.0 - (_377 * _377), 0.0, 1.0);\n        atten = _383 * _383;\n        if (_342 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _397 = fa_light_texel(param_2);\n            float _407 = _397.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _413 = fa_light_texel(param_3);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5)\n            {\n                cos_inner = mix(_407, 1.0, 0.25);\n            }\n            atten *= smoothstep(_407, cos_inner, dot(-l, normalize(_397.xyz)));\n        }\n    }\n    int _444;\n    if (_348)\n    {\n        _444 = 0;\n    }\n    else\n    {\n        _444 = (_342 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _339.xyz * atten, atten, 1.0, dist, _444);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1188;\n    if (i == 0)\n    {\n        _1188 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1204;\n        if (i == 1)\n        {\n            _1204 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1212;\n            if (i == 2)\n            {\n                _1212 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1212 = fa_shadows[24].w;\n            }\n            _1204 = _1212;\n        }\n        _1188 = _1204;\n    }\n    return _1188;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1245 = fa_shadow_depth(param, param_1);\n    float _1249;\n    if (conv.x < 0.5)\n    {\n        _1249 = _1245;\n    }\n    else\n    {\n        _1249 = (conv.y * conv.z) / (conv.z - (_1245 * (conv.z - conv.y)));\n    }\n    return _1249;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1176 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1176), sin(_1176)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1295 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1309 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1295;\n            vec2 _1328 = fa_shadow_vogel(param_3, param_4, param_5) * _1309;\n            vec2 param_6 = uv + (_1328 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1340 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1340 < (zr - (length(_1328) * plane)))\n            {\n                sum += _1340;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1384 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1384; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1384;\n        float param_11 = _1295;\n        vec2 _1403 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1403 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1403) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1384);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1445 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1450 = clamp(dot(n, l), 0.0, 1.0);\n    float _1456 = sqrt(1.0 - (_1450 * _1450));\n    float _1463 = min(_1456 / max(_1450, 0.20000000298023223876953125), 4.0);\n    float _1468;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1468 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1468 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1493 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1468 * _1456)), 1.0);\n    float _1500 = _1493.x;\n    bool _1503 = _1500 < fa_shadows[ci * 1 + 16].x;\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1500 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1521;\n    if (!_1512)\n    {\n        _1521 = _1493.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1521 = _1512;\n    }\n    bool _1530;\n    if (!_1521)\n    {\n        _1530 = _1493.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1530 = _1521;\n    }\n    bool _1537;\n    if (!_1530)\n    {\n        _1537 = _1493.z > 1.0;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        return -1.0;\n    }\n    float _1546;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1546 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1546 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1493.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1493.z - ((_1546 * (1.0 + (0.5 * _1463))) / _1445);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1445;\n    float param_5 = _1445 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1463, 3.0)) * 0.5) / _1445;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1973 = int(fa_shadows[25].x + 0.5);\n    if (_1973 < 1)\n    {\n        return 1.0;\n    }\n    float _1988 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1973 - 1;\n    if (_1988 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2000 = _1973 > 1;\n    bool _2007;\n    if (_2000)\n    {\n        _2007 = _1988 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2007 = _2000;\n    }\n    if (_2007)\n    {\n        ci = 1;\n    }\n    bool _2011 = _1973 > 2;\n    bool _2018;\n    if (_2011)\n    {\n        _2018 = _1988 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2018 = _2011;\n    }\n    if (_2018)\n    {\n        ci = 2;\n    }\n    bool _2022 = _1973 > 3;\n    bool _2029;\n    if (_2022)\n    {\n        _2029 = _1988 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2029 = _2022;\n    }\n    if (_2029)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1973)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2055 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2055;\n        if (_2055 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2080;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2080 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2080 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2099 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2080, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2110 = clamp((_1988 - (fa_shadow_split_at(param_7) - _2099)) / _2099, 0.0, 1.0);\n        if (_2110 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1973)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2131 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2131;\n                if (_2131 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2110);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1604 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    if (_1612)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1625 = fa_light_texel(param);\n    float _1626 = _1625.x;\n    if (_1626 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1635 = int(_1626 + 0.5);\n    int param_1 = _1635;\n    vec4 _1639 = fa_light_texel(param_1);\n    int param_2 = _1635 + 1;\n    vec4 _1644 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1647 = _1639.y;\n    if (_1647 > 0.0)\n    {\n        float _1664 = 1.0 - smoothstep(0.75 * _1647, _1647, length(world - fa_shadows[27].xyz));\n        fade = _1664;\n        if (_1664 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1639.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1683 = world - fa_light_texel(param_3).xyz;\n        vec3 _1686 = abs(_1683);\n        float _1688 = _1686.x;\n        float _1690 = _1686.y;\n        bool _1691 = _1688 >= _1690;\n        bool _1699;\n        if (_1691)\n        {\n            _1699 = _1688 >= _1686.z;\n        }\n        else\n        {\n            _1699 = _1691;\n        }\n        int _1700;\n        if (_1699)\n        {\n            _1700 = (_1683.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1713;\n            if (_1690 >= _1686.z)\n            {\n                _1713 = (_1683.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1713 = (_1683.z > 0.0) ? 4 : 5;\n            }\n            _1700 = _1713;\n        }\n        face = _1700;\n    }\n    int _1732 = (_1635 + 2) + (face * 6);\n    int param_4 = _1732;\n    int param_5 = _1732 + 1;\n    int param_6 = _1732 + 3;\n    vec4 _1746 = fa_light_texel(param_6);\n    int param_7 = _1732 + 4;\n    vec4 _1751 = fa_light_texel(param_7);\n    int param_8 = _1732 + 5;\n    vec4 _1756 = fa_light_texel(param_8);\n    float _1768 = _1756.x * max(dot(_1746, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1773 = clamp(dot(n, l), 0.0, 1.0);\n    float _1796 = clamp(dot(n, _1746.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1819 = min(sqrt(1.0 - (_1796 * _1796)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1746, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1822 = _1644.y;\n    float _1824;\n    if (_1822 > 0.0)\n    {\n        _1824 = _1822;\n    }\n    else\n    {\n        _1824 = 1.5 * _1768;\n    }\n    vec4 _1844 = vec4(world + (n * (_1824 * sqrt(1.0 - (_1773 * _1773)))), 1.0);\n    float _1848 = dot(_1746, _1844);\n    float _1851 = _1756.y;\n    if (_1848 < _1851)\n    {\n        return 1.0;\n    }\n    vec2 _1866 = vec2(dot(fa_light_texel(param_4), _1844), dot(fa_light_texel(param_5), _1844)) / vec2(_1848);\n    float _1868 = _1866.x;\n    bool _1871 = _1868 < _1751.x;\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1868 > _1751.z;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    bool _1889;\n    if (!_1880)\n    {\n        _1889 = _1866.y < _1751.y;\n    }\n    else\n    {\n        _1889 = _1880;\n    }\n    bool _1898;\n    if (!_1889)\n    {\n        _1898 = _1866.y > _1751.w;\n    }\n    else\n    {\n        _1898 = _1889;\n    }\n    if (_1898)\n    {\n        return 1.0;\n    }\n    float _1904 = _1644.x;\n    float _1906;\n    if (_1904 > 0.0)\n    {\n        _1906 = _1904;\n    }\n    else\n    {\n        _1906 = 1.5 * _1768;\n    }\n    vec2 param_10 = _1866;\n    vec4 param_11 = _1751;\n    float param_12 = _1848 - (_1906 * (1.0 + (0.5 * _1819)));\n    float param_13 = _1768;\n    float param_14 = 1.0;\n    float param_15 = _1756.z * 0.25;\n    float param_16 = (_1768 * min(_1819, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1851, _1756.z);\n    int param_18 = int(_1639.z + 0.5);\n    float param_19 = _1639.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2447 = fa_lm.z > 0.5;\n    bool _2453;\n    if (_2447)\n    {\n        int param = li;\n        _2453 = fa_light_baked(param);\n    }\n    else\n    {\n        _2453 = _2447;\n    }\n    if (_2453)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2476 = fa_light_sample(param_2, param_3);\n    vec3 _3512 = _2476.direction;\n    vec3 _3507 = _2476.color;\n    float _3514 = _2476.attenuation;\n    float _3509 = _2476.shadow;\n    int _3517 = _2476.type;\n    if ((_3517 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3512;\n        float _2490 = fa_shadow_factor(param_4, param_5);\n        _3509 = _2490;\n        _3507 *= _2490;\n    }\n    else\n    {\n        bool _2501 = _3517 != 0;\n        bool _2507;\n        if (_2501)\n        {\n            _2507 = _3514 > 0.0;\n        }\n        else\n        {\n            _2507 = _2501;\n        }\n        if (_2507)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3512;\n            float _2519 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3509 = _2519;\n            _3507 *= _2519;\n        }\n    }\n    return LightSample(_3512, _3507, _3514, _3509, _2476._distance, _3517);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2155 = int(fa_shadows[25].x + 0.5);\n    float _2165 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2170 = _2155 > 0;\n    bool _2179;\n    if (_2170)\n    {\n        int param = _2155 - 1;\n        _2179 = _2165 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2179 = _2170;\n    }\n    if (_2179)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2186 = _2155 > 1;\n        bool _2193;\n        if (_2186)\n        {\n            _2193 = _2165 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2193 = _2186;\n        }\n        if (_2193)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2199 = _2155 > 2;\n        bool _2206;\n        if (_2199)\n        {\n            _2206 = _2165 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2206 = _2199;\n        }\n        if (_2206)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2212 = _2155 > 3;\n        bool _2219;\n        if (_2212)\n        {\n            _2219 = _2165 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2219 = _2212;\n        }\n        if (_2219)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3323 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3323 = -_3323;\n    }\n    vec3 _2908 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3323, fa_world_tangent, fa_uv, fa_vertex_color, _2908, gl_FrontFacing);\n    Surface _2916 = fa_standard_surface(param_1);\n    vec3 _3362 = _2916.albedo;\n    float _3363 = _2916.alpha;\n    vec3 _3364 = _2916.normal;\n    float _3365 = _2916.metallic;\n    float _3366 = _2916.roughness;\n    float _3367 = _2916.occlusion;\n    vec3 _3368 = _2916.emission;\n    float _3369 = _2916.clearcoat;\n    float _3370 = _2916.clearcoat_roughness;\n    vec3 _3371 = _2916.sheen_color;\n    float _3372 = _2916.sheen_roughness;\n    float _3373 = _2916.anisotropy;\n    float _3374 = _2916.anisotropy_rotation;\n    float _3375 = _2916.specular;\n    float _3376 = _2916.ior;\n    vec3 _3377 = _2916.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3323, fa_world_tangent, fa_uv, fa_vertex_color, _2908, gl_FrontFacing);\n    Surface param_3 = _2916;\n    surface(param_2, param_3);\n    _3362 = param_3.albedo;\n    _3363 = param_3.alpha;\n    _3364 = param_3.normal;\n    _3365 = param_3.metallic;\n    _3366 = param_3.roughness;\n    _3367 = param_3.occlusion;\n    _3368 = param_3.emission;\n    _3369 = param_3.clearcoat;\n    _3370 = param_3.clearcoat_roughness;\n    _3371 = param_3.sheen_color;\n    _3372 = param_3.sheen_roughness;\n    _3373 = param_3.anisotropy;\n    _3374 = param_3.anisotropy_rotation;\n    _3375 = param_3.specular;\n    _3376 = param_3.ior;\n    _3377 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3323;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3362 = param_6;\n    _3364 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3362;\n    }\n    else\n    {\n        vec3 _2954 = _3364;\n        vec3 _2955 = normalize(_2954);\n        _3364 = _2955;\n        vec3 param_8 = _2955;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _3323, fa_world_tangent, fa_uv, fa_vertex_color, _2908, gl_FrontFacing);\n        Surface param_10 = Surface(_3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375, _3376, _3377);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _2974 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2974; ln++)\n        {\n            int param_12 = ln;\n            int _2987 = fa_cl_light(param_12);\n            bool _2990 = fa_lm.z > 0.5;\n            bool _2996;\n            if (_2990)\n            {\n                int param_13 = _2987;\n                _2996 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _2996 = _2990;\n            }\n            if (_2996)\n            {\n                continue;\n            }\n            int param_14 = _2987;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3323;\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _3323, fa_world_tangent, fa_uv, fa_vertex_color, _2908, gl_FrontFacing);\n            Surface param_18 = Surface(_3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375, _3376, _3377);\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _3023 = result;\n    vec3 _3024 = _3023 + _3368;\n    result = _3024;\n    vec3 param_20 = _3024;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3033 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3040;\n    if (!_3033)\n    {\n        _3040 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3040 = _3033;\n    }\n    if (_3040)\n    {\n        vec3 _3049 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3055 = dot(_3049, fa_mesh_fs_params[9].xyz);\n        bool _3059 = fa_mesh_fs_params[9].w > 0.5;\n        float _3060;\n        if (_3059)\n        {\n            _3060 = _3055;\n        }\n        else\n        {\n            _3060 = length(_3049);\n        }\n        float _3072 = _3060 - fa_mesh_fs_params[8].x;\n        if (_3072 > 0.0)\n        {\n            float _3081 = fa_mesh_fs_params[7].w * _3072;\n            float tau = _3081 * _3081;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3097;\n                if (_3059)\n                {\n                    _3097 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3055);\n                }\n                else\n                {\n                    _3097 = fa_mesh_fs_params[0].y;\n                }\n                float _3118 = mix(_3097, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3060, 0.0, 1.0));\n                float _3122 = fa_world_pos.y - _3118;\n                float _3127 = _3118 - fa_mesh_fs_params[8].z;\n                float _3132 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3135 = _3127 <= 0.0;\n                bool _3136 = !_3135;\n                bool _3142;\n                if (_3136)\n                {\n                    _3142 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3142 = _3135;\n                }\n                float _3143;\n                if (_3142)\n                {\n                    _3143 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3143 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3127, 80.0));\n                }\n                bool _3170;\n                if (_3136)\n                {\n                    _3170 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3170 = _3135;\n                }\n                float _3171;\n                if (_3170)\n                {\n                    _3171 = fa_mesh_fs_params[8].y * _3127;\n                }\n                else\n                {\n                    _3171 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3127, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3196 = _3132 <= 0.0;\n                bool _3203;\n                if (!_3196)\n                {\n                    _3203 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3203 = _3196;\n                }\n                float _3204;\n                if (_3203)\n                {\n                    _3204 = fa_mesh_fs_params[8].y * _3132;\n                }\n                else\n                {\n                    _3204 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3132, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3231;\n                if (abs(_3122) < 0.001000000047497451305389404296875)\n                {\n                    _3231 = _3143;\n                }\n                else\n                {\n                    _3231 = (_3204 - _3171) / _3122;\n                }\n                tau += (_3072 * max(_3231, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3363);\n}\n\n",
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
            "inst_name": "_131",
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
            "inst_name": "_458",
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
            "inst_name": "_1198",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _463 = fa_mesh_fs_params[19].x < 0.0;\n    bool _470;\n    if (!_463)\n    {\n        _470 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _478;\n    if (!_470)\n    {\n        _478 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _478 = _470;\n    }\n    bool _485;\n    if (!_478)\n    {\n        _485 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _485 = _478;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    if (_492)\n    {\n        return vec4(0.0);\n    }\n    vec4 _502 = vec4(world_pos, 1.0);\n    float _509 = dot(fa_mesh_fs_params[16], _502);\n    if (!(_509 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _531 = vec2(dot(fa_mesh_fs_params[14], _502), dot(fa_mesh_fs_params[15], _502)) / vec2(_509);\n    int _535 = int(fa_mesh_fs_params[18].x);\n    int _539 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _539) + clamp(int(floor(((_531.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _539 - 1)) * _535)) + clamp(int(floor(((_531.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _535 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _615 = fa_cluster_texel(param);\n    return ivec2(int(_615.x), int(_615.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2420 = fa_cluster_lookup(param);\n    fa_cl_slot = _2420.x;\n    fa_cl_local = _2420.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2573 = fa_linear_to_srgb(param);\n        c = _2573;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2581 = fa_srgb_to_linear(param_1);\n            c = _2581;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _223;\n    if (i.front_facing)\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    vec3 _247 = normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    vec3 _274 = normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    vec3 _277;\n    if (i.front_facing)\n    {\n        _277 = _274;\n    }\n    else\n    {\n        _277 = -_274;\n    }\n    return _277;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2612 = fa_tex_fix(param_2, param_3);\n    vec4 _3647 = base_t;\n    _3647.x = _2612.x;\n    _3647.y = _2612.y;\n    _3647.z = _2612.z;\n    base_t = _3647;\n    vec4 _2626 = (_3647 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3527 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2658 = fa_tex_fix(param_6, param_7);\n        vec3 _2661 = (_2658 * 2.0) - vec3(1.0);\n        vec2 _2666 = _2661.xy * fa_mesh_fs_params[6].x;\n        vec3 _3655 = _2661;\n        _3655.x = _2666.x;\n        _3655.y = _2666.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3655;\n        _3527 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2695 = fa_tex_fix(param_12, param_13);\n    vec4 _3658 = mrt;\n    _3658.x = _2695.x;\n    _3658.y = _2695.y;\n    _3658.z = _2695.z;\n    mrt = _3658;\n    vec4 _2723 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2723.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2735 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2765 = fa_tex_fix(param_20, param_21);\n    float _3532 = fa_mesh_fs_params[20].x;\n    float _3533 = fa_mesh_fs_params[20].y;\n    float _3536 = fa_mesh_fs_params[20].z;\n    float _3535 = fa_mesh_fs_params[21].w;\n    float _3538 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3532 *= _2735.y;\n            _3533 *= _2735.z;\n            _3535 *= _2723.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3536 *= mrt.x;\n            _3538 *= mrt.w;\n        }\n    }\n    return Surface(_2626.xyz, _2626.w, _3527, clamp(fa_mesh_fs_params[5].x * _2695.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2695.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2735.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2765), _3532, _3533, fa_mesh_fs_params[21].xyz, _3535, _3536, fa_mesh_fs_params[20].w, _3538, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _696 = rect.zw - rect.xy;\n    vec2 _700 = _696 * atlas;\n    vec2 _704 = ddx * _700;\n    vec2 _708 = ddy * _700;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _696), clamp(0.5 * log2(max(max(dot(_704, _704), dot(_708, _708)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _743 = fa_mesh_fs_params[10].y < 0.5;\n    bool _750;\n    if (!_743)\n    {\n        _750 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _750 = _743;\n    }\n    if (_750)\n    {\n        return;\n    }\n    vec3 _756 = dFdx(world_pos);\n    vec3 _759 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _763 = fa_cluster_texel(param);\n    int _767 = int(_763.w);\n    if (_767 < 1)\n    {\n        return;\n    }\n    int _777 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _777;\n    vec4 _781 = fa_light_texel(param_1);\n    vec2 _784 = _781.yz;\n    int _788 = int(_781.w);\n    int param_2 = _777 + 1;\n    vec4 _793 = fa_light_texel(param_2);\n    float _794 = _793.x;\n    int _800 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _804 = int(_763.z);\n    vec3 _1070;\n    for (int k = 0; k < _767; k++)\n    {\n        int _817 = _804 + k;\n        int param_3 = _788 + (_817 >> 2);\n        int _835 = (_777 + 2) + (int(fa_light_texel(param_3)[_817 & 3]) * 7);\n        int param_4 = _835 + 6;\n        vec4 _840 = fa_light_texel(param_4);\n        if (((int(_840.w + 0.5) >> _800) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _835;\n        vec4 _855 = fa_light_texel(param_5);\n        int param_6 = _835 + 1;\n        vec4 _860 = fa_light_texel(param_6);\n        int param_7 = _835 + 2;\n        vec4 _865 = fa_light_texel(param_7);\n        vec3 _868 = _855.xyz;\n        float _873 = dot(_868, world_pos) + _855.w;\n        vec3 _875 = _860.xyz;\n        float _880 = dot(_875, world_pos) + _860.w;\n        vec3 _882 = _865.xyz;\n        float _887 = dot(_882, world_pos) + _865.w;\n        bool _892 = abs(_873) > 0.5;\n        bool _900;\n        if (!_892)\n        {\n            _900 = abs(_880) > 0.5;\n        }\n        else\n        {\n            _900 = _892;\n        }\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_887) > 0.5;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        if (_908)\n        {\n            continue;\n        }\n        float _923 = clamp(dot(geo_normal, normalize(_882)) * _840.z, 0.0, 1.0);\n        if (_923 <= 0.0)\n        {\n            continue;\n        }\n        float _943 = (clamp((0.5 - abs(_887)) * 10.0, 0.0, 1.0) * _923) * _840.x;\n        vec2 _951 = vec2(_873 + 0.5, 0.5 - _880);\n        vec2 _961 = vec2(dot(_868, _756), dot(_875, _756));\n        vec2 _971 = vec2(dot(_868, _759), dot(_875, _759));\n        int param_8 = _835 + 5;\n        vec4 _976 = fa_light_texel(param_8);\n        int param_9 = _835 + 3;\n        vec4 _981 = fa_light_texel(param_9);\n        int param_10 = _835 + 4;\n        vec4 _986 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _976.xyz;\n        bool _996 = _981.z > _981.x;\n        if (_996)\n        {\n            vec4 param_11 = _981;\n            vec2 param_12 = _951;\n            vec2 param_13 = _784;\n            vec2 param_14 = _961;\n            vec2 param_15 = _971;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_794 > 0.5) && (_794 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1022 = fa_dc_to_linear(param_16);\n                vec4 _3583 = tx;\n                _3583.x = _1022.x;\n                _3583.y = _1022.y;\n                _3583.z = _1022.z;\n                tx = _3583;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_943 * tex_a) * _976.w, 0.0, 1.0)));\n        if (_986.z > _986.x)\n        {\n            vec4 param_17 = _986;\n            vec2 param_18 = _951;\n            vec2 param_19 = _784;\n            vec2 param_20 = _961;\n            vec2 param_21 = _971;\n            vec4 _1066 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_794 > 1.5)\n            {\n                vec3 param_22 = _1066.xyz;\n                vec3 _1076 = fa_dc_to_srgb(param_22);\n                _1070 = _1076;\n            }\n            else\n            {\n                _1070 = _1066.xyz;\n            }\n            vec3 _1086 = (_1070 * 2.0) - vec3(1.0);\n            vec2 _1091 = _1086.xy * _840.y;\n            vec3 _1113 = (normalize(_868) * _1091.x) + (normalize(_875) * _1091.y);\n            vec3 _1116 = normalize(normal);\n            normal = normalize(mix(_1116, normalize((_1116 * max(_1086.z, 0.0500000007450580596923828125)) + (_1113 - (_1116 * dot(_1116, _1113)))), vec3(clamp(_943 * (_996 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2333 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2333;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _333 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _339 = fa_light_texel(param_1);\n    float _342 = _339.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _348 = _342 < 0.5;\n    vec3 l;\n    if (_348)\n    {\n        l = normalize(_333.xyz);\n    }\n    else\n    {\n        vec3 _360 = _333.xyz - world_pos;\n        float _362 = length(_360);\n        dist = _362;\n        l = _360 / vec3(max(_362, 9.9999997473787516355514526367188e-05));\n        float _377 = _362 / max(_333.w, 0.001000000047497451305389404296875);\n        float _383 = clamp(1.0 - (_377 * _377), 0.0, 1.0);\n        atten = _383 * _383;\n        if (_342 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _397 = fa_light_texel(param_2);\n            float _407 = _397.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _413 = fa_light_texel(param_3);\n            float _414 = _413.x;\n            float cos_inner = _414;\n            if (_414 > 1.5)\n            {\n                cos_inner = mix(_407, 1.0, 0.25);\n            }\n            atten *= smoothstep(_407, cos_inner, dot(-l, normalize(_397.xyz)));\n        }\n    }\n    int _444;\n    if (_348)\n    {\n        _444 = 0;\n    }\n    else\n    {\n        _444 = (_342 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _339.xyz * atten, atten, 1.0, dist, _444);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1188;\n    if (i == 0)\n    {\n        _1188 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1204;\n        if (i == 1)\n        {\n            _1204 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1212;\n            if (i == 2)\n            {\n                _1212 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1212 = fa_shadows[24].w;\n            }\n            _1204 = _1212;\n        }\n        _1188 = _1204;\n    }\n    return _1188;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1245 = fa_shadow_depth(param, param_1);\n    float _1249;\n    if (conv.x < 0.5)\n    {\n        _1249 = _1245;\n    }\n    else\n    {\n        _1249 = (conv.y * conv.z) / (conv.z - (_1245 * (conv.z - conv.y)));\n    }\n    return _1249;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1176 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1176), sin(_1176)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1295 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1309 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1295;\n            vec2 _1328 = fa_shadow_vogel(param_3, param_4, param_5) * _1309;\n            vec2 param_6 = uv + (_1328 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1340 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1340 < (zr - (length(_1328) * plane)))\n            {\n                sum += _1340;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1384 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1384; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1384;\n        float param_11 = _1295;\n        vec2 _1403 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1403 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1403) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1384);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1445 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1450 = clamp(dot(n, l), 0.0, 1.0);\n    float _1456 = sqrt(1.0 - (_1450 * _1450));\n    float _1463 = min(_1456 / max(_1450, 0.20000000298023223876953125), 4.0);\n    float _1468;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1468 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1468 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1493 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1468 * _1456)), 1.0);\n    float _1500 = _1493.x;\n    bool _1503 = _1500 < fa_shadows[ci * 1 + 16].x;\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1500 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1521;\n    if (!_1512)\n    {\n        _1521 = _1493.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1521 = _1512;\n    }\n    bool _1530;\n    if (!_1521)\n    {\n        _1530 = _1493.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1530 = _1521;\n    }\n    bool _1537;\n    if (!_1530)\n    {\n        _1537 = _1493.z > 1.0;\n    }\n    else\n    {\n        _1537 = _1530;\n    }\n    if (_1537)\n    {\n        return -1.0;\n    }\n    float _1546;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1546 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1546 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1493.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1493.z - ((_1546 * (1.0 + (0.5 * _1463))) / _1445);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1445;\n    float param_5 = _1445 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1463, 3.0)) * 0.5) / _1445;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1973 = int(fa_shadows[25].x + 0.5);\n    if (_1973 < 1)\n    {\n        return 1.0;\n    }\n    float _1988 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1973 - 1;\n    if (_1988 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2000 = _1973 > 1;\n    bool _2007;\n    if (_2000)\n    {\n        _2007 = _1988 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2007 = _2000;\n    }\n    if (_2007)\n    {\n        ci = 1;\n    }\n    bool _2011 = _1973 > 2;\n    bool _2018;\n    if (_2011)\n    {\n        _2018 = _1988 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2018 = _2011;\n    }\n    if (_2018)\n    {\n        ci = 2;\n    }\n    bool _2022 = _1973 > 3;\n    bool _2029;\n    if (_2022)\n    {\n        _2029 = _1988 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2029 = _2022;\n    }\n    if (_2029)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1973)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2055 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2055;\n        if (_2055 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2080;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2080 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2080 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2099 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2080, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2110 = clamp((_1988 - (fa_shadow_split_at(param_7) - _2099)) / _2099, 0.0, 1.0);\n        if (_2110 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1973)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2131 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2131;\n                if (_2131 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2110);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1604 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1612;\n    if (!_1604)\n    {\n        _1612 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1612 = _1604;\n    }\n    if (_1612)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1625 = fa_light_texel(param);\n    float _1626 = _1625.x;\n    if (_1626 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1635 = int(_1626 + 0.5);\n    int param_1 = _1635;\n    vec4 _1639 = fa_light_texel(param_1);\n    int param_2 = _1635 + 1;\n    vec4 _1644 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1647 = _1639.y;\n    if (_1647 > 0.0)\n    {\n        float _1664 = 1.0 - smoothstep(0.75 * _1647, _1647, length(world - fa_shadows[27].xyz));\n        fade = _1664;\n        if (_1664 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1639.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1683 = world - fa_light_texel(param_3).xyz;\n        vec3 _1686 = abs(_1683);\n        float _1688 = _1686.x;\n        float _1690 = _1686.y;\n        bool _1691 = _1688 >= _1690;\n        bool _1699;\n        if (_1691)\n        {\n            _1699 = _1688 >= _1686.z;\n        }\n        else\n        {\n            _1699 = _1691;\n        }\n        int _1700;\n        if (_1699)\n        {\n            _1700 = (_1683.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1713;\n            if (_1690 >= _1686.z)\n            {\n                _1713 = (_1683.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1713 = (_1683.z > 0.0) ? 4 : 5;\n            }\n            _1700 = _1713;\n        }\n        face = _1700;\n    }\n    int _1732 = (_1635 + 2) + (face * 6);\n    int param_4 = _1732;\n    int param_5 = _1732 + 1;\n    int param_6 = _1732 + 3;\n    vec4 _1746 = fa_light_texel(param_6);\n    int param_7 = _1732 + 4;\n    vec4 _1751 = fa_light_texel(param_7);\n    int param_8 = _1732 + 5;\n    vec4 _1756 = fa_light_texel(param_8);\n    float _1768 = _1756.x * max(dot(_1746, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1773 = clamp(dot(n, l), 0.0, 1.0);\n    float _1796 = clamp(dot(n, _1746.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1819 = min(sqrt(1.0 - (_1796 * _1796)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1746, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1822 = _1644.y;\n    float _1824;\n    if (_1822 > 0.0)\n    {\n        _1824 = _1822;\n    }\n    else\n    {\n        _1824 = 1.5 * _1768;\n    }\n    vec4 _1844 = vec4(world + (n * (_1824 * sqrt(1.0 - (_1773 * _1773)))), 1.0);\n    float _1848 = dot(_1746, _1844);\n    float _1851 = _1756.y;\n    if (_1848 < _1851)\n    {\n        return 1.0;\n    }\n    vec2 _1866 = vec2(dot(fa_light_texel(param_4), _1844), dot(fa_light_texel(param_5), _1844)) / vec2(_1848);\n    float _1868 = _1866.x;\n    bool _1871 = _1868 < _1751.x;\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1868 > _1751.z;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    bool _1889;\n    if (!_1880)\n    {\n        _1889 = _1866.y < _1751.y;\n    }\n    else\n    {\n        _1889 = _1880;\n    }\n    bool _1898;\n    if (!_1889)\n    {\n        _1898 = _1866.y > _1751.w;\n    }\n    else\n    {\n        _1898 = _1889;\n    }\n    if (_1898)\n    {\n        return 1.0;\n    }\n    float _1904 = _1644.x;\n    float _1906;\n    if (_1904 > 0.0)\n    {\n        _1906 = _1904;\n    }\n    else\n    {\n        _1906 = 1.5 * _1768;\n    }\n    vec2 param_10 = _1866;\n    vec4 param_11 = _1751;\n    float param_12 = _1848 - (_1906 * (1.0 + (0.5 * _1819)));\n    float param_13 = _1768;\n    float param_14 = 1.0;\n    float param_15 = _1756.z * 0.25;\n    float param_16 = (_1768 * min(_1819, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1851, _1756.z);\n    int param_18 = int(_1639.z + 0.5);\n    float param_19 = _1639.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2447 = fa_lm.z > 0.5;\n    bool _2453;\n    if (_2447)\n    {\n        int param = li;\n        _2453 = fa_light_baked(param);\n    }\n    else\n    {\n        _2453 = _2447;\n    }\n    if (_2453)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2476 = fa_light_sample(param_2, param_3);\n    vec3 _3512 = _2476.direction;\n    vec3 _3507 = _2476.color;\n    float _3514 = _2476.attenuation;\n    float _3509 = _2476.shadow;\n    int _3517 = _2476.type;\n    if ((_3517 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3512;\n        float _2490 = fa_shadow_factor(param_4, param_5);\n        _3509 = _2490;\n        _3507 *= _2490;\n    }\n    else\n    {\n        bool _2501 = _3517 != 0;\n        bool _2507;\n        if (_2501)\n        {\n            _2507 = _3514 > 0.0;\n        }\n        else\n        {\n            _2507 = _2501;\n        }\n        if (_2507)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3512;\n            float _2519 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3509 = _2519;\n            _3507 *= _2519;\n        }\n    }\n    return LightSample(_3512, _3507, _3514, _3509, _2476._distance, _3517);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2155 = int(fa_shadows[25].x + 0.5);\n    float _2165 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2170 = _2155 > 0;\n    bool _2179;\n    if (_2170)\n    {\n        int param = _2155 - 1;\n        _2179 = _2165 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2179 = _2170;\n    }\n    if (_2179)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2186 = _2155 > 1;\n        bool _2193;\n        if (_2186)\n        {\n            _2193 = _2165 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2193 = _2186;\n        }\n        if (_2193)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2199 = _2155 > 2;\n        bool _2206;\n        if (_2199)\n        {\n            _2206 = _2165 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2206 = _2199;\n        }\n        if (_2206)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2212 = _2155 > 3;\n        bool _2219;\n        if (_2212)\n        {\n            _2219 = _2165 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2219 = _2212;\n        }\n        if (_2219)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3323 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3323 = -_3323;\n    }\n    vec3 _2908 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3323, fa_world_tangent, fa_uv, fa_vertex_color, _2908, gl_FrontFacing);\n    Surface _2916 = fa_standard_surface(param_1);\n    vec3 _3362 = _2916.albedo;\n    float _3363 = _2916.alpha;\n    vec3 _3364 = _2916.normal;\n    float _3365 = _2916.metallic;\n    float _3366 = _2916.roughness;\n    float _3367 = _2916.occlusion;\n    vec3 _3368 = _2916.emission;\n    float _3369 = _2916.clearcoat;\n    float _3370 = _2916.clearcoat_roughness;\n    vec3 _3371 = _2916.sheen_color;\n    float _3372 = _2916.sheen_roughness;\n    float _3373 = _2916.anisotropy;\n    float _3374 = _2916.anisotropy_rotation;\n    float _3375 = _2916.specular;\n    float _3376 = _2916.ior;\n    vec3 _3377 = _2916.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3323, fa_world_tangent, fa_uv, fa_vertex_color, _2908, gl_FrontFacing);\n    Surface param_3 = _2916;\n    surface(param_2, param_3);\n    _3362 = param_3.albedo;\n    _3363 = param_3.alpha;\n    _3364 = param_3.normal;\n    _3365 = param_3.metallic;\n    _3366 = param_3.roughness;\n    _3367 = param_3.occlusion;\n    _3368 = param_3.emission;\n    _3369 = param_3.clearcoat;\n    _3370 = param_3.clearcoat_roughness;\n    _3371 = param_3.sheen_color;\n    _3372 = param_3.sheen_roughness;\n    _3373 = param_3.anisotropy;\n    _3374 = param_3.anisotropy_rotation;\n    _3375 = param_3.specular;\n    _3376 = param_3.ior;\n    _3377 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3323;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3362 = param_6;\n    _3364 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3362;\n    }\n    else\n    {\n        vec3 _2954 = _3364;\n        vec3 _2955 = normalize(_2954);\n        _3364 = _2955;\n        vec3 param_8 = _2955;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _3323, fa_world_tangent, fa_uv, fa_vertex_color, _2908, gl_FrontFacing);\n        Surface param_10 = Surface(_3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375, _3376, _3377);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _2974 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2974; ln++)\n        {\n            int param_12 = ln;\n            int _2987 = fa_cl_light(param_12);\n            bool _2990 = fa_lm.z > 0.5;\n            bool _2996;\n            if (_2990)\n            {\n                int param_13 = _2987;\n                _2996 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _2996 = _2990;\n            }\n            if (_2996)\n            {\n                continue;\n            }\n            int param_14 = _2987;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3323;\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _3323, fa_world_tangent, fa_uv, fa_vertex_color, _2908, gl_FrontFacing);\n            Surface param_18 = Surface(_3362, _3363, _3364, _3365, _3366, _3367, _3368, _3369, _3370, _3371, _3372, _3373, _3374, _3375, _3376, _3377);\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _3023 = result;\n    vec3 _3024 = _3023 + _3368;\n    result = _3024;\n    vec3 param_20 = _3024;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3033 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3040;\n    if (!_3033)\n    {\n        _3040 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3040 = _3033;\n    }\n    if (_3040)\n    {\n        vec3 _3049 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3055 = dot(_3049, fa_mesh_fs_params[9].xyz);\n        bool _3059 = fa_mesh_fs_params[9].w > 0.5;\n        float _3060;\n        if (_3059)\n        {\n            _3060 = _3055;\n        }\n        else\n        {\n            _3060 = length(_3049);\n        }\n        float _3072 = _3060 - fa_mesh_fs_params[8].x;\n        if (_3072 > 0.0)\n        {\n            float _3081 = fa_mesh_fs_params[7].w * _3072;\n            float tau = _3081 * _3081;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3097;\n                if (_3059)\n                {\n                    _3097 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3055);\n                }\n                else\n                {\n                    _3097 = fa_mesh_fs_params[0].y;\n                }\n                float _3118 = mix(_3097, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3060, 0.0, 1.0));\n                float _3122 = fa_world_pos.y - _3118;\n                float _3127 = _3118 - fa_mesh_fs_params[8].z;\n                float _3132 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3135 = _3127 <= 0.0;\n                bool _3136 = !_3135;\n                bool _3142;\n                if (_3136)\n                {\n                    _3142 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3142 = _3135;\n                }\n                float _3143;\n                if (_3142)\n                {\n                    _3143 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3143 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3127, 80.0));\n                }\n                bool _3170;\n                if (_3136)\n                {\n                    _3170 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3170 = _3135;\n                }\n                float _3171;\n                if (_3170)\n                {\n                    _3171 = fa_mesh_fs_params[8].y * _3127;\n                }\n                else\n                {\n                    _3171 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3127, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3196 = _3132 <= 0.0;\n                bool _3203;\n                if (!_3196)\n                {\n                    _3203 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3203 = _3196;\n                }\n                float _3204;\n                if (_3203)\n                {\n                    _3204 = fa_mesh_fs_params[8].y * _3132;\n                }\n                else\n                {\n                    _3204 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3132, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3231;\n                if (abs(_3122) < 0.001000000047497451305389404296875)\n                {\n                    _3231 = _3143;\n                }\n                else\n                {\n                    _3231 = (_3204 - _3171) / _3122;\n                }\n                tau += (_3072 * max(_3231, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3363);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_458",
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
            "inst_name": "_1198",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_131",
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
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 24,
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
