{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "cdeb0668828214c74f0c30d588a05ff792b9d23c1a6a8d04f213c29c73527515",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _465 = fa_mesh_fs_params[19].x < 0.0;\n    bool _472;\n    if (!_465)\n    {\n        _472 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _472 = _465;\n    }\n    bool _480;\n    if (!_472)\n    {\n        _480 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _480 = _472;\n    }\n    bool _487;\n    if (!_480)\n    {\n        _487 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _487 = _480;\n    }\n    bool _494;\n    if (!_487)\n    {\n        _494 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _494 = _487;\n    }\n    if (_494)\n    {\n        return vec4(0.0);\n    }\n    vec4 _504 = vec4(world_pos, 1.0);\n    float _511 = dot(fa_mesh_fs_params[16], _504);\n    if (!(_511 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _533 = vec2(dot(fa_mesh_fs_params[14], _504), dot(fa_mesh_fs_params[15], _504)) / vec2(_511);\n    int _537 = int(fa_mesh_fs_params[18].x);\n    int _541 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _541) + clamp(int(floor(((_533.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _541 - 1)) * _537)) + clamp(int(floor(((_533.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _537 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _617 = fa_cluster_texel(param);\n    return ivec2(int(_617.x), int(_617.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2675 = fa_cluster_lookup(param);\n    fa_cl_slot = _2675.x;\n    fa_cl_local = _2675.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2867 = fa_linear_to_srgb(param);\n        c = _2867;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2875 = fa_srgb_to_linear(param_1);\n            c = _2875;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _225;\n    if (i.front_facing)\n    {\n        _225 = i.world_normal;\n    }\n    else\n    {\n        _225 = -i.world_normal;\n    }\n    vec3 _249 = normalize(i.world_tangent.xyz - (_225 * dot(_225, i.world_tangent.xyz)));\n    vec3 _276 = normalize(((_249 * m.x) + ((cross(_225, _249) * i.world_tangent.w) * m.y)) + (_225 * m.z));\n    vec3 _279;\n    if (i.front_facing)\n    {\n        _279 = _276;\n    }\n    else\n    {\n        _279 = -_276;\n    }\n    return _279;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2906 = fa_tex_fix(param_2, param_3);\n    vec4 _3927 = base_t;\n    _3927.x = _2906.x;\n    _3927.y = _2906.y;\n    _3927.z = _2906.z;\n    base_t = _3927;\n    vec4 _2920 = (_3927 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3794 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2952 = fa_tex_fix(param_6, param_7);\n        vec3 _2955 = (_2952 * 2.0) - vec3(1.0);\n        vec2 _2960 = _2955.xy * fa_mesh_fs_params[6].x;\n        vec3 _3935 = _2955;\n        _3935.x = _2960.x;\n        _3935.y = _2960.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3935;\n        _3794 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2989 = fa_tex_fix(param_12, param_13);\n    vec4 _3938 = mrt;\n    _3938.x = _2989.x;\n    _3938.y = _2989.y;\n    _3938.z = _2989.z;\n    mrt = _3938;\n    vec4 _3017 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3017.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3029 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3059 = fa_tex_fix(param_20, param_21);\n    float _3799 = fa_mesh_fs_params[20].x;\n    float _3800 = fa_mesh_fs_params[20].y;\n    float _3803 = fa_mesh_fs_params[20].z;\n    float _3802 = fa_mesh_fs_params[21].w;\n    float _3805 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3799 *= _3029.y;\n            _3800 *= _3029.z;\n            _3802 *= _3017.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3803 *= mrt.x;\n            _3805 *= mrt.w;\n        }\n    }\n    return Surface(_2920.xyz, _2920.w, _3794, clamp(fa_mesh_fs_params[5].x * _2989.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2989.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3029.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3059), _3799, _3800, fa_mesh_fs_params[21].xyz, _3802, _3803, fa_mesh_fs_params[20].w, _3805, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _698 = rect.zw - rect.xy;\n    vec2 _702 = _698 * atlas;\n    vec2 _706 = ddx * _702;\n    vec2 _710 = ddy * _702;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _698), clamp(0.5 * log2(max(max(dot(_706, _706), dot(_710, _710)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _745 = fa_mesh_fs_params[10].y < 0.5;\n    bool _752;\n    if (!_745)\n    {\n        _752 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _752 = _745;\n    }\n    if (_752)\n    {\n        return;\n    }\n    vec3 _758 = dFdx(world_pos);\n    vec3 _761 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _765 = fa_cluster_texel(param);\n    int _769 = int(_765.w);\n    if (_769 < 1)\n    {\n        return;\n    }\n    int _779 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _779;\n    vec4 _783 = fa_light_texel(param_1);\n    vec2 _786 = _783.yz;\n    int _790 = int(_783.w);\n    int param_2 = _779 + 1;\n    vec4 _795 = fa_light_texel(param_2);\n    float _796 = _795.x;\n    int _802 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _806 = int(_765.z);\n    vec3 _1072;\n    for (int k = 0; k < _769; k++)\n    {\n        int _819 = _806 + k;\n        int param_3 = _790 + (_819 >> 2);\n        int _837 = (_779 + 2) + (int(fa_light_texel(param_3)[_819 & 3]) * 7);\n        int param_4 = _837 + 6;\n        vec4 _842 = fa_light_texel(param_4);\n        if (((int(_842.w + 0.5) >> _802) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _837;\n        vec4 _857 = fa_light_texel(param_5);\n        int param_6 = _837 + 1;\n        vec4 _862 = fa_light_texel(param_6);\n        int param_7 = _837 + 2;\n        vec4 _867 = fa_light_texel(param_7);\n        vec3 _870 = _857.xyz;\n        float _875 = dot(_870, world_pos) + _857.w;\n        vec3 _877 = _862.xyz;\n        float _882 = dot(_877, world_pos) + _862.w;\n        vec3 _884 = _867.xyz;\n        float _889 = dot(_884, world_pos) + _867.w;\n        bool _894 = abs(_875) > 0.5;\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_882) > 0.5;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        bool _910;\n        if (!_902)\n        {\n            _910 = abs(_889) > 0.5;\n        }\n        else\n        {\n            _910 = _902;\n        }\n        if (_910)\n        {\n            continue;\n        }\n        float _925 = clamp(dot(geo_normal, normalize(_884)) * _842.z, 0.0, 1.0);\n        if (_925 <= 0.0)\n        {\n            continue;\n        }\n        float _945 = (clamp((0.5 - abs(_889)) * 10.0, 0.0, 1.0) * _925) * _842.x;\n        vec2 _953 = vec2(_875 + 0.5, 0.5 - _882);\n        vec2 _963 = vec2(dot(_870, _758), dot(_877, _758));\n        vec2 _973 = vec2(dot(_870, _761), dot(_877, _761));\n        int param_8 = _837 + 5;\n        vec4 _978 = fa_light_texel(param_8);\n        int param_9 = _837 + 3;\n        vec4 _983 = fa_light_texel(param_9);\n        int param_10 = _837 + 4;\n        vec4 _988 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _978.xyz;\n        bool _998 = _983.z > _983.x;\n        if (_998)\n        {\n            vec4 param_11 = _983;\n            vec2 param_12 = _953;\n            vec2 param_13 = _786;\n            vec2 param_14 = _963;\n            vec2 param_15 = _973;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_796 > 0.5) && (_796 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1024 = fa_dc_to_linear(param_16);\n                vec4 _3850 = tx;\n                _3850.x = _1024.x;\n                _3850.y = _1024.y;\n                _3850.z = _1024.z;\n                tx = _3850;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_945 * tex_a) * _978.w, 0.0, 1.0)));\n        if (_988.z > _988.x)\n        {\n            vec4 param_17 = _988;\n            vec2 param_18 = _953;\n            vec2 param_19 = _786;\n            vec2 param_20 = _963;\n            vec2 param_21 = _973;\n            vec4 _1068 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_796 > 1.5)\n            {\n                vec3 param_22 = _1068.xyz;\n                vec3 _1078 = fa_dc_to_srgb(param_22);\n                _1072 = _1078;\n            }\n            else\n            {\n                _1072 = _1068.xyz;\n            }\n            vec3 _1088 = (_1072 * 2.0) - vec3(1.0);\n            vec2 _1093 = _1088.xy * _842.y;\n            vec3 _1115 = (normalize(_870) * _1093.x) + (normalize(_877) * _1093.y);\n            vec3 _1118 = normalize(normal);\n            normal = normalize(mix(_1118, normalize((_1118 * max(_1088.z, 0.0500000007450580596923828125)) + (_1115 - (_1118 * dot(_1118, _1115)))), vec3(clamp(_945 * (_998 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2335 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2335;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _335 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _341 = fa_light_texel(param_1);\n    float _344 = _341.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _350 = _344 < 0.5;\n    vec3 l;\n    if (_350)\n    {\n        l = normalize(_335.xyz);\n    }\n    else\n    {\n        vec3 _362 = _335.xyz - world_pos;\n        float _364 = length(_362);\n        dist = _364;\n        l = _362 / vec3(max(_364, 9.9999997473787516355514526367188e-05));\n        float _379 = _364 / max(_335.w, 0.001000000047497451305389404296875);\n        float _385 = clamp(1.0 - (_379 * _379), 0.0, 1.0);\n        atten = _385 * _385;\n        if (_344 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _399 = fa_light_texel(param_2);\n            float _409 = _399.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _415 = fa_light_texel(param_3);\n            float _416 = _415.x;\n            float cos_inner = _416;\n            if (_416 > 1.5)\n            {\n                cos_inner = mix(_409, 1.0, 0.25);\n            }\n            atten *= smoothstep(_409, cos_inner, dot(-l, normalize(_399.xyz)));\n        }\n    }\n    int _446;\n    if (_350)\n    {\n        _446 = 0;\n    }\n    else\n    {\n        _446 = (_344 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _341.xyz * atten, atten, 1.0, dist, _446);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1190;\n    if (i == 0)\n    {\n        _1190 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1206;\n        if (i == 1)\n        {\n            _1206 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1214;\n            if (i == 2)\n            {\n                _1214 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1214 = fa_shadows[24].w;\n            }\n            _1206 = _1214;\n        }\n        _1190 = _1206;\n    }\n    return _1190;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1247 = fa_shadow_depth(param, param_1);\n    float _1251;\n    if (conv.x < 0.5)\n    {\n        _1251 = _1247;\n    }\n    else\n    {\n        _1251 = (conv.y * conv.z) / (conv.z - (_1247 * (conv.z - conv.y)));\n    }\n    return _1251;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1178 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1178), sin(_1178)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1297 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1311 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1297;\n            vec2 _1330 = fa_shadow_vogel(param_3, param_4, param_5) * _1311;\n            vec2 param_6 = uv + (_1330 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1342 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1342 < (zr - (length(_1330) * plane)))\n            {\n                sum += _1342;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1386 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1386; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1386;\n        float param_11 = _1297;\n        vec2 _1405 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1405 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1405) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1386);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1447 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1452 = clamp(dot(n, l), 0.0, 1.0);\n    float _1458 = sqrt(1.0 - (_1452 * _1452));\n    float _1465 = min(_1458 / max(_1452, 0.20000000298023223876953125), 4.0);\n    float _1470;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1470 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1470 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1495 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1470 * _1458)), 1.0);\n    float _1502 = _1495.x;\n    bool _1505 = _1502 < fa_shadows[ci * 1 + 16].x;\n    bool _1514;\n    if (!_1505)\n    {\n        _1514 = _1502 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1514 = _1505;\n    }\n    bool _1523;\n    if (!_1514)\n    {\n        _1523 = _1495.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1523 = _1514;\n    }\n    bool _1532;\n    if (!_1523)\n    {\n        _1532 = _1495.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1532 = _1523;\n    }\n    bool _1539;\n    if (!_1532)\n    {\n        _1539 = _1495.z > 1.0;\n    }\n    else\n    {\n        _1539 = _1532;\n    }\n    if (_1539)\n    {\n        return -1.0;\n    }\n    float _1548;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1548 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1548 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1495.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1495.z - ((_1548 * (1.0 + (0.5 * _1465))) / _1447);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1447;\n    float param_5 = _1447 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1465, 3.0)) * 0.5) / _1447;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1975 = int(fa_shadows[25].x + 0.5);\n    if (_1975 < 1)\n    {\n        return 1.0;\n    }\n    float _1990 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1975 - 1;\n    if (_1990 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2002 = _1975 > 1;\n    bool _2009;\n    if (_2002)\n    {\n        _2009 = _1990 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2009 = _2002;\n    }\n    if (_2009)\n    {\n        ci = 1;\n    }\n    bool _2013 = _1975 > 2;\n    bool _2020;\n    if (_2013)\n    {\n        _2020 = _1990 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2020 = _2013;\n    }\n    if (_2020)\n    {\n        ci = 2;\n    }\n    bool _2024 = _1975 > 3;\n    bool _2031;\n    if (_2024)\n    {\n        _2031 = _1990 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2031 = _2024;\n    }\n    if (_2031)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1975)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2057 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2057;\n        if (_2057 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2082;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2082 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2082 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2101 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2082, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2112 = clamp((_1990 - (fa_shadow_split_at(param_7) - _2101)) / _2101, 0.0, 1.0);\n        if (_2112 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1975)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2133 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2133;\n                if (_2133 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2112);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1606 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1614;\n    if (!_1606)\n    {\n        _1614 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1614 = _1606;\n    }\n    if (_1614)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1627 = fa_light_texel(param);\n    float _1628 = _1627.x;\n    if (_1628 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1637 = int(_1628 + 0.5);\n    int param_1 = _1637;\n    vec4 _1641 = fa_light_texel(param_1);\n    int param_2 = _1637 + 1;\n    vec4 _1646 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1649 = _1641.y;\n    if (_1649 > 0.0)\n    {\n        float _1666 = 1.0 - smoothstep(0.75 * _1649, _1649, length(world - fa_shadows[27].xyz));\n        fade = _1666;\n        if (_1666 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1641.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1685 = world - fa_light_texel(param_3).xyz;\n        vec3 _1688 = abs(_1685);\n        float _1690 = _1688.x;\n        float _1692 = _1688.y;\n        bool _1693 = _1690 >= _1692;\n        bool _1701;\n        if (_1693)\n        {\n            _1701 = _1690 >= _1688.z;\n        }\n        else\n        {\n            _1701 = _1693;\n        }\n        int _1702;\n        if (_1701)\n        {\n            _1702 = (_1685.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1715;\n            if (_1692 >= _1688.z)\n            {\n                _1715 = (_1685.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1715 = (_1685.z > 0.0) ? 4 : 5;\n            }\n            _1702 = _1715;\n        }\n        face = _1702;\n    }\n    int _1734 = (_1637 + 2) + (face * 6);\n    int param_4 = _1734;\n    int param_5 = _1734 + 1;\n    int param_6 = _1734 + 3;\n    vec4 _1748 = fa_light_texel(param_6);\n    int param_7 = _1734 + 4;\n    vec4 _1753 = fa_light_texel(param_7);\n    int param_8 = _1734 + 5;\n    vec4 _1758 = fa_light_texel(param_8);\n    float _1770 = _1758.x * max(dot(_1748, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1775 = clamp(dot(n, l), 0.0, 1.0);\n    float _1798 = clamp(dot(n, _1748.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1821 = min(sqrt(1.0 - (_1798 * _1798)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1748, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1824 = _1646.y;\n    float _1826;\n    if (_1824 > 0.0)\n    {\n        _1826 = _1824;\n    }\n    else\n    {\n        _1826 = 1.5 * _1770;\n    }\n    vec4 _1846 = vec4(world + (n * (_1826 * sqrt(1.0 - (_1775 * _1775)))), 1.0);\n    float _1850 = dot(_1748, _1846);\n    float _1853 = _1758.y;\n    if (_1850 < _1853)\n    {\n        return 1.0;\n    }\n    vec2 _1868 = vec2(dot(fa_light_texel(param_4), _1846), dot(fa_light_texel(param_5), _1846)) / vec2(_1850);\n    float _1870 = _1868.x;\n    bool _1873 = _1870 < _1753.x;\n    bool _1882;\n    if (!_1873)\n    {\n        _1882 = _1870 > _1753.z;\n    }\n    else\n    {\n        _1882 = _1873;\n    }\n    bool _1891;\n    if (!_1882)\n    {\n        _1891 = _1868.y < _1753.y;\n    }\n    else\n    {\n        _1891 = _1882;\n    }\n    bool _1900;\n    if (!_1891)\n    {\n        _1900 = _1868.y > _1753.w;\n    }\n    else\n    {\n        _1900 = _1891;\n    }\n    if (_1900)\n    {\n        return 1.0;\n    }\n    float _1906 = _1646.x;\n    float _1908;\n    if (_1906 > 0.0)\n    {\n        _1908 = _1906;\n    }\n    else\n    {\n        _1908 = 1.5 * _1770;\n    }\n    vec2 param_10 = _1868;\n    vec4 param_11 = _1753;\n    float param_12 = _1850 - (_1908 * (1.0 + (0.5 * _1821)));\n    float param_13 = _1770;\n    float param_14 = 1.0;\n    float param_15 = _1758.z * 0.25;\n    float param_16 = (_1770 * min(_1821, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1853, _1758.z);\n    int param_18 = int(_1641.z + 0.5);\n    float param_19 = _1641.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _2415 = fa_mesh_fs_params[24].x < 0.5;\n    bool _2422;\n    if (!_2415)\n    {\n        _2422 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2422 = _2415;\n    }\n    if (_2422)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2435 = fa_light_texel(param);\n    float _2436 = _2435.y;\n    float len = _2436;\n    if (_2436 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2448 = length(world - fa_mesh_fs_params[0].xyz);\n    float _2458 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _2448);\n    if (_2458 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2464 = len;\n    float _2467 = min(_2464, 0.89999997615814208984375 * dist);\n    len = _2467;\n    float _2473 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _2448);\n    float _2478 = _2473 + (0.5 * _2467);\n    vec3 _2484 = world + (gn * _2473);\n    float _2486 = fa_shadow_noise();\n    float occ = 0.0;\n    float _2551;\n    for (int k = 0; k < 12; k++)\n    {\n        float _2502 = (float(k) + _2486) * 0.083333335816860198974609375;\n        vec3 _2510 = _2484 + (l * (_2502 * len));\n        vec4 _2516 = vec4(_2510, 1.0);\n        float _2522 = dot(fa_mesh_fs_params[28], _2516);\n        if (_2522 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _2542 = vec2(dot(fa_mesh_fs_params[26], _2516), dot(fa_mesh_fs_params[27], _2516)) / vec2(_2522);\n        float _2546 = _2542.x * 0.5;\n        float _2547 = _2546 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _2551 = (_2542.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _2551 = 0.5 - (_2542.y * 0.5);\n        }\n        bool _2567 = _2547 < 0.0;\n        bool _2574;\n        if (!_2567)\n        {\n            _2574 = _2547 >= 1.0;\n        }\n        else\n        {\n            _2574 = _2567;\n        }\n        bool _2581;\n        if (!_2574)\n        {\n            _2581 = _2551 < 0.0;\n        }\n        else\n        {\n            _2581 = _2574;\n        }\n        bool _2588;\n        if (!_2581)\n        {\n            _2588 = _2551 >= 1.0;\n        }\n        else\n        {\n            _2588 = _2581;\n        }\n        if (_2588)\n        {\n            break;\n        }\n        vec4 _2607 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_2547, _2551) * fa_mesh_fs_params[24].zw), 0);\n        if (_2607.w < 0.5)\n        {\n            continue;\n        }\n        float _2626 = (dot(fa_mesh_fs_params[29].xyz, _2510) + fa_mesh_fs_params[29].w) - _2607.x;\n        if ((_2626 > _2473) && (_2626 < _2478))\n        {\n            occ = max(occ, (1.0 - (_2502 * _2502)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_2547, 0.5 - _2546), min(_2551, 1.0 - _2551))));\n        }\n    }\n    return 1.0 - (occ * _2458);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2702 = fa_lm.z > 0.5;\n    bool _2708;\n    if (_2702)\n    {\n        int param = li;\n        _2708 = fa_light_baked(param);\n    }\n    else\n    {\n        _2708 = _2702;\n    }\n    if (_2708)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2731 = fa_light_sample(param_2, param_3);\n    vec3 _3779 = _2731.direction;\n    vec3 _3774 = _2731.color;\n    float _3781 = _2731.attenuation;\n    float _3776 = _2731.shadow;\n    float _3783 = _2731._distance;\n    int _3784 = _2731.type;\n    bool _2734 = _3784 == 0;\n    if (_2734 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3779;\n        float _2745 = fa_shadow_factor(param_4, param_5);\n        _3776 = _2745;\n        _3774 *= _2745;\n    }\n    else\n    {\n        bool _2756 = _3784 != 0;\n        bool _2762;\n        if (_2756)\n        {\n            _2762 = _3781 > 0.0;\n        }\n        else\n        {\n            _2762 = _2756;\n        }\n        if (_2762)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3779;\n            float _2774 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3776 = _2774;\n            _3774 *= _2774;\n        }\n    }\n    bool _2784 = fa_mesh_fs_params[24].x > 0.5;\n    bool _2790;\n    if (_2784)\n    {\n        _2790 = _3781 > 0.0;\n    }\n    else\n    {\n        _2790 = _2784;\n    }\n    if (_2790)\n    {\n        float _2797;\n        if (_2734)\n        {\n            _2797 = 1000000000.0;\n        }\n        else\n        {\n            _2797 = _3783;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _3779;\n        float param_14 = _2797;\n        float _2815 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _3776 *= _2815;\n        _3774 *= _2815;\n    }\n    return LightSample(_3779, _3774, _3781, _3776, _3783, _3784);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2157 = int(fa_shadows[25].x + 0.5);\n    float _2167 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2172 = _2157 > 0;\n    bool _2181;\n    if (_2172)\n    {\n        int param = _2157 - 1;\n        _2181 = _2167 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2181 = _2172;\n    }\n    if (_2181)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2188 = _2157 > 1;\n        bool _2195;\n        if (_2188)\n        {\n            _2195 = _2167 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2195 = _2188;\n        }\n        if (_2195)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2201 = _2157 > 2;\n        bool _2208;\n        if (_2201)\n        {\n            _2208 = _2167 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2208 = _2201;\n        }\n        if (_2208)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2214 = _2157 > 3;\n        bool _2221;\n        if (_2214)\n        {\n            _2221 = _2167 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2221 = _2214;\n        }\n        if (_2221)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3615 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3615 = -_3615;\n    }\n    vec3 _3201 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3615, fa_world_tangent, fa_uv, fa_vertex_color, _3201, gl_FrontFacing);\n    Surface _3209 = fa_standard_surface(param_1);\n    vec3 _3646 = _3209.albedo;\n    float _3647 = _3209.alpha;\n    vec3 _3648 = _3209.normal;\n    float _3649 = _3209.metallic;\n    float _3650 = _3209.roughness;\n    float _3651 = _3209.occlusion;\n    vec3 _3652 = _3209.emission;\n    float _3653 = _3209.clearcoat;\n    float _3654 = _3209.clearcoat_roughness;\n    vec3 _3655 = _3209.sheen_color;\n    float _3656 = _3209.sheen_roughness;\n    float _3657 = _3209.anisotropy;\n    float _3658 = _3209.anisotropy_rotation;\n    float _3659 = _3209.specular;\n    float _3660 = _3209.ior;\n    vec3 _3661 = _3209.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3615, fa_world_tangent, fa_uv, fa_vertex_color, _3201, gl_FrontFacing);\n    Surface param_3 = _3209;\n    surface(param_2, param_3);\n    _3646 = param_3.albedo;\n    _3647 = param_3.alpha;\n    _3648 = param_3.normal;\n    _3649 = param_3.metallic;\n    _3650 = param_3.roughness;\n    _3651 = param_3.occlusion;\n    _3652 = param_3.emission;\n    _3653 = param_3.clearcoat;\n    _3654 = param_3.clearcoat_roughness;\n    _3655 = param_3.sheen_color;\n    _3656 = param_3.sheen_roughness;\n    _3657 = param_3.anisotropy;\n    _3658 = param_3.anisotropy_rotation;\n    _3659 = param_3.specular;\n    _3660 = param_3.ior;\n    _3661 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3615;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3646 = param_6;\n    _3648 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3646;\n    }\n    else\n    {\n        vec3 _3247 = _3648;\n        vec3 _3248 = normalize(_3247);\n        _3648 = _3248;\n        vec3 param_8 = _3248;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _3646) * _3651;\n        int _3267 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3267; ln++)\n        {\n            int param_9 = ln;\n            int _3280 = fa_cl_light(param_9);\n            bool _3283 = fa_lm.z > 0.5;\n            bool _3289;\n            if (_3283)\n            {\n                int param_10 = _3280;\n                _3289 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3289 = _3283;\n            }\n            if (_3289)\n            {\n                continue;\n            }\n            int param_11 = _3280;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _3615;\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _3615, fa_world_tangent, fa_uv, fa_vertex_color, _3201, gl_FrontFacing);\n            Surface param_15 = Surface(_3646, _3647, _3648, _3649, _3650, _3651, _3652, _3653, _3654, _3655, _3656, _3657, _3658, _3659, _3660, _3661);\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3316 = result;\n    vec3 _3317 = _3316 + _3652;\n    result = _3317;\n    vec3 param_17 = _3317;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3326 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3333;\n    if (!_3326)\n    {\n        _3333 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3333 = _3326;\n    }\n    if (_3333)\n    {\n        vec3 _3342 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3348 = dot(_3342, fa_mesh_fs_params[9].xyz);\n        bool _3352 = fa_mesh_fs_params[9].w > 0.5;\n        float _3353;\n        if (_3352)\n        {\n            _3353 = _3348;\n        }\n        else\n        {\n            _3353 = length(_3342);\n        }\n        float _3365 = _3353 - fa_mesh_fs_params[8].x;\n        if (_3365 > 0.0)\n        {\n            float _3374 = fa_mesh_fs_params[7].w * _3365;\n            float tau = _3374 * _3374;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3390;\n                if (_3352)\n                {\n                    _3390 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3348);\n                }\n                else\n                {\n                    _3390 = fa_mesh_fs_params[0].y;\n                }\n                float _3411 = mix(_3390, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3353, 0.0, 1.0));\n                float _3415 = fa_world_pos.y - _3411;\n                float _3420 = _3411 - fa_mesh_fs_params[8].z;\n                float _3425 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3428 = _3420 <= 0.0;\n                bool _3429 = !_3428;\n                bool _3435;\n                if (_3429)\n                {\n                    _3435 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3435 = _3428;\n                }\n                float _3436;\n                if (_3435)\n                {\n                    _3436 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3436 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3420, 80.0));\n                }\n                bool _3463;\n                if (_3429)\n                {\n                    _3463 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3463 = _3428;\n                }\n                float _3464;\n                if (_3463)\n                {\n                    _3464 = fa_mesh_fs_params[8].y * _3420;\n                }\n                else\n                {\n                    _3464 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3420, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3489 = _3425 <= 0.0;\n                bool _3496;\n                if (!_3489)\n                {\n                    _3496 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3496 = _3489;\n                }\n                float _3497;\n                if (_3496)\n                {\n                    _3497 = fa_mesh_fs_params[8].y * _3425;\n                }\n                else\n                {\n                    _3497 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3425, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3524;\n                if (abs(_3415) < 0.001000000047497451305389404296875)\n                {\n                    _3524 = _3436;\n                }\n                else\n                {\n                    _3524 = (_3497 - _3464) / _3415;\n                }\n                tau += (_3365 * max(_3524, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3647);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_460",
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
            "inst_name": "_1200",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
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
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _465 = fa_mesh_fs_params[19].x < 0.0;\n    bool _472;\n    if (!_465)\n    {\n        _472 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _472 = _465;\n    }\n    bool _480;\n    if (!_472)\n    {\n        _480 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _480 = _472;\n    }\n    bool _487;\n    if (!_480)\n    {\n        _487 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _487 = _480;\n    }\n    bool _494;\n    if (!_487)\n    {\n        _494 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _494 = _487;\n    }\n    if (_494)\n    {\n        return vec4(0.0);\n    }\n    vec4 _504 = vec4(world_pos, 1.0);\n    float _511 = dot(fa_mesh_fs_params[16], _504);\n    if (!(_511 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _533 = vec2(dot(fa_mesh_fs_params[14], _504), dot(fa_mesh_fs_params[15], _504)) / vec2(_511);\n    int _537 = int(fa_mesh_fs_params[18].x);\n    int _541 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _541) + clamp(int(floor(((_533.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _541 - 1)) * _537)) + clamp(int(floor(((_533.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _537 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _617 = fa_cluster_texel(param);\n    return ivec2(int(_617.x), int(_617.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2675 = fa_cluster_lookup(param);\n    fa_cl_slot = _2675.x;\n    fa_cl_local = _2675.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2867 = fa_linear_to_srgb(param);\n        c = _2867;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2875 = fa_srgb_to_linear(param_1);\n            c = _2875;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _225;\n    if (i.front_facing)\n    {\n        _225 = i.world_normal;\n    }\n    else\n    {\n        _225 = -i.world_normal;\n    }\n    vec3 _249 = normalize(i.world_tangent.xyz - (_225 * dot(_225, i.world_tangent.xyz)));\n    vec3 _276 = normalize(((_249 * m.x) + ((cross(_225, _249) * i.world_tangent.w) * m.y)) + (_225 * m.z));\n    vec3 _279;\n    if (i.front_facing)\n    {\n        _279 = _276;\n    }\n    else\n    {\n        _279 = -_276;\n    }\n    return _279;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2906 = fa_tex_fix(param_2, param_3);\n    vec4 _3927 = base_t;\n    _3927.x = _2906.x;\n    _3927.y = _2906.y;\n    _3927.z = _2906.z;\n    base_t = _3927;\n    vec4 _2920 = (_3927 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3794 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2952 = fa_tex_fix(param_6, param_7);\n        vec3 _2955 = (_2952 * 2.0) - vec3(1.0);\n        vec2 _2960 = _2955.xy * fa_mesh_fs_params[6].x;\n        vec3 _3935 = _2955;\n        _3935.x = _2960.x;\n        _3935.y = _2960.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3935;\n        _3794 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2989 = fa_tex_fix(param_12, param_13);\n    vec4 _3938 = mrt;\n    _3938.x = _2989.x;\n    _3938.y = _2989.y;\n    _3938.z = _2989.z;\n    mrt = _3938;\n    vec4 _3017 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3017.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3029 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3059 = fa_tex_fix(param_20, param_21);\n    float _3799 = fa_mesh_fs_params[20].x;\n    float _3800 = fa_mesh_fs_params[20].y;\n    float _3803 = fa_mesh_fs_params[20].z;\n    float _3802 = fa_mesh_fs_params[21].w;\n    float _3805 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3799 *= _3029.y;\n            _3800 *= _3029.z;\n            _3802 *= _3017.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3803 *= mrt.x;\n            _3805 *= mrt.w;\n        }\n    }\n    return Surface(_2920.xyz, _2920.w, _3794, clamp(fa_mesh_fs_params[5].x * _2989.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2989.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3029.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3059), _3799, _3800, fa_mesh_fs_params[21].xyz, _3802, _3803, fa_mesh_fs_params[20].w, _3805, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _698 = rect.zw - rect.xy;\n    vec2 _702 = _698 * atlas;\n    vec2 _706 = ddx * _702;\n    vec2 _710 = ddy * _702;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _698), clamp(0.5 * log2(max(max(dot(_706, _706), dot(_710, _710)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _745 = fa_mesh_fs_params[10].y < 0.5;\n    bool _752;\n    if (!_745)\n    {\n        _752 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _752 = _745;\n    }\n    if (_752)\n    {\n        return;\n    }\n    vec3 _758 = dFdx(world_pos);\n    vec3 _761 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _765 = fa_cluster_texel(param);\n    int _769 = int(_765.w);\n    if (_769 < 1)\n    {\n        return;\n    }\n    int _779 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _779;\n    vec4 _783 = fa_light_texel(param_1);\n    vec2 _786 = _783.yz;\n    int _790 = int(_783.w);\n    int param_2 = _779 + 1;\n    vec4 _795 = fa_light_texel(param_2);\n    float _796 = _795.x;\n    int _802 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _806 = int(_765.z);\n    vec3 _1072;\n    for (int k = 0; k < _769; k++)\n    {\n        int _819 = _806 + k;\n        int param_3 = _790 + (_819 >> 2);\n        int _837 = (_779 + 2) + (int(fa_light_texel(param_3)[_819 & 3]) * 7);\n        int param_4 = _837 + 6;\n        vec4 _842 = fa_light_texel(param_4);\n        if (((int(_842.w + 0.5) >> _802) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _837;\n        vec4 _857 = fa_light_texel(param_5);\n        int param_6 = _837 + 1;\n        vec4 _862 = fa_light_texel(param_6);\n        int param_7 = _837 + 2;\n        vec4 _867 = fa_light_texel(param_7);\n        vec3 _870 = _857.xyz;\n        float _875 = dot(_870, world_pos) + _857.w;\n        vec3 _877 = _862.xyz;\n        float _882 = dot(_877, world_pos) + _862.w;\n        vec3 _884 = _867.xyz;\n        float _889 = dot(_884, world_pos) + _867.w;\n        bool _894 = abs(_875) > 0.5;\n        bool _902;\n        if (!_894)\n        {\n            _902 = abs(_882) > 0.5;\n        }\n        else\n        {\n            _902 = _894;\n        }\n        bool _910;\n        if (!_902)\n        {\n            _910 = abs(_889) > 0.5;\n        }\n        else\n        {\n            _910 = _902;\n        }\n        if (_910)\n        {\n            continue;\n        }\n        float _925 = clamp(dot(geo_normal, normalize(_884)) * _842.z, 0.0, 1.0);\n        if (_925 <= 0.0)\n        {\n            continue;\n        }\n        float _945 = (clamp((0.5 - abs(_889)) * 10.0, 0.0, 1.0) * _925) * _842.x;\n        vec2 _953 = vec2(_875 + 0.5, 0.5 - _882);\n        vec2 _963 = vec2(dot(_870, _758), dot(_877, _758));\n        vec2 _973 = vec2(dot(_870, _761), dot(_877, _761));\n        int param_8 = _837 + 5;\n        vec4 _978 = fa_light_texel(param_8);\n        int param_9 = _837 + 3;\n        vec4 _983 = fa_light_texel(param_9);\n        int param_10 = _837 + 4;\n        vec4 _988 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _978.xyz;\n        bool _998 = _983.z > _983.x;\n        if (_998)\n        {\n            vec4 param_11 = _983;\n            vec2 param_12 = _953;\n            vec2 param_13 = _786;\n            vec2 param_14 = _963;\n            vec2 param_15 = _973;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_796 > 0.5) && (_796 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1024 = fa_dc_to_linear(param_16);\n                vec4 _3850 = tx;\n                _3850.x = _1024.x;\n                _3850.y = _1024.y;\n                _3850.z = _1024.z;\n                tx = _3850;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_945 * tex_a) * _978.w, 0.0, 1.0)));\n        if (_988.z > _988.x)\n        {\n            vec4 param_17 = _988;\n            vec2 param_18 = _953;\n            vec2 param_19 = _786;\n            vec2 param_20 = _963;\n            vec2 param_21 = _973;\n            vec4 _1068 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_796 > 1.5)\n            {\n                vec3 param_22 = _1068.xyz;\n                vec3 _1078 = fa_dc_to_srgb(param_22);\n                _1072 = _1078;\n            }\n            else\n            {\n                _1072 = _1068.xyz;\n            }\n            vec3 _1088 = (_1072 * 2.0) - vec3(1.0);\n            vec2 _1093 = _1088.xy * _842.y;\n            vec3 _1115 = (normalize(_870) * _1093.x) + (normalize(_877) * _1093.y);\n            vec3 _1118 = normalize(normal);\n            normal = normalize(mix(_1118, normalize((_1118 * max(_1088.z, 0.0500000007450580596923828125)) + (_1115 - (_1118 * dot(_1118, _1115)))), vec3(clamp(_945 * (_998 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2335 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2335;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _335 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _341 = fa_light_texel(param_1);\n    float _344 = _341.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _350 = _344 < 0.5;\n    vec3 l;\n    if (_350)\n    {\n        l = normalize(_335.xyz);\n    }\n    else\n    {\n        vec3 _362 = _335.xyz - world_pos;\n        float _364 = length(_362);\n        dist = _364;\n        l = _362 / vec3(max(_364, 9.9999997473787516355514526367188e-05));\n        float _379 = _364 / max(_335.w, 0.001000000047497451305389404296875);\n        float _385 = clamp(1.0 - (_379 * _379), 0.0, 1.0);\n        atten = _385 * _385;\n        if (_344 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _399 = fa_light_texel(param_2);\n            float _409 = _399.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _415 = fa_light_texel(param_3);\n            float _416 = _415.x;\n            float cos_inner = _416;\n            if (_416 > 1.5)\n            {\n                cos_inner = mix(_409, 1.0, 0.25);\n            }\n            atten *= smoothstep(_409, cos_inner, dot(-l, normalize(_399.xyz)));\n        }\n    }\n    int _446;\n    if (_350)\n    {\n        _446 = 0;\n    }\n    else\n    {\n        _446 = (_344 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _341.xyz * atten, atten, 1.0, dist, _446);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1190;\n    if (i == 0)\n    {\n        _1190 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1206;\n        if (i == 1)\n        {\n            _1206 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1214;\n            if (i == 2)\n            {\n                _1214 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1214 = fa_shadows[24].w;\n            }\n            _1206 = _1214;\n        }\n        _1190 = _1206;\n    }\n    return _1190;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1247 = fa_shadow_depth(param, param_1);\n    float _1251;\n    if (conv.x < 0.5)\n    {\n        _1251 = _1247;\n    }\n    else\n    {\n        _1251 = (conv.y * conv.z) / (conv.z - (_1247 * (conv.z - conv.y)));\n    }\n    return _1251;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1178 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1178), sin(_1178)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1297 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1311 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1297;\n            vec2 _1330 = fa_shadow_vogel(param_3, param_4, param_5) * _1311;\n            vec2 param_6 = uv + (_1330 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1342 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1342 < (zr - (length(_1330) * plane)))\n            {\n                sum += _1342;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1386 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1386; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1386;\n        float param_11 = _1297;\n        vec2 _1405 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1405 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1405) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1386);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1447 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1452 = clamp(dot(n, l), 0.0, 1.0);\n    float _1458 = sqrt(1.0 - (_1452 * _1452));\n    float _1465 = min(_1458 / max(_1452, 0.20000000298023223876953125), 4.0);\n    float _1470;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1470 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1470 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1495 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1470 * _1458)), 1.0);\n    float _1502 = _1495.x;\n    bool _1505 = _1502 < fa_shadows[ci * 1 + 16].x;\n    bool _1514;\n    if (!_1505)\n    {\n        _1514 = _1502 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1514 = _1505;\n    }\n    bool _1523;\n    if (!_1514)\n    {\n        _1523 = _1495.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1523 = _1514;\n    }\n    bool _1532;\n    if (!_1523)\n    {\n        _1532 = _1495.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1532 = _1523;\n    }\n    bool _1539;\n    if (!_1532)\n    {\n        _1539 = _1495.z > 1.0;\n    }\n    else\n    {\n        _1539 = _1532;\n    }\n    if (_1539)\n    {\n        return -1.0;\n    }\n    float _1548;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1548 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1548 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1495.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1495.z - ((_1548 * (1.0 + (0.5 * _1465))) / _1447);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1447;\n    float param_5 = _1447 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1465, 3.0)) * 0.5) / _1447;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1975 = int(fa_shadows[25].x + 0.5);\n    if (_1975 < 1)\n    {\n        return 1.0;\n    }\n    float _1990 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1975 - 1;\n    if (_1990 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2002 = _1975 > 1;\n    bool _2009;\n    if (_2002)\n    {\n        _2009 = _1990 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2009 = _2002;\n    }\n    if (_2009)\n    {\n        ci = 1;\n    }\n    bool _2013 = _1975 > 2;\n    bool _2020;\n    if (_2013)\n    {\n        _2020 = _1990 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2020 = _2013;\n    }\n    if (_2020)\n    {\n        ci = 2;\n    }\n    bool _2024 = _1975 > 3;\n    bool _2031;\n    if (_2024)\n    {\n        _2031 = _1990 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2031 = _2024;\n    }\n    if (_2031)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1975)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2057 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2057;\n        if (_2057 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2082;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2082 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2082 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2101 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2082, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2112 = clamp((_1990 - (fa_shadow_split_at(param_7) - _2101)) / _2101, 0.0, 1.0);\n        if (_2112 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1975)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2133 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2133;\n                if (_2133 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2112);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1606 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1614;\n    if (!_1606)\n    {\n        _1614 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1614 = _1606;\n    }\n    if (_1614)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1627 = fa_light_texel(param);\n    float _1628 = _1627.x;\n    if (_1628 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1637 = int(_1628 + 0.5);\n    int param_1 = _1637;\n    vec4 _1641 = fa_light_texel(param_1);\n    int param_2 = _1637 + 1;\n    vec4 _1646 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1649 = _1641.y;\n    if (_1649 > 0.0)\n    {\n        float _1666 = 1.0 - smoothstep(0.75 * _1649, _1649, length(world - fa_shadows[27].xyz));\n        fade = _1666;\n        if (_1666 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1641.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1685 = world - fa_light_texel(param_3).xyz;\n        vec3 _1688 = abs(_1685);\n        float _1690 = _1688.x;\n        float _1692 = _1688.y;\n        bool _1693 = _1690 >= _1692;\n        bool _1701;\n        if (_1693)\n        {\n            _1701 = _1690 >= _1688.z;\n        }\n        else\n        {\n            _1701 = _1693;\n        }\n        int _1702;\n        if (_1701)\n        {\n            _1702 = (_1685.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1715;\n            if (_1692 >= _1688.z)\n            {\n                _1715 = (_1685.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1715 = (_1685.z > 0.0) ? 4 : 5;\n            }\n            _1702 = _1715;\n        }\n        face = _1702;\n    }\n    int _1734 = (_1637 + 2) + (face * 6);\n    int param_4 = _1734;\n    int param_5 = _1734 + 1;\n    int param_6 = _1734 + 3;\n    vec4 _1748 = fa_light_texel(param_6);\n    int param_7 = _1734 + 4;\n    vec4 _1753 = fa_light_texel(param_7);\n    int param_8 = _1734 + 5;\n    vec4 _1758 = fa_light_texel(param_8);\n    float _1770 = _1758.x * max(dot(_1748, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1775 = clamp(dot(n, l), 0.0, 1.0);\n    float _1798 = clamp(dot(n, _1748.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1821 = min(sqrt(1.0 - (_1798 * _1798)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1748, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1824 = _1646.y;\n    float _1826;\n    if (_1824 > 0.0)\n    {\n        _1826 = _1824;\n    }\n    else\n    {\n        _1826 = 1.5 * _1770;\n    }\n    vec4 _1846 = vec4(world + (n * (_1826 * sqrt(1.0 - (_1775 * _1775)))), 1.0);\n    float _1850 = dot(_1748, _1846);\n    float _1853 = _1758.y;\n    if (_1850 < _1853)\n    {\n        return 1.0;\n    }\n    vec2 _1868 = vec2(dot(fa_light_texel(param_4), _1846), dot(fa_light_texel(param_5), _1846)) / vec2(_1850);\n    float _1870 = _1868.x;\n    bool _1873 = _1870 < _1753.x;\n    bool _1882;\n    if (!_1873)\n    {\n        _1882 = _1870 > _1753.z;\n    }\n    else\n    {\n        _1882 = _1873;\n    }\n    bool _1891;\n    if (!_1882)\n    {\n        _1891 = _1868.y < _1753.y;\n    }\n    else\n    {\n        _1891 = _1882;\n    }\n    bool _1900;\n    if (!_1891)\n    {\n        _1900 = _1868.y > _1753.w;\n    }\n    else\n    {\n        _1900 = _1891;\n    }\n    if (_1900)\n    {\n        return 1.0;\n    }\n    float _1906 = _1646.x;\n    float _1908;\n    if (_1906 > 0.0)\n    {\n        _1908 = _1906;\n    }\n    else\n    {\n        _1908 = 1.5 * _1770;\n    }\n    vec2 param_10 = _1868;\n    vec4 param_11 = _1753;\n    float param_12 = _1850 - (_1908 * (1.0 + (0.5 * _1821)));\n    float param_13 = _1770;\n    float param_14 = 1.0;\n    float param_15 = _1758.z * 0.25;\n    float param_16 = (_1770 * min(_1821, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1853, _1758.z);\n    int param_18 = int(_1641.z + 0.5);\n    float param_19 = _1641.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _2415 = fa_mesh_fs_params[24].x < 0.5;\n    bool _2422;\n    if (!_2415)\n    {\n        _2422 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2422 = _2415;\n    }\n    if (_2422)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2435 = fa_light_texel(param);\n    float _2436 = _2435.y;\n    float len = _2436;\n    if (_2436 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2448 = length(world - fa_mesh_fs_params[0].xyz);\n    float _2458 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _2448);\n    if (_2458 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2464 = len;\n    float _2467 = min(_2464, 0.89999997615814208984375 * dist);\n    len = _2467;\n    float _2473 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _2448);\n    float _2478 = _2473 + (0.5 * _2467);\n    vec3 _2484 = world + (gn * _2473);\n    float _2486 = fa_shadow_noise();\n    float occ = 0.0;\n    float _2551;\n    for (int k = 0; k < 12; k++)\n    {\n        float _2502 = (float(k) + _2486) * 0.083333335816860198974609375;\n        vec3 _2510 = _2484 + (l * (_2502 * len));\n        vec4 _2516 = vec4(_2510, 1.0);\n        float _2522 = dot(fa_mesh_fs_params[28], _2516);\n        if (_2522 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _2542 = vec2(dot(fa_mesh_fs_params[26], _2516), dot(fa_mesh_fs_params[27], _2516)) / vec2(_2522);\n        float _2546 = _2542.x * 0.5;\n        float _2547 = _2546 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _2551 = (_2542.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _2551 = 0.5 - (_2542.y * 0.5);\n        }\n        bool _2567 = _2547 < 0.0;\n        bool _2574;\n        if (!_2567)\n        {\n            _2574 = _2547 >= 1.0;\n        }\n        else\n        {\n            _2574 = _2567;\n        }\n        bool _2581;\n        if (!_2574)\n        {\n            _2581 = _2551 < 0.0;\n        }\n        else\n        {\n            _2581 = _2574;\n        }\n        bool _2588;\n        if (!_2581)\n        {\n            _2588 = _2551 >= 1.0;\n        }\n        else\n        {\n            _2588 = _2581;\n        }\n        if (_2588)\n        {\n            break;\n        }\n        vec4 _2607 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_2547, _2551) * fa_mesh_fs_params[24].zw), 0);\n        if (_2607.w < 0.5)\n        {\n            continue;\n        }\n        float _2626 = (dot(fa_mesh_fs_params[29].xyz, _2510) + fa_mesh_fs_params[29].w) - _2607.x;\n        if ((_2626 > _2473) && (_2626 < _2478))\n        {\n            occ = max(occ, (1.0 - (_2502 * _2502)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_2547, 0.5 - _2546), min(_2551, 1.0 - _2551))));\n        }\n    }\n    return 1.0 - (occ * _2458);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2702 = fa_lm.z > 0.5;\n    bool _2708;\n    if (_2702)\n    {\n        int param = li;\n        _2708 = fa_light_baked(param);\n    }\n    else\n    {\n        _2708 = _2702;\n    }\n    if (_2708)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2731 = fa_light_sample(param_2, param_3);\n    vec3 _3779 = _2731.direction;\n    vec3 _3774 = _2731.color;\n    float _3781 = _2731.attenuation;\n    float _3776 = _2731.shadow;\n    float _3783 = _2731._distance;\n    int _3784 = _2731.type;\n    bool _2734 = _3784 == 0;\n    if (_2734 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3779;\n        float _2745 = fa_shadow_factor(param_4, param_5);\n        _3776 = _2745;\n        _3774 *= _2745;\n    }\n    else\n    {\n        bool _2756 = _3784 != 0;\n        bool _2762;\n        if (_2756)\n        {\n            _2762 = _3781 > 0.0;\n        }\n        else\n        {\n            _2762 = _2756;\n        }\n        if (_2762)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3779;\n            float _2774 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3776 = _2774;\n            _3774 *= _2774;\n        }\n    }\n    bool _2784 = fa_mesh_fs_params[24].x > 0.5;\n    bool _2790;\n    if (_2784)\n    {\n        _2790 = _3781 > 0.0;\n    }\n    else\n    {\n        _2790 = _2784;\n    }\n    if (_2790)\n    {\n        float _2797;\n        if (_2734)\n        {\n            _2797 = 1000000000.0;\n        }\n        else\n        {\n            _2797 = _3783;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _3779;\n        float param_14 = _2797;\n        float _2815 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _3776 *= _2815;\n        _3774 *= _2815;\n    }\n    return LightSample(_3779, _3774, _3781, _3776, _3783, _3784);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2157 = int(fa_shadows[25].x + 0.5);\n    float _2167 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2172 = _2157 > 0;\n    bool _2181;\n    if (_2172)\n    {\n        int param = _2157 - 1;\n        _2181 = _2167 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2181 = _2172;\n    }\n    if (_2181)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2188 = _2157 > 1;\n        bool _2195;\n        if (_2188)\n        {\n            _2195 = _2167 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2195 = _2188;\n        }\n        if (_2195)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2201 = _2157 > 2;\n        bool _2208;\n        if (_2201)\n        {\n            _2208 = _2167 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2208 = _2201;\n        }\n        if (_2208)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2214 = _2157 > 3;\n        bool _2221;\n        if (_2214)\n        {\n            _2221 = _2167 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2221 = _2214;\n        }\n        if (_2221)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3615 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3615 = -_3615;\n    }\n    vec3 _3201 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3615, fa_world_tangent, fa_uv, fa_vertex_color, _3201, gl_FrontFacing);\n    Surface _3209 = fa_standard_surface(param_1);\n    vec3 _3646 = _3209.albedo;\n    float _3647 = _3209.alpha;\n    vec3 _3648 = _3209.normal;\n    float _3649 = _3209.metallic;\n    float _3650 = _3209.roughness;\n    float _3651 = _3209.occlusion;\n    vec3 _3652 = _3209.emission;\n    float _3653 = _3209.clearcoat;\n    float _3654 = _3209.clearcoat_roughness;\n    vec3 _3655 = _3209.sheen_color;\n    float _3656 = _3209.sheen_roughness;\n    float _3657 = _3209.anisotropy;\n    float _3658 = _3209.anisotropy_rotation;\n    float _3659 = _3209.specular;\n    float _3660 = _3209.ior;\n    vec3 _3661 = _3209.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3615, fa_world_tangent, fa_uv, fa_vertex_color, _3201, gl_FrontFacing);\n    Surface param_3 = _3209;\n    surface(param_2, param_3);\n    _3646 = param_3.albedo;\n    _3647 = param_3.alpha;\n    _3648 = param_3.normal;\n    _3649 = param_3.metallic;\n    _3650 = param_3.roughness;\n    _3651 = param_3.occlusion;\n    _3652 = param_3.emission;\n    _3653 = param_3.clearcoat;\n    _3654 = param_3.clearcoat_roughness;\n    _3655 = param_3.sheen_color;\n    _3656 = param_3.sheen_roughness;\n    _3657 = param_3.anisotropy;\n    _3658 = param_3.anisotropy_rotation;\n    _3659 = param_3.specular;\n    _3660 = param_3.ior;\n    _3661 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3615;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3646 = param_6;\n    _3648 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3646;\n    }\n    else\n    {\n        vec3 _3247 = _3648;\n        vec3 _3248 = normalize(_3247);\n        _3648 = _3248;\n        vec3 param_8 = _3248;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _3646) * _3651;\n        int _3267 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3267; ln++)\n        {\n            int param_9 = ln;\n            int _3280 = fa_cl_light(param_9);\n            bool _3283 = fa_lm.z > 0.5;\n            bool _3289;\n            if (_3283)\n            {\n                int param_10 = _3280;\n                _3289 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _3289 = _3283;\n            }\n            if (_3289)\n            {\n                continue;\n            }\n            int param_11 = _3280;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _3615;\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _3615, fa_world_tangent, fa_uv, fa_vertex_color, _3201, gl_FrontFacing);\n            Surface param_15 = Surface(_3646, _3647, _3648, _3649, _3650, _3651, _3652, _3653, _3654, _3655, _3656, _3657, _3658, _3659, _3660, _3661);\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _3316 = result;\n    vec3 _3317 = _3316 + _3652;\n    result = _3317;\n    vec3 param_17 = _3317;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _3326 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3333;\n    if (!_3326)\n    {\n        _3333 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3333 = _3326;\n    }\n    if (_3333)\n    {\n        vec3 _3342 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3348 = dot(_3342, fa_mesh_fs_params[9].xyz);\n        bool _3352 = fa_mesh_fs_params[9].w > 0.5;\n        float _3353;\n        if (_3352)\n        {\n            _3353 = _3348;\n        }\n        else\n        {\n            _3353 = length(_3342);\n        }\n        float _3365 = _3353 - fa_mesh_fs_params[8].x;\n        if (_3365 > 0.0)\n        {\n            float _3374 = fa_mesh_fs_params[7].w * _3365;\n            float tau = _3374 * _3374;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3390;\n                if (_3352)\n                {\n                    _3390 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3348);\n                }\n                else\n                {\n                    _3390 = fa_mesh_fs_params[0].y;\n                }\n                float _3411 = mix(_3390, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3353, 0.0, 1.0));\n                float _3415 = fa_world_pos.y - _3411;\n                float _3420 = _3411 - fa_mesh_fs_params[8].z;\n                float _3425 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3428 = _3420 <= 0.0;\n                bool _3429 = !_3428;\n                bool _3435;\n                if (_3429)\n                {\n                    _3435 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3435 = _3428;\n                }\n                float _3436;\n                if (_3435)\n                {\n                    _3436 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3436 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3420, 80.0));\n                }\n                bool _3463;\n                if (_3429)\n                {\n                    _3463 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3463 = _3428;\n                }\n                float _3464;\n                if (_3463)\n                {\n                    _3464 = fa_mesh_fs_params[8].y * _3420;\n                }\n                else\n                {\n                    _3464 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3420, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3489 = _3425 <= 0.0;\n                bool _3496;\n                if (!_3489)\n                {\n                    _3496 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3496 = _3489;\n                }\n                float _3497;\n                if (_3496)\n                {\n                    _3497 = fa_mesh_fs_params[8].y * _3425;\n                }\n                else\n                {\n                    _3497 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3425, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3524;\n                if (abs(_3415) < 0.001000000047497451305389404296875)\n                {\n                    _3524 = _3436;\n                }\n                else\n                {\n                    _3524 = (_3497 - _3464) / _3415;\n                }\n                tau += (_3365 * max(_3524, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3647);\n}\n\n",
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
            "size": 480,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_460",
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
            "inst_name": "_1200",
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
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
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
