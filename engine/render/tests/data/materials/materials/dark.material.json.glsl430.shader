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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _457 = fa_mesh_fs_params[19].x < 0.0;\n    bool _464;\n    if (!_457)\n    {\n        _464 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _464 = _457;\n    }\n    bool _472;\n    if (!_464)\n    {\n        _472 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _472 = _464;\n    }\n    bool _479;\n    if (!_472)\n    {\n        _479 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    if (_486)\n    {\n        return vec4(0.0);\n    }\n    vec4 _496 = vec4(world_pos, 1.0);\n    float _503 = dot(fa_mesh_fs_params[16], _496);\n    if (!(_503 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _525 = vec2(dot(fa_mesh_fs_params[14], _496), dot(fa_mesh_fs_params[15], _496)) / vec2(_503);\n    int _529 = int(fa_mesh_fs_params[18].x);\n    int _533 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _533) + clamp(int(floor(((_525.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _533 - 1)) * _529)) + clamp(int(floor(((_525.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _529 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _609 = fa_cluster_texel(param);\n    return ivec2(int(_609.x), int(_609.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2414 = fa_cluster_lookup(param);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _217;\n    if (i.front_facing)\n    {\n        _217 = i.world_normal;\n    }\n    else\n    {\n        _217 = -i.world_normal;\n    }\n    vec3 _241 = normalize(i.world_tangent.xyz - (_217 * dot(_217, i.world_tangent.xyz)));\n    vec3 _268 = normalize(((_241 * m.x) + ((cross(_217, _241) * i.world_tangent.w) * m.y)) + (_217 * m.z));\n    vec3 _271;\n    if (i.front_facing)\n    {\n        _271 = _268;\n    }\n    else\n    {\n        _271 = -_268;\n    }\n    return _271;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2601 = fa_tex_fix(param_2, param_3);\n    vec4 _3611 = base_t;\n    _3611.x = _2601.x;\n    _3611.y = _2601.y;\n    _3611.z = _2601.z;\n    base_t = _3611;\n    vec4 _2615 = (_3611 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3491 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2647 = fa_tex_fix(param_6, param_7);\n        vec3 _2650 = (_2647 * 2.0) - vec3(1.0);\n        vec2 _2655 = _2650.xy * fa_mesh_fs_params[6].x;\n        vec3 _3619 = _2650;\n        _3619.x = _2655.x;\n        _3619.y = _2655.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3619;\n        _3491 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2684 = fa_tex_fix(param_12, param_13);\n    vec4 _3622 = mrt;\n    _3622.x = _2684.x;\n    _3622.y = _2684.y;\n    _3622.z = _2684.z;\n    mrt = _3622;\n    vec4 _2712 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3496 = fa_mesh_fs_params[20].x;\n    float _3497 = fa_mesh_fs_params[20].y;\n    float _3500 = fa_mesh_fs_params[20].z;\n    float _3499 = fa_mesh_fs_params[21].w;\n    float _3502 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3496 *= _2724.y;\n            _3497 *= _2724.z;\n            _3499 *= _2712.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3500 *= mrt.x;\n            _3502 *= mrt.w;\n        }\n    }\n    return Surface(_2615.xyz, _2615.w, _3491, clamp(fa_mesh_fs_params[5].x * _2684.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2684.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2724.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2754), _3496, _3497, fa_mesh_fs_params[21].xyz, _3499, _3500, fa_mesh_fs_params[20].w, _3502, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _690 = rect.zw - rect.xy;\n    vec2 _694 = _690 * atlas;\n    vec2 _698 = ddx * _694;\n    vec2 _702 = ddy * _694;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _690), clamp(0.5 * log2(max(max(dot(_698, _698), dot(_702, _702)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _737 = fa_mesh_fs_params[10].y < 0.5;\n    bool _744;\n    if (!_737)\n    {\n        _744 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return;\n    }\n    vec3 _750 = dFdx(world_pos);\n    vec3 _753 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _757 = fa_cluster_texel(param);\n    int _761 = int(_757.w);\n    if (_761 < 1)\n    {\n        return;\n    }\n    int _771 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _771;\n    vec4 _775 = fa_light_texel(param_1);\n    vec2 _778 = _775.yz;\n    int _782 = int(_775.w);\n    int param_2 = _771 + 1;\n    vec4 _787 = fa_light_texel(param_2);\n    float _788 = _787.x;\n    int _794 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _798 = int(_757.z);\n    vec3 _1064;\n    for (int k = 0; k < _761; k++)\n    {\n        int _811 = _798 + k;\n        int param_3 = _782 + (_811 >> 2);\n        int _829 = (_771 + 2) + (int(fa_light_texel(param_3)[_811 & 3]) * 7);\n        int param_4 = _829 + 6;\n        vec4 _834 = fa_light_texel(param_4);\n        if (((int(_834.w + 0.5) >> _794) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _829;\n        vec4 _849 = fa_light_texel(param_5);\n        int param_6 = _829 + 1;\n        vec4 _854 = fa_light_texel(param_6);\n        int param_7 = _829 + 2;\n        vec4 _859 = fa_light_texel(param_7);\n        vec3 _862 = _849.xyz;\n        float _867 = dot(_862, world_pos) + _849.w;\n        vec3 _869 = _854.xyz;\n        float _874 = dot(_869, world_pos) + _854.w;\n        vec3 _876 = _859.xyz;\n        float _881 = dot(_876, world_pos) + _859.w;\n        bool _886 = abs(_867) > 0.5;\n        bool _894;\n        if (!_886)\n        {\n            _894 = abs(_874) > 0.5;\n        }\n        else\n        {\n            _894 = _886;\n        }\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_881) > 0.5;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        if (_902)\n        {\n            continue;\n        }\n        float _917 = clamp(dot(geo_normal, normalize(_876)) * _834.z, 0.0, 1.0);\n        if (_917 <= 0.0)\n        {\n            continue;\n        }\n        float _937 = (clamp((0.5 - abs(_881)) * 10.0, 0.0, 1.0) * _917) * _834.x;\n        vec2 _945 = vec2(_867 + 0.5, 0.5 - _874);\n        vec2 _955 = vec2(dot(_862, _750), dot(_869, _750));\n        vec2 _965 = vec2(dot(_862, _753), dot(_869, _753));\n        int param_8 = _829 + 5;\n        vec4 _970 = fa_light_texel(param_8);\n        int param_9 = _829 + 3;\n        vec4 _975 = fa_light_texel(param_9);\n        int param_10 = _829 + 4;\n        vec4 _980 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _970.xyz;\n        bool _990 = _975.z > _975.x;\n        if (_990)\n        {\n            vec4 param_11 = _975;\n            vec2 param_12 = _945;\n            vec2 param_13 = _778;\n            vec2 param_14 = _955;\n            vec2 param_15 = _965;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_788 > 0.5) && (_788 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1016 = fa_dc_to_linear(param_16);\n                vec4 _3547 = tx;\n                _3547.x = _1016.x;\n                _3547.y = _1016.y;\n                _3547.z = _1016.z;\n                tx = _3547;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_937 * tex_a) * _970.w, 0.0, 1.0)));\n        if (_980.z > _980.x)\n        {\n            vec4 param_17 = _980;\n            vec2 param_18 = _945;\n            vec2 param_19 = _778;\n            vec2 param_20 = _955;\n            vec2 param_21 = _965;\n            vec4 _1060 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_788 > 1.5)\n            {\n                vec3 param_22 = _1060.xyz;\n                vec3 _1070 = fa_dc_to_srgb(param_22);\n                _1064 = _1070;\n            }\n            else\n            {\n                _1064 = _1060.xyz;\n            }\n            vec3 _1080 = (_1064 * 2.0) - vec3(1.0);\n            vec2 _1085 = _1080.xy * _834.y;\n            vec3 _1107 = (normalize(_862) * _1085.x) + (normalize(_869) * _1085.y);\n            vec3 _1110 = normalize(normal);\n            normal = normalize(mix(_1110, normalize((_1110 * max(_1080.z, 0.0500000007450580596923828125)) + (_1107 - (_1110 * dot(_1110, _1107)))), vec3(clamp(_937 * (_990 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2327 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2327;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _327 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _333 = fa_light_texel(param_1);\n    float _336 = _333.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _342 = _336 < 0.5;\n    vec3 l;\n    if (_342)\n    {\n        l = normalize(_327.xyz);\n    }\n    else\n    {\n        vec3 _354 = _327.xyz - world_pos;\n        float _356 = length(_354);\n        dist = _356;\n        l = _354 / vec3(max(_356, 9.9999997473787516355514526367188e-05));\n        float _371 = _356 / max(_327.w, 0.001000000047497451305389404296875);\n        float _377 = clamp(1.0 - (_371 * _371), 0.0, 1.0);\n        atten = _377 * _377;\n        if (_336 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _391 = fa_light_texel(param_2);\n            float _401 = _391.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _407 = fa_light_texel(param_3);\n            float _408 = _407.x;\n            float cos_inner = _408;\n            if (_408 > 1.5)\n            {\n                cos_inner = mix(_401, 1.0, 0.25);\n            }\n            atten *= smoothstep(_401, cos_inner, dot(-l, normalize(_391.xyz)));\n        }\n    }\n    int _438;\n    if (_342)\n    {\n        _438 = 0;\n    }\n    else\n    {\n        _438 = (_336 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _333.xyz * atten, atten, 1.0, dist, _438);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1182;\n    if (i == 0)\n    {\n        _1182 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1198;\n        if (i == 1)\n        {\n            _1198 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1206;\n            if (i == 2)\n            {\n                _1206 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1206 = fa_shadows[24].w;\n            }\n            _1198 = _1206;\n        }\n        _1182 = _1198;\n    }\n    return _1182;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1239 = fa_shadow_depth(param, param_1);\n    float _1243;\n    if (conv.x < 0.5)\n    {\n        _1243 = _1239;\n    }\n    else\n    {\n        _1243 = (conv.y * conv.z) / (conv.z - (_1239 * (conv.z - conv.y)));\n    }\n    return _1243;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1170 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1170), sin(_1170)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1289 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1303 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1289;\n            vec2 _1322 = fa_shadow_vogel(param_3, param_4, param_5) * _1303;\n            vec2 param_6 = uv + (_1322 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1334 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1334 < (zr - (length(_1322) * plane)))\n            {\n                sum += _1334;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1378; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1378;\n        float param_11 = _1289;\n        vec2 _1397 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1397 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1397) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1378);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1439 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1444 = clamp(dot(n, l), 0.0, 1.0);\n    float _1450 = sqrt(1.0 - (_1444 * _1444));\n    float _1457 = min(_1450 / max(_1444, 0.20000000298023223876953125), 4.0);\n    float _1462;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1462 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1462 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1487 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1462 * _1450)), 1.0);\n    float _1494 = _1487.x;\n    bool _1497 = _1494 < fa_shadows[ci * 1 + 16].x;\n    bool _1506;\n    if (!_1497)\n    {\n        _1506 = _1494 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1506 = _1497;\n    }\n    bool _1515;\n    if (!_1506)\n    {\n        _1515 = _1487.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1515 = _1506;\n    }\n    bool _1524;\n    if (!_1515)\n    {\n        _1524 = _1487.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1524 = _1515;\n    }\n    bool _1531;\n    if (!_1524)\n    {\n        _1531 = _1487.z > 1.0;\n    }\n    else\n    {\n        _1531 = _1524;\n    }\n    if (_1531)\n    {\n        return -1.0;\n    }\n    float _1540;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1540 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1540 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1487.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1487.z - ((_1540 * (1.0 + (0.5 * _1457))) / _1439);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1439;\n    float param_5 = _1439 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1457, 3.0)) * 0.5) / _1439;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1967 = int(fa_shadows[25].x + 0.5);\n    if (_1967 < 1)\n    {\n        return 1.0;\n    }\n    float _1982 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1967 - 1;\n    if (_1982 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1994 = _1967 > 1;\n    bool _2001;\n    if (_1994)\n    {\n        _2001 = _1982 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2001 = _1994;\n    }\n    if (_2001)\n    {\n        ci = 1;\n    }\n    bool _2005 = _1967 > 2;\n    bool _2012;\n    if (_2005)\n    {\n        _2012 = _1982 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2012 = _2005;\n    }\n    if (_2012)\n    {\n        ci = 2;\n    }\n    bool _2016 = _1967 > 3;\n    bool _2023;\n    if (_2016)\n    {\n        _2023 = _1982 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2023 = _2016;\n    }\n    if (_2023)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1967)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2049 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2049;\n        if (_2049 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2074;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2074 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2074 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2093 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2074, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2104 = clamp((_1982 - (fa_shadow_split_at(param_7) - _2093)) / _2093, 0.0, 1.0);\n        if (_2104 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1967)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2125 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2125;\n                if (_2125 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2104);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1598 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    if (_1606)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1619 = fa_light_texel(param);\n    float _1620 = _1619.x;\n    if (_1620 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1629 = int(_1620 + 0.5);\n    int param_1 = _1629;\n    vec4 _1633 = fa_light_texel(param_1);\n    int param_2 = _1629 + 1;\n    vec4 _1638 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1641 = _1633.y;\n    if (_1641 > 0.0)\n    {\n        float _1658 = 1.0 - smoothstep(0.75 * _1641, _1641, length(world - fa_shadows[27].xyz));\n        fade = _1658;\n        if (_1658 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1633.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1677 = world - fa_light_texel(param_3).xyz;\n        vec3 _1680 = abs(_1677);\n        float _1682 = _1680.x;\n        float _1684 = _1680.y;\n        bool _1685 = _1682 >= _1684;\n        bool _1693;\n        if (_1685)\n        {\n            _1693 = _1682 >= _1680.z;\n        }\n        else\n        {\n            _1693 = _1685;\n        }\n        int _1694;\n        if (_1693)\n        {\n            _1694 = (_1677.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1707;\n            if (_1684 >= _1680.z)\n            {\n                _1707 = (_1677.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1707 = (_1677.z > 0.0) ? 4 : 5;\n            }\n            _1694 = _1707;\n        }\n        face = _1694;\n    }\n    int _1726 = (_1629 + 2) + (face * 6);\n    int param_4 = _1726;\n    int param_5 = _1726 + 1;\n    int param_6 = _1726 + 3;\n    vec4 _1740 = fa_light_texel(param_6);\n    int param_7 = _1726 + 4;\n    vec4 _1745 = fa_light_texel(param_7);\n    int param_8 = _1726 + 5;\n    vec4 _1750 = fa_light_texel(param_8);\n    float _1762 = _1750.x * max(dot(_1740, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1767 = clamp(dot(n, l), 0.0, 1.0);\n    float _1790 = clamp(dot(n, _1740.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1813 = min(sqrt(1.0 - (_1790 * _1790)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1740, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1816 = _1638.y;\n    float _1818;\n    if (_1816 > 0.0)\n    {\n        _1818 = _1816;\n    }\n    else\n    {\n        _1818 = 1.5 * _1762;\n    }\n    vec4 _1838 = vec4(world + (n * (_1818 * sqrt(1.0 - (_1767 * _1767)))), 1.0);\n    float _1842 = dot(_1740, _1838);\n    float _1845 = _1750.y;\n    if (_1842 < _1845)\n    {\n        return 1.0;\n    }\n    vec2 _1860 = vec2(dot(fa_light_texel(param_4), _1838), dot(fa_light_texel(param_5), _1838)) / vec2(_1842);\n    float _1862 = _1860.x;\n    bool _1865 = _1862 < _1745.x;\n    bool _1874;\n    if (!_1865)\n    {\n        _1874 = _1862 > _1745.z;\n    }\n    else\n    {\n        _1874 = _1865;\n    }\n    bool _1883;\n    if (!_1874)\n    {\n        _1883 = _1860.y < _1745.y;\n    }\n    else\n    {\n        _1883 = _1874;\n    }\n    bool _1892;\n    if (!_1883)\n    {\n        _1892 = _1860.y > _1745.w;\n    }\n    else\n    {\n        _1892 = _1883;\n    }\n    if (_1892)\n    {\n        return 1.0;\n    }\n    float _1898 = _1638.x;\n    float _1900;\n    if (_1898 > 0.0)\n    {\n        _1900 = _1898;\n    }\n    else\n    {\n        _1900 = 1.5 * _1762;\n    }\n    vec2 param_10 = _1860;\n    vec4 param_11 = _1745;\n    float param_12 = _1842 - (_1900 * (1.0 + (0.5 * _1813)));\n    float param_13 = _1762;\n    float param_14 = 1.0;\n    float param_15 = _1750.z * 0.25;\n    float param_16 = (_1762 * min(_1813, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1845, _1750.z);\n    int param_18 = int(_1633.z + 0.5);\n    float param_19 = _1633.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2441 = fa_lm.z > 0.5;\n    bool _2447;\n    if (_2441)\n    {\n        int param = li;\n        _2447 = fa_light_baked(param);\n    }\n    else\n    {\n        _2447 = _2441;\n    }\n    if (_2447)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2470 = fa_light_sample(param_2, param_3);\n    vec3 _3476 = _2470.direction;\n    vec3 _3471 = _2470.color;\n    float _3478 = _2470.attenuation;\n    float _3473 = _2470.shadow;\n    int _3481 = _2470.type;\n    if ((_3481 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3476;\n        float _2484 = fa_shadow_factor(param_4, param_5);\n        _3473 = _2484;\n        _3471 *= _2484;\n    }\n    else\n    {\n        bool _2495 = _3481 != 0;\n        bool _2501;\n        if (_2495)\n        {\n            _2501 = _3478 > 0.0;\n        }\n        else\n        {\n            _2501 = _2495;\n        }\n        if (_2501)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3476;\n            float _2513 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3473 = _2513;\n            _3471 *= _2513;\n        }\n    }\n    return LightSample(_3476, _3471, _3478, _3473, _2470._distance, _3481);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2149 = int(fa_shadows[25].x + 0.5);\n    float _2159 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2164 = _2149 > 0;\n    bool _2173;\n    if (_2164)\n    {\n        int param = _2149 - 1;\n        _2173 = _2159 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2173 = _2164;\n    }\n    if (_2173)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2180 = _2149 > 1;\n        bool _2187;\n        if (_2180)\n        {\n            _2187 = _2159 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2187 = _2180;\n        }\n        if (_2187)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2193 = _2149 > 2;\n        bool _2200;\n        if (_2193)\n        {\n            _2200 = _2159 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2200 = _2193;\n        }\n        if (_2200)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2206 = _2149 > 3;\n        bool _2213;\n        if (_2206)\n        {\n            _2213 = _2159 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2213 = _2206;\n        }\n        if (_2213)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3312 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3312 = -_3312;\n    }\n    vec3 _2897 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing);\n    Surface _2905 = fa_standard_surface(param_1);\n    vec3 _3343 = _2905.albedo;\n    float _3344 = _2905.alpha;\n    vec3 _3345 = _2905.normal;\n    float _3346 = _2905.metallic;\n    float _3347 = _2905.roughness;\n    float _3348 = _2905.occlusion;\n    vec3 _3349 = _2905.emission;\n    float _3350 = _2905.clearcoat;\n    float _3351 = _2905.clearcoat_roughness;\n    vec3 _3352 = _2905.sheen_color;\n    float _3353 = _2905.sheen_roughness;\n    float _3354 = _2905.anisotropy;\n    float _3355 = _2905.anisotropy_rotation;\n    float _3356 = _2905.specular;\n    float _3357 = _2905.ior;\n    vec3 _3358 = _2905.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing);\n    Surface param_3 = _2905;\n    surface(param_2, param_3);\n    _3343 = param_3.albedo;\n    _3344 = param_3.alpha;\n    _3345 = param_3.normal;\n    _3346 = param_3.metallic;\n    _3347 = param_3.roughness;\n    _3348 = param_3.occlusion;\n    _3349 = param_3.emission;\n    _3350 = param_3.clearcoat;\n    _3351 = param_3.clearcoat_roughness;\n    _3352 = param_3.sheen_color;\n    _3353 = param_3.sheen_roughness;\n    _3354 = param_3.anisotropy;\n    _3355 = param_3.anisotropy_rotation;\n    _3356 = param_3.specular;\n    _3357 = param_3.ior;\n    _3358 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3312;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3343 = param_6;\n    _3345 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3343;\n    }\n    else\n    {\n        vec3 _2943 = _3345;\n        vec3 _2944 = normalize(_2943);\n        _3345 = _2944;\n        vec3 param_8 = _2944;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _3343) * _3348;\n        int _2963 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2963; ln++)\n        {\n            int param_9 = ln;\n            int _2976 = fa_cl_light(param_9);\n            bool _2979 = fa_lm.z > 0.5;\n            bool _2985;\n            if (_2979)\n            {\n                int param_10 = _2976;\n                _2985 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _2985 = _2979;\n            }\n            if (_2985)\n            {\n                continue;\n            }\n            int param_11 = _2976;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _3312;\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing);\n            Surface param_15 = Surface(_3343, _3344, _3345, _3346, _3347, _3348, _3349, _3350, _3351, _3352, _3353, _3354, _3355, _3356, _3357, _3358);\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3012 = result;\n    vec3 _3013 = _3012 + _3349;\n    result = _3013;\n    vec3 param_17 = _3013;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3022 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3029;\n    if (!_3022)\n    {\n        _3029 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3029 = _3022;\n    }\n    if (_3029)\n    {\n        vec3 _3038 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3044 = dot(_3038, fa_mesh_fs_params[9].xyz);\n        bool _3048 = fa_mesh_fs_params[9].w > 0.5;\n        float _3049;\n        if (_3048)\n        {\n            _3049 = _3044;\n        }\n        else\n        {\n            _3049 = length(_3038);\n        }\n        float _3061 = _3049 - fa_mesh_fs_params[8].x;\n        if (_3061 > 0.0)\n        {\n            float _3070 = fa_mesh_fs_params[7].w * _3061;\n            float tau = _3070 * _3070;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3086;\n                if (_3048)\n                {\n                    _3086 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3044);\n                }\n                else\n                {\n                    _3086 = fa_mesh_fs_params[0].y;\n                }\n                float _3107 = mix(_3086, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3049, 0.0, 1.0));\n                float _3111 = fa_world_pos.y - _3107;\n                float _3116 = _3107 - fa_mesh_fs_params[8].z;\n                float _3121 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3124 = _3116 <= 0.0;\n                bool _3125 = !_3124;\n                bool _3131;\n                if (_3125)\n                {\n                    _3131 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3131 = _3124;\n                }\n                float _3132;\n                if (_3131)\n                {\n                    _3132 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3132 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3116, 80.0));\n                }\n                bool _3159;\n                if (_3125)\n                {\n                    _3159 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3159 = _3124;\n                }\n                float _3160;\n                if (_3159)\n                {\n                    _3160 = fa_mesh_fs_params[8].y * _3116;\n                }\n                else\n                {\n                    _3160 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3116, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3185 = _3121 <= 0.0;\n                bool _3192;\n                if (!_3185)\n                {\n                    _3192 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3192 = _3185;\n                }\n                float _3193;\n                if (_3192)\n                {\n                    _3193 = fa_mesh_fs_params[8].y * _3121;\n                }\n                else\n                {\n                    _3193 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3121, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3220;\n                if (abs(_3111) < 0.001000000047497451305389404296875)\n                {\n                    _3220 = _3132;\n                }\n                else\n                {\n                    _3220 = (_3193 - _3160) / _3111;\n                }\n                tau += (_3061 * max(_3220, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3344);\n}\n\n",
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
            "inst_name": "_452",
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
            "inst_name": "_1192",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _457 = fa_mesh_fs_params[19].x < 0.0;\n    bool _464;\n    if (!_457)\n    {\n        _464 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _464 = _457;\n    }\n    bool _472;\n    if (!_464)\n    {\n        _472 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _472 = _464;\n    }\n    bool _479;\n    if (!_472)\n    {\n        _479 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _479 = _472;\n    }\n    bool _486;\n    if (!_479)\n    {\n        _486 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _486 = _479;\n    }\n    if (_486)\n    {\n        return vec4(0.0);\n    }\n    vec4 _496 = vec4(world_pos, 1.0);\n    float _503 = dot(fa_mesh_fs_params[16], _496);\n    if (!(_503 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _525 = vec2(dot(fa_mesh_fs_params[14], _496), dot(fa_mesh_fs_params[15], _496)) / vec2(_503);\n    int _529 = int(fa_mesh_fs_params[18].x);\n    int _533 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _533) + clamp(int(floor(((_525.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _533 - 1)) * _529)) + clamp(int(floor(((_525.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _529 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _609 = fa_cluster_texel(param);\n    return ivec2(int(_609.x), int(_609.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2414 = fa_cluster_lookup(param);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _217;\n    if (i.front_facing)\n    {\n        _217 = i.world_normal;\n    }\n    else\n    {\n        _217 = -i.world_normal;\n    }\n    vec3 _241 = normalize(i.world_tangent.xyz - (_217 * dot(_217, i.world_tangent.xyz)));\n    vec3 _268 = normalize(((_241 * m.x) + ((cross(_217, _241) * i.world_tangent.w) * m.y)) + (_217 * m.z));\n    vec3 _271;\n    if (i.front_facing)\n    {\n        _271 = _268;\n    }\n    else\n    {\n        _271 = -_268;\n    }\n    return _271;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2601 = fa_tex_fix(param_2, param_3);\n    vec4 _3611 = base_t;\n    _3611.x = _2601.x;\n    _3611.y = _2601.y;\n    _3611.z = _2601.z;\n    base_t = _3611;\n    vec4 _2615 = (_3611 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3491 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2647 = fa_tex_fix(param_6, param_7);\n        vec3 _2650 = (_2647 * 2.0) - vec3(1.0);\n        vec2 _2655 = _2650.xy * fa_mesh_fs_params[6].x;\n        vec3 _3619 = _2650;\n        _3619.x = _2655.x;\n        _3619.y = _2655.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3619;\n        _3491 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2684 = fa_tex_fix(param_12, param_13);\n    vec4 _3622 = mrt;\n    _3622.x = _2684.x;\n    _3622.y = _2684.y;\n    _3622.z = _2684.z;\n    mrt = _3622;\n    vec4 _2712 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3496 = fa_mesh_fs_params[20].x;\n    float _3497 = fa_mesh_fs_params[20].y;\n    float _3500 = fa_mesh_fs_params[20].z;\n    float _3499 = fa_mesh_fs_params[21].w;\n    float _3502 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3496 *= _2724.y;\n            _3497 *= _2724.z;\n            _3499 *= _2712.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3500 *= mrt.x;\n            _3502 *= mrt.w;\n        }\n    }\n    return Surface(_2615.xyz, _2615.w, _3491, clamp(fa_mesh_fs_params[5].x * _2684.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2684.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2724.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2754), _3496, _3497, fa_mesh_fs_params[21].xyz, _3499, _3500, fa_mesh_fs_params[20].w, _3502, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _690 = rect.zw - rect.xy;\n    vec2 _694 = _690 * atlas;\n    vec2 _698 = ddx * _694;\n    vec2 _702 = ddy * _694;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _690), clamp(0.5 * log2(max(max(dot(_698, _698), dot(_702, _702)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _737 = fa_mesh_fs_params[10].y < 0.5;\n    bool _744;\n    if (!_737)\n    {\n        _744 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _744 = _737;\n    }\n    if (_744)\n    {\n        return;\n    }\n    vec3 _750 = dFdx(world_pos);\n    vec3 _753 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _757 = fa_cluster_texel(param);\n    int _761 = int(_757.w);\n    if (_761 < 1)\n    {\n        return;\n    }\n    int _771 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _771;\n    vec4 _775 = fa_light_texel(param_1);\n    vec2 _778 = _775.yz;\n    int _782 = int(_775.w);\n    int param_2 = _771 + 1;\n    vec4 _787 = fa_light_texel(param_2);\n    float _788 = _787.x;\n    int _794 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _798 = int(_757.z);\n    vec3 _1064;\n    for (int k = 0; k < _761; k++)\n    {\n        int _811 = _798 + k;\n        int param_3 = _782 + (_811 >> 2);\n        int _829 = (_771 + 2) + (int(fa_light_texel(param_3)[_811 & 3]) * 7);\n        int param_4 = _829 + 6;\n        vec4 _834 = fa_light_texel(param_4);\n        if (((int(_834.w + 0.5) >> _794) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _829;\n        vec4 _849 = fa_light_texel(param_5);\n        int param_6 = _829 + 1;\n        vec4 _854 = fa_light_texel(param_6);\n        int param_7 = _829 + 2;\n        vec4 _859 = fa_light_texel(param_7);\n        vec3 _862 = _849.xyz;\n        float _867 = dot(_862, world_pos) + _849.w;\n        vec3 _869 = _854.xyz;\n        float _874 = dot(_869, world_pos) + _854.w;\n        vec3 _876 = _859.xyz;\n        float _881 = dot(_876, world_pos) + _859.w;\n        bool _886 = abs(_867) > 0.5;\n        bool _894;\n        if (!_886)\n        {\n            _894 = abs(_874) > 0.5;\n        }\n        else\n        {\n            _894 = _886;\n        }\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_881) > 0.5;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        if (_902)\n        {\n            continue;\n        }\n        float _917 = clamp(dot(geo_normal, normalize(_876)) * _834.z, 0.0, 1.0);\n        if (_917 <= 0.0)\n        {\n            continue;\n        }\n        float _937 = (clamp((0.5 - abs(_881)) * 10.0, 0.0, 1.0) * _917) * _834.x;\n        vec2 _945 = vec2(_867 + 0.5, 0.5 - _874);\n        vec2 _955 = vec2(dot(_862, _750), dot(_869, _750));\n        vec2 _965 = vec2(dot(_862, _753), dot(_869, _753));\n        int param_8 = _829 + 5;\n        vec4 _970 = fa_light_texel(param_8);\n        int param_9 = _829 + 3;\n        vec4 _975 = fa_light_texel(param_9);\n        int param_10 = _829 + 4;\n        vec4 _980 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _970.xyz;\n        bool _990 = _975.z > _975.x;\n        if (_990)\n        {\n            vec4 param_11 = _975;\n            vec2 param_12 = _945;\n            vec2 param_13 = _778;\n            vec2 param_14 = _955;\n            vec2 param_15 = _965;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_788 > 0.5) && (_788 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1016 = fa_dc_to_linear(param_16);\n                vec4 _3547 = tx;\n                _3547.x = _1016.x;\n                _3547.y = _1016.y;\n                _3547.z = _1016.z;\n                tx = _3547;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_937 * tex_a) * _970.w, 0.0, 1.0)));\n        if (_980.z > _980.x)\n        {\n            vec4 param_17 = _980;\n            vec2 param_18 = _945;\n            vec2 param_19 = _778;\n            vec2 param_20 = _955;\n            vec2 param_21 = _965;\n            vec4 _1060 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_788 > 1.5)\n            {\n                vec3 param_22 = _1060.xyz;\n                vec3 _1070 = fa_dc_to_srgb(param_22);\n                _1064 = _1070;\n            }\n            else\n            {\n                _1064 = _1060.xyz;\n            }\n            vec3 _1080 = (_1064 * 2.0) - vec3(1.0);\n            vec2 _1085 = _1080.xy * _834.y;\n            vec3 _1107 = (normalize(_862) * _1085.x) + (normalize(_869) * _1085.y);\n            vec3 _1110 = normalize(normal);\n            normal = normalize(mix(_1110, normalize((_1110 * max(_1080.z, 0.0500000007450580596923828125)) + (_1107 - (_1110 * dot(_1110, _1107)))), vec3(clamp(_937 * (_990 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2327 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2327;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _327 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _333 = fa_light_texel(param_1);\n    float _336 = _333.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _342 = _336 < 0.5;\n    vec3 l;\n    if (_342)\n    {\n        l = normalize(_327.xyz);\n    }\n    else\n    {\n        vec3 _354 = _327.xyz - world_pos;\n        float _356 = length(_354);\n        dist = _356;\n        l = _354 / vec3(max(_356, 9.9999997473787516355514526367188e-05));\n        float _371 = _356 / max(_327.w, 0.001000000047497451305389404296875);\n        float _377 = clamp(1.0 - (_371 * _371), 0.0, 1.0);\n        atten = _377 * _377;\n        if (_336 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _391 = fa_light_texel(param_2);\n            float _401 = _391.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _407 = fa_light_texel(param_3);\n            float _408 = _407.x;\n            float cos_inner = _408;\n            if (_408 > 1.5)\n            {\n                cos_inner = mix(_401, 1.0, 0.25);\n            }\n            atten *= smoothstep(_401, cos_inner, dot(-l, normalize(_391.xyz)));\n        }\n    }\n    int _438;\n    if (_342)\n    {\n        _438 = 0;\n    }\n    else\n    {\n        _438 = (_336 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _333.xyz * atten, atten, 1.0, dist, _438);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1182;\n    if (i == 0)\n    {\n        _1182 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1198;\n        if (i == 1)\n        {\n            _1198 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1206;\n            if (i == 2)\n            {\n                _1206 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1206 = fa_shadows[24].w;\n            }\n            _1198 = _1206;\n        }\n        _1182 = _1198;\n    }\n    return _1182;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1239 = fa_shadow_depth(param, param_1);\n    float _1243;\n    if (conv.x < 0.5)\n    {\n        _1243 = _1239;\n    }\n    else\n    {\n        _1243 = (conv.y * conv.z) / (conv.z - (_1239 * (conv.z - conv.y)));\n    }\n    return _1243;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1170 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1170), sin(_1170)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1289 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1303 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1289;\n            vec2 _1322 = fa_shadow_vogel(param_3, param_4, param_5) * _1303;\n            vec2 param_6 = uv + (_1322 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1334 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1334 < (zr - (length(_1322) * plane)))\n            {\n                sum += _1334;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1378; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1378;\n        float param_11 = _1289;\n        vec2 _1397 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1397 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1397) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1378);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1439 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1444 = clamp(dot(n, l), 0.0, 1.0);\n    float _1450 = sqrt(1.0 - (_1444 * _1444));\n    float _1457 = min(_1450 / max(_1444, 0.20000000298023223876953125), 4.0);\n    float _1462;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1462 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1462 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1487 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1462 * _1450)), 1.0);\n    float _1494 = _1487.x;\n    bool _1497 = _1494 < fa_shadows[ci * 1 + 16].x;\n    bool _1506;\n    if (!_1497)\n    {\n        _1506 = _1494 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1506 = _1497;\n    }\n    bool _1515;\n    if (!_1506)\n    {\n        _1515 = _1487.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1515 = _1506;\n    }\n    bool _1524;\n    if (!_1515)\n    {\n        _1524 = _1487.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1524 = _1515;\n    }\n    bool _1531;\n    if (!_1524)\n    {\n        _1531 = _1487.z > 1.0;\n    }\n    else\n    {\n        _1531 = _1524;\n    }\n    if (_1531)\n    {\n        return -1.0;\n    }\n    float _1540;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1540 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1540 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1487.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1487.z - ((_1540 * (1.0 + (0.5 * _1457))) / _1439);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1439;\n    float param_5 = _1439 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1457, 3.0)) * 0.5) / _1439;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1967 = int(fa_shadows[25].x + 0.5);\n    if (_1967 < 1)\n    {\n        return 1.0;\n    }\n    float _1982 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1967 - 1;\n    if (_1982 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1994 = _1967 > 1;\n    bool _2001;\n    if (_1994)\n    {\n        _2001 = _1982 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2001 = _1994;\n    }\n    if (_2001)\n    {\n        ci = 1;\n    }\n    bool _2005 = _1967 > 2;\n    bool _2012;\n    if (_2005)\n    {\n        _2012 = _1982 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2012 = _2005;\n    }\n    if (_2012)\n    {\n        ci = 2;\n    }\n    bool _2016 = _1967 > 3;\n    bool _2023;\n    if (_2016)\n    {\n        _2023 = _1982 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2023 = _2016;\n    }\n    if (_2023)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1967)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2049 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2049;\n        if (_2049 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2074;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2074 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2074 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2093 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2074, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2104 = clamp((_1982 - (fa_shadow_split_at(param_7) - _2093)) / _2093, 0.0, 1.0);\n        if (_2104 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1967)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2125 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2125;\n                if (_2125 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2104);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1598 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1606;\n    if (!_1598)\n    {\n        _1606 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1606 = _1598;\n    }\n    if (_1606)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1619 = fa_light_texel(param);\n    float _1620 = _1619.x;\n    if (_1620 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1629 = int(_1620 + 0.5);\n    int param_1 = _1629;\n    vec4 _1633 = fa_light_texel(param_1);\n    int param_2 = _1629 + 1;\n    vec4 _1638 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1641 = _1633.y;\n    if (_1641 > 0.0)\n    {\n        float _1658 = 1.0 - smoothstep(0.75 * _1641, _1641, length(world - fa_shadows[27].xyz));\n        fade = _1658;\n        if (_1658 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1633.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1677 = world - fa_light_texel(param_3).xyz;\n        vec3 _1680 = abs(_1677);\n        float _1682 = _1680.x;\n        float _1684 = _1680.y;\n        bool _1685 = _1682 >= _1684;\n        bool _1693;\n        if (_1685)\n        {\n            _1693 = _1682 >= _1680.z;\n        }\n        else\n        {\n            _1693 = _1685;\n        }\n        int _1694;\n        if (_1693)\n        {\n            _1694 = (_1677.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1707;\n            if (_1684 >= _1680.z)\n            {\n                _1707 = (_1677.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1707 = (_1677.z > 0.0) ? 4 : 5;\n            }\n            _1694 = _1707;\n        }\n        face = _1694;\n    }\n    int _1726 = (_1629 + 2) + (face * 6);\n    int param_4 = _1726;\n    int param_5 = _1726 + 1;\n    int param_6 = _1726 + 3;\n    vec4 _1740 = fa_light_texel(param_6);\n    int param_7 = _1726 + 4;\n    vec4 _1745 = fa_light_texel(param_7);\n    int param_8 = _1726 + 5;\n    vec4 _1750 = fa_light_texel(param_8);\n    float _1762 = _1750.x * max(dot(_1740, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1767 = clamp(dot(n, l), 0.0, 1.0);\n    float _1790 = clamp(dot(n, _1740.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1813 = min(sqrt(1.0 - (_1790 * _1790)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1740, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1816 = _1638.y;\n    float _1818;\n    if (_1816 > 0.0)\n    {\n        _1818 = _1816;\n    }\n    else\n    {\n        _1818 = 1.5 * _1762;\n    }\n    vec4 _1838 = vec4(world + (n * (_1818 * sqrt(1.0 - (_1767 * _1767)))), 1.0);\n    float _1842 = dot(_1740, _1838);\n    float _1845 = _1750.y;\n    if (_1842 < _1845)\n    {\n        return 1.0;\n    }\n    vec2 _1860 = vec2(dot(fa_light_texel(param_4), _1838), dot(fa_light_texel(param_5), _1838)) / vec2(_1842);\n    float _1862 = _1860.x;\n    bool _1865 = _1862 < _1745.x;\n    bool _1874;\n    if (!_1865)\n    {\n        _1874 = _1862 > _1745.z;\n    }\n    else\n    {\n        _1874 = _1865;\n    }\n    bool _1883;\n    if (!_1874)\n    {\n        _1883 = _1860.y < _1745.y;\n    }\n    else\n    {\n        _1883 = _1874;\n    }\n    bool _1892;\n    if (!_1883)\n    {\n        _1892 = _1860.y > _1745.w;\n    }\n    else\n    {\n        _1892 = _1883;\n    }\n    if (_1892)\n    {\n        return 1.0;\n    }\n    float _1898 = _1638.x;\n    float _1900;\n    if (_1898 > 0.0)\n    {\n        _1900 = _1898;\n    }\n    else\n    {\n        _1900 = 1.5 * _1762;\n    }\n    vec2 param_10 = _1860;\n    vec4 param_11 = _1745;\n    float param_12 = _1842 - (_1900 * (1.0 + (0.5 * _1813)));\n    float param_13 = _1762;\n    float param_14 = 1.0;\n    float param_15 = _1750.z * 0.25;\n    float param_16 = (_1762 * min(_1813, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1845, _1750.z);\n    int param_18 = int(_1633.z + 0.5);\n    float param_19 = _1633.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2441 = fa_lm.z > 0.5;\n    bool _2447;\n    if (_2441)\n    {\n        int param = li;\n        _2447 = fa_light_baked(param);\n    }\n    else\n    {\n        _2447 = _2441;\n    }\n    if (_2447)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2470 = fa_light_sample(param_2, param_3);\n    vec3 _3476 = _2470.direction;\n    vec3 _3471 = _2470.color;\n    float _3478 = _2470.attenuation;\n    float _3473 = _2470.shadow;\n    int _3481 = _2470.type;\n    if ((_3481 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3476;\n        float _2484 = fa_shadow_factor(param_4, param_5);\n        _3473 = _2484;\n        _3471 *= _2484;\n    }\n    else\n    {\n        bool _2495 = _3481 != 0;\n        bool _2501;\n        if (_2495)\n        {\n            _2501 = _3478 > 0.0;\n        }\n        else\n        {\n            _2501 = _2495;\n        }\n        if (_2501)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3476;\n            float _2513 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3473 = _2513;\n            _3471 *= _2513;\n        }\n    }\n    return LightSample(_3476, _3471, _3478, _3473, _2470._distance, _3481);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2149 = int(fa_shadows[25].x + 0.5);\n    float _2159 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2164 = _2149 > 0;\n    bool _2173;\n    if (_2164)\n    {\n        int param = _2149 - 1;\n        _2173 = _2159 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2173 = _2164;\n    }\n    if (_2173)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2180 = _2149 > 1;\n        bool _2187;\n        if (_2180)\n        {\n            _2187 = _2159 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2187 = _2180;\n        }\n        if (_2187)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2193 = _2149 > 2;\n        bool _2200;\n        if (_2193)\n        {\n            _2200 = _2159 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2200 = _2193;\n        }\n        if (_2200)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2206 = _2149 > 3;\n        bool _2213;\n        if (_2206)\n        {\n            _2213 = _2159 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2213 = _2206;\n        }\n        if (_2213)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3312 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3312 = -_3312;\n    }\n    vec3 _2897 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing);\n    Surface _2905 = fa_standard_surface(param_1);\n    vec3 _3343 = _2905.albedo;\n    float _3344 = _2905.alpha;\n    vec3 _3345 = _2905.normal;\n    float _3346 = _2905.metallic;\n    float _3347 = _2905.roughness;\n    float _3348 = _2905.occlusion;\n    vec3 _3349 = _2905.emission;\n    float _3350 = _2905.clearcoat;\n    float _3351 = _2905.clearcoat_roughness;\n    vec3 _3352 = _2905.sheen_color;\n    float _3353 = _2905.sheen_roughness;\n    float _3354 = _2905.anisotropy;\n    float _3355 = _2905.anisotropy_rotation;\n    float _3356 = _2905.specular;\n    float _3357 = _2905.ior;\n    vec3 _3358 = _2905.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing);\n    Surface param_3 = _2905;\n    surface(param_2, param_3);\n    _3343 = param_3.albedo;\n    _3344 = param_3.alpha;\n    _3345 = param_3.normal;\n    _3346 = param_3.metallic;\n    _3347 = param_3.roughness;\n    _3348 = param_3.occlusion;\n    _3349 = param_3.emission;\n    _3350 = param_3.clearcoat;\n    _3351 = param_3.clearcoat_roughness;\n    _3352 = param_3.sheen_color;\n    _3353 = param_3.sheen_roughness;\n    _3354 = param_3.anisotropy;\n    _3355 = param_3.anisotropy_rotation;\n    _3356 = param_3.specular;\n    _3357 = param_3.ior;\n    _3358 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3312;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3343 = param_6;\n    _3345 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3343;\n    }\n    else\n    {\n        vec3 _2943 = _3345;\n        vec3 _2944 = normalize(_2943);\n        _3345 = _2944;\n        vec3 param_8 = _2944;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _3343) * _3348;\n        int _2963 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2963; ln++)\n        {\n            int param_9 = ln;\n            int _2976 = fa_cl_light(param_9);\n            bool _2979 = fa_lm.z > 0.5;\n            bool _2985;\n            if (_2979)\n            {\n                int param_10 = _2976;\n                _2985 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _2985 = _2979;\n            }\n            if (_2985)\n            {\n                continue;\n            }\n            int param_11 = _2976;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _3312;\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _3312, fa_world_tangent, fa_uv, fa_vertex_color, _2897, gl_FrontFacing);\n            Surface param_15 = Surface(_3343, _3344, _3345, _3346, _3347, _3348, _3349, _3350, _3351, _3352, _3353, _3354, _3355, _3356, _3357, _3358);\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3012 = result;\n    vec3 _3013 = _3012 + _3349;\n    result = _3013;\n    vec3 param_17 = _3013;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3022 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3029;\n    if (!_3022)\n    {\n        _3029 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3029 = _3022;\n    }\n    if (_3029)\n    {\n        vec3 _3038 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3044 = dot(_3038, fa_mesh_fs_params[9].xyz);\n        bool _3048 = fa_mesh_fs_params[9].w > 0.5;\n        float _3049;\n        if (_3048)\n        {\n            _3049 = _3044;\n        }\n        else\n        {\n            _3049 = length(_3038);\n        }\n        float _3061 = _3049 - fa_mesh_fs_params[8].x;\n        if (_3061 > 0.0)\n        {\n            float _3070 = fa_mesh_fs_params[7].w * _3061;\n            float tau = _3070 * _3070;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3086;\n                if (_3048)\n                {\n                    _3086 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3044);\n                }\n                else\n                {\n                    _3086 = fa_mesh_fs_params[0].y;\n                }\n                float _3107 = mix(_3086, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3049, 0.0, 1.0));\n                float _3111 = fa_world_pos.y - _3107;\n                float _3116 = _3107 - fa_mesh_fs_params[8].z;\n                float _3121 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3124 = _3116 <= 0.0;\n                bool _3125 = !_3124;\n                bool _3131;\n                if (_3125)\n                {\n                    _3131 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3131 = _3124;\n                }\n                float _3132;\n                if (_3131)\n                {\n                    _3132 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3132 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3116, 80.0));\n                }\n                bool _3159;\n                if (_3125)\n                {\n                    _3159 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3159 = _3124;\n                }\n                float _3160;\n                if (_3159)\n                {\n                    _3160 = fa_mesh_fs_params[8].y * _3116;\n                }\n                else\n                {\n                    _3160 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3116, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3185 = _3121 <= 0.0;\n                bool _3192;\n                if (!_3185)\n                {\n                    _3192 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3192 = _3185;\n                }\n                float _3193;\n                if (_3192)\n                {\n                    _3193 = fa_mesh_fs_params[8].y * _3121;\n                }\n                else\n                {\n                    _3193 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3121, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3220;\n                if (abs(_3111) < 0.001000000047497451305389404296875)\n                {\n                    _3220 = _3132;\n                }\n                else\n                {\n                    _3220 = (_3193 - _3160) / _3111;\n                }\n                tau += (_3061 * max(_3220, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3344);\n}\n\n",
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
            "inst_name": "_452",
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
            "inst_name": "_1192",
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
