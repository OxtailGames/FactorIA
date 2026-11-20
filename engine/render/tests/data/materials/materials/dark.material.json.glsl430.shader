{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "bccfdbb53ee48b05b8dde63187158cf27ea0b93537445c8a05fdc4dbc713dc01",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _445 = fa_mesh_fs_params[19].x < 0.0;\n    bool _452;\n    if (!_445)\n    {\n        _452 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    bool _460;\n    if (!_452)\n    {\n        _460 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _460 = _452;\n    }\n    bool _467;\n    if (!_460)\n    {\n        _467 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    if (_474)\n    {\n        return vec4(0.0);\n    }\n    vec4 _484 = vec4(world_pos, 1.0);\n    float _491 = dot(fa_mesh_fs_params[16], _484);\n    if (!(_491 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _513 = vec2(dot(fa_mesh_fs_params[14], _484), dot(fa_mesh_fs_params[15], _484)) / vec2(_491);\n    int _517 = int(fa_mesh_fs_params[18].x);\n    int _521 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _521) + clamp(int(floor(((_513.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _521 - 1)) * _517)) + clamp(int(floor(((_513.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _517 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _597 = fa_cluster_texel(param);\n    return ivec2(int(_597.x), int(_597.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2254 = fa_cluster_lookup(param);\n    fa_cl_slot = _2254.x;\n    fa_cl_local = _2254.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2402 = fa_linear_to_srgb(param);\n        c = _2402;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2410 = fa_srgb_to_linear(param_1);\n            c = _2410;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _204;\n    if (i.front_facing)\n    {\n        _204 = i.world_normal;\n    }\n    else\n    {\n        _204 = -i.world_normal;\n    }\n    vec3 _228 = normalize(i.world_tangent.xyz - (_204 * dot(_204, i.world_tangent.xyz)));\n    vec3 _256 = normalize(((_228 * m.x) + ((cross(_204, _228) * i.world_tangent.w) * m.y)) + (_204 * m.z));\n    vec3 _259;\n    if (i.front_facing)\n    {\n        _259 = _256;\n    }\n    else\n    {\n        _259 = -_256;\n    }\n    return _259;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2441 = fa_tex_fix(param_2, param_3);\n    vec4 _3453 = base_t;\n    _3453.x = _2441.x;\n    _3453.y = _2441.y;\n    _3453.z = _2441.z;\n    base_t = _3453;\n    vec4 _2455 = (_3453 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3333 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2487 = fa_tex_fix(param_6, param_7);\n        vec3 _2490 = (_2487 * 2.0) - vec3(1.0);\n        vec2 _2495 = _2490.xy * fa_mesh_fs_params[6].x;\n        vec3 _3461 = _2490;\n        _3461.x = _2495.x;\n        _3461.y = _2495.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3461;\n        _3333 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2524 = fa_tex_fix(param_12, param_13);\n    vec4 _3464 = mrt;\n    _3464.x = _2524.x;\n    _3464.y = _2524.y;\n    _3464.z = _2524.z;\n    mrt = _3464;\n    vec4 _2552 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2552.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2564 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2594 = fa_tex_fix(param_20, param_21);\n    float _3338 = fa_mesh_fs_params[20].x;\n    float _3339 = fa_mesh_fs_params[20].y;\n    float _3342 = fa_mesh_fs_params[20].z;\n    float _3341 = fa_mesh_fs_params[21].w;\n    float _3344 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3338 *= _2564.y;\n            _3339 *= _2564.z;\n            _3341 *= _2552.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3342 *= mrt.x;\n            _3344 *= mrt.w;\n        }\n    }\n    return Surface(_2455.xyz, _2455.w, _3333, clamp(fa_mesh_fs_params[5].x * _2524.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2524.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2564.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2594), _3338, _3339, fa_mesh_fs_params[21].xyz, _3341, _3342, fa_mesh_fs_params[20].w, _3344, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _678 = rect.zw - rect.xy;\n    vec2 _682 = _678 * atlas;\n    vec2 _686 = ddx * _682;\n    vec2 _690 = ddy * _682;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _678), clamp(0.5 * log2(max(max(dot(_686, _686), dot(_690, _690)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _725 = fa_mesh_fs_params[10].y < 0.5;\n    bool _732;\n    if (!_725)\n    {\n        _732 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _732 = _725;\n    }\n    if (_732)\n    {\n        return;\n    }\n    vec3 _738 = dFdx(world_pos);\n    vec3 _741 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _745 = fa_cluster_texel(param);\n    int _749 = int(_745.w);\n    if (_749 < 1)\n    {\n        return;\n    }\n    int _759 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _759;\n    vec4 _763 = fa_light_texel(param_1);\n    vec2 _766 = _763.yz;\n    int _770 = int(_763.w);\n    int param_2 = _759 + 1;\n    vec4 _775 = fa_light_texel(param_2);\n    float _776 = _775.x;\n    int _782 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _786 = int(_745.z);\n    vec3 _1052;\n    for (int k = 0; k < _749; k++)\n    {\n        int _799 = _786 + k;\n        int param_3 = _770 + (_799 >> 2);\n        int _817 = (_759 + 2) + (int(fa_light_texel(param_3)[_799 & 3]) * 7);\n        int param_4 = _817 + 6;\n        vec4 _822 = fa_light_texel(param_4);\n        if (((int(_822.w + 0.5) >> _782) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _817;\n        vec4 _837 = fa_light_texel(param_5);\n        int param_6 = _817 + 1;\n        vec4 _842 = fa_light_texel(param_6);\n        int param_7 = _817 + 2;\n        vec4 _847 = fa_light_texel(param_7);\n        vec3 _850 = _837.xyz;\n        float _855 = dot(_850, world_pos) + _837.w;\n        vec3 _857 = _842.xyz;\n        float _862 = dot(_857, world_pos) + _842.w;\n        vec3 _864 = _847.xyz;\n        float _869 = dot(_864, world_pos) + _847.w;\n        bool _874 = abs(_855) > 0.5;\n        bool _882;\n        if (!_874)\n        {\n            _882 = abs(_862) > 0.5;\n        }\n        else\n        {\n            _882 = _874;\n        }\n        bool _890;\n        if (!_882)\n        {\n            _890 = abs(_869) > 0.5;\n        }\n        else\n        {\n            _890 = _882;\n        }\n        if (_890)\n        {\n            continue;\n        }\n        float _905 = clamp(dot(geo_normal, normalize(_864)) * _822.z, 0.0, 1.0);\n        if (_905 <= 0.0)\n        {\n            continue;\n        }\n        float _925 = (clamp((0.5 - abs(_869)) * 10.0, 0.0, 1.0) * _905) * _822.x;\n        vec2 _933 = vec2(_855 + 0.5, 0.5 - _862);\n        vec2 _943 = vec2(dot(_850, _738), dot(_857, _738));\n        vec2 _953 = vec2(dot(_850, _741), dot(_857, _741));\n        int param_8 = _817 + 5;\n        vec4 _958 = fa_light_texel(param_8);\n        int param_9 = _817 + 3;\n        vec4 _963 = fa_light_texel(param_9);\n        int param_10 = _817 + 4;\n        vec4 _968 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _958.xyz;\n        bool _978 = _963.z > _963.x;\n        if (_978)\n        {\n            vec4 param_11 = _963;\n            vec2 param_12 = _933;\n            vec2 param_13 = _766;\n            vec2 param_14 = _943;\n            vec2 param_15 = _953;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_776 > 0.5) && (_776 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1004 = fa_dc_to_linear(param_16);\n                vec4 _3389 = tx;\n                _3389.x = _1004.x;\n                _3389.y = _1004.y;\n                _3389.z = _1004.z;\n                tx = _3389;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_925 * tex_a) * _958.w, 0.0, 1.0)));\n        if (_968.z > _968.x)\n        {\n            vec4 param_17 = _968;\n            vec2 param_18 = _933;\n            vec2 param_19 = _766;\n            vec2 param_20 = _943;\n            vec2 param_21 = _953;\n            vec4 _1048 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_776 > 1.5)\n            {\n                vec3 param_22 = _1048.xyz;\n                vec3 _1058 = fa_dc_to_srgb(param_22);\n                _1052 = _1058;\n            }\n            else\n            {\n                _1052 = _1048.xyz;\n            }\n            vec3 _1068 = (_1052 * 2.0) - vec3(1.0);\n            vec2 _1073 = _1068.xy * _822.y;\n            vec3 _1095 = (normalize(_850) * _1073.x) + (normalize(_857) * _1073.y);\n            vec3 _1098 = normalize(normal);\n            normal = normalize(mix(_1098, normalize((_1098 * max(_1068.z, 0.0500000007450580596923828125)) + (_1095 - (_1098 * dot(_1098, _1095)))), vec3(clamp(_925 * (_978 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _315 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _321 = fa_light_texel(param_1);\n    float _324 = _321.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _330 = _324 < 0.5;\n    vec3 l;\n    if (_330)\n    {\n        l = normalize(_315.xyz);\n    }\n    else\n    {\n        vec3 _342 = _315.xyz - world_pos;\n        float _344 = length(_342);\n        dist = _344;\n        l = _342 / vec3(max(_344, 9.9999997473787516355514526367188e-05));\n        float _359 = _344 / max(_315.w, 0.001000000047497451305389404296875);\n        float _365 = clamp(1.0 - (_359 * _359), 0.0, 1.0);\n        atten = _365 * _365;\n        if (_324 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _379 = fa_light_texel(param_2);\n            float _389 = _379.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _395 = fa_light_texel(param_3);\n            float _396 = _395.x;\n            float cos_inner = _396;\n            if (_396 > 1.5)\n            {\n                cos_inner = mix(_389, 1.0, 0.25);\n            }\n            atten *= smoothstep(_389, cos_inner, dot(-l, normalize(_379.xyz)));\n        }\n    }\n    int _426;\n    if (_330)\n    {\n        _426 = 0;\n    }\n    else\n    {\n        _426 = (_324 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _321.xyz * atten, atten, 1.0, dist, _426);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1170;\n    if (i == 0)\n    {\n        _1170 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1186;\n        if (i == 1)\n        {\n            _1186 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1194;\n            if (i == 2)\n            {\n                _1194 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1194 = fa_shadows[24].w;\n            }\n            _1186 = _1194;\n        }\n        _1170 = _1186;\n    }\n    return _1170;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1227 = fa_shadow_depth(param, param_1);\n    float _1231;\n    if (conv.x < 0.5)\n    {\n        _1231 = _1227;\n    }\n    else\n    {\n        _1231 = (conv.y * conv.z) / (conv.z - (_1227 * (conv.z - conv.y)));\n    }\n    return _1231;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1158 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1158), sin(_1158)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1277 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1291 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1277;\n            vec2 _1310 = fa_shadow_vogel(param_3, param_4, param_5) * _1291;\n            vec2 param_6 = uv + (_1310 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1322 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1322 < (zr - (length(_1310) * plane)))\n            {\n                sum += _1322;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1366 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1366; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1366;\n        float param_11 = _1277;\n        vec2 _1385 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1385 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1385) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1366);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1427 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1432 = clamp(dot(n, l), 0.0, 1.0);\n    float _1438 = sqrt(1.0 - (_1432 * _1432));\n    float _1445 = min(_1438 / max(_1432, 0.20000000298023223876953125), 4.0);\n    float _1450;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1450 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1450 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1475 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1450 * _1438)), 1.0);\n    float _1482 = _1475.x;\n    bool _1485 = _1482 < fa_shadows[ci * 1 + 16].x;\n    bool _1494;\n    if (!_1485)\n    {\n        _1494 = _1482 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1494 = _1485;\n    }\n    bool _1503;\n    if (!_1494)\n    {\n        _1503 = _1475.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1503 = _1494;\n    }\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1475.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1519;\n    if (!_1512)\n    {\n        _1519 = _1475.z > 1.0;\n    }\n    else\n    {\n        _1519 = _1512;\n    }\n    if (_1519)\n    {\n        return -1.0;\n    }\n    float _1528;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1528 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1528 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1475.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1475.z - ((_1528 * (1.0 + (0.5 * _1445))) / _1427);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1427;\n    float param_5 = _1427 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1445, 3.0)) * 0.5) / _1427;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1955 = int(fa_shadows[25].x + 0.5);\n    if (_1955 < 1)\n    {\n        return 1.0;\n    }\n    float _1970 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1955 - 1;\n    if (_1970 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1982 = _1955 > 1;\n    bool _1989;\n    if (_1982)\n    {\n        _1989 = _1970 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1989 = _1982;\n    }\n    if (_1989)\n    {\n        ci = 1;\n    }\n    bool _1993 = _1955 > 2;\n    bool _2000;\n    if (_1993)\n    {\n        _2000 = _1970 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2000 = _1993;\n    }\n    if (_2000)\n    {\n        ci = 2;\n    }\n    bool _2004 = _1955 > 3;\n    bool _2011;\n    if (_2004)\n    {\n        _2011 = _1970 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2011 = _2004;\n    }\n    if (_2011)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1955)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2037 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2037;\n        if (_2037 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2062;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2062 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2062 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2081 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2062, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2092 = clamp((_1970 - (fa_shadow_split_at(param_7) - _2081)) / _2081, 0.0, 1.0);\n        if (_2092 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1955)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2113 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2113;\n                if (_2113 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2092);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1586 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1594;\n    if (!_1586)\n    {\n        _1594 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1594 = _1586;\n    }\n    if (_1594)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1607 = fa_light_texel(param);\n    float _1608 = _1607.x;\n    if (_1608 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1617 = int(_1608 + 0.5);\n    int param_1 = _1617;\n    vec4 _1621 = fa_light_texel(param_1);\n    int param_2 = _1617 + 1;\n    vec4 _1626 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1629 = _1621.y;\n    if (_1629 > 0.0)\n    {\n        float _1646 = 1.0 - smoothstep(0.75 * _1629, _1629, length(world - fa_shadows[27].xyz));\n        fade = _1646;\n        if (_1646 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1621.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1665 = world - fa_light_texel(param_3).xyz;\n        vec3 _1668 = abs(_1665);\n        float _1670 = _1668.x;\n        float _1672 = _1668.y;\n        bool _1673 = _1670 >= _1672;\n        bool _1681;\n        if (_1673)\n        {\n            _1681 = _1670 >= _1668.z;\n        }\n        else\n        {\n            _1681 = _1673;\n        }\n        int _1682;\n        if (_1681)\n        {\n            _1682 = (_1665.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1695;\n            if (_1672 >= _1668.z)\n            {\n                _1695 = (_1665.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1695 = (_1665.z > 0.0) ? 4 : 5;\n            }\n            _1682 = _1695;\n        }\n        face = _1682;\n    }\n    int _1714 = (_1617 + 2) + (face * 6);\n    int param_4 = _1714;\n    int param_5 = _1714 + 1;\n    int param_6 = _1714 + 3;\n    vec4 _1728 = fa_light_texel(param_6);\n    int param_7 = _1714 + 4;\n    vec4 _1733 = fa_light_texel(param_7);\n    int param_8 = _1714 + 5;\n    vec4 _1738 = fa_light_texel(param_8);\n    float _1750 = _1738.x * max(dot(_1728, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1755 = clamp(dot(n, l), 0.0, 1.0);\n    float _1778 = clamp(dot(n, _1728.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1801 = min(sqrt(1.0 - (_1778 * _1778)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1728, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1804 = _1626.y;\n    float _1806;\n    if (_1804 > 0.0)\n    {\n        _1806 = _1804;\n    }\n    else\n    {\n        _1806 = 1.5 * _1750;\n    }\n    vec4 _1826 = vec4(world + (n * (_1806 * sqrt(1.0 - (_1755 * _1755)))), 1.0);\n    float _1830 = dot(_1728, _1826);\n    float _1833 = _1738.y;\n    if (_1830 < _1833)\n    {\n        return 1.0;\n    }\n    vec2 _1848 = vec2(dot(fa_light_texel(param_4), _1826), dot(fa_light_texel(param_5), _1826)) / vec2(_1830);\n    float _1850 = _1848.x;\n    bool _1853 = _1850 < _1733.x;\n    bool _1862;\n    if (!_1853)\n    {\n        _1862 = _1850 > _1733.z;\n    }\n    else\n    {\n        _1862 = _1853;\n    }\n    bool _1871;\n    if (!_1862)\n    {\n        _1871 = _1848.y < _1733.y;\n    }\n    else\n    {\n        _1871 = _1862;\n    }\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1848.y > _1733.w;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    if (_1880)\n    {\n        return 1.0;\n    }\n    float _1886 = _1626.x;\n    float _1888;\n    if (_1886 > 0.0)\n    {\n        _1888 = _1886;\n    }\n    else\n    {\n        _1888 = 1.5 * _1750;\n    }\n    vec2 param_10 = _1848;\n    vec4 param_11 = _1733;\n    float param_12 = _1830 - (_1888 * (1.0 + (0.5 * _1801)));\n    float param_13 = _1750;\n    float param_14 = 1.0;\n    float param_15 = _1738.z * 0.25;\n    float param_16 = (_1750 * min(_1801, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1833, _1738.z);\n    int param_18 = int(_1621.z + 0.5);\n    float param_19 = _1621.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2281 = fa_lm.z > 0.5;\n    bool _2287;\n    if (_2281)\n    {\n        int param = li;\n        _2287 = fa_light_baked(param);\n    }\n    else\n    {\n        _2287 = _2281;\n    }\n    if (_2287)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2310 = fa_light_sample(param_2, param_3);\n    vec3 _3318 = _2310.direction;\n    vec3 _3313 = _2310.color;\n    float _3320 = _2310.attenuation;\n    float _3315 = _2310.shadow;\n    int _3323 = _2310.type;\n    if ((_3323 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3318;\n        float _2324 = fa_shadow_factor(param_4, param_5);\n        _3315 = _2324;\n        _3313 *= _2324;\n    }\n    else\n    {\n        bool _2335 = _3323 != 0;\n        bool _2341;\n        if (_2335)\n        {\n            _2341 = _3320 > 0.0;\n        }\n        else\n        {\n            _2341 = _2335;\n        }\n        if (_2341)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3318;\n            float _2353 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3315 = _2353;\n            _3313 *= _2353;\n        }\n    }\n    return LightSample(_3318, _3313, _3320, _3315, _2310._distance, _3323);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2137 = int(fa_shadows[25].x + 0.5);\n    float _2147 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2152 = _2137 > 0;\n    bool _2161;\n    if (_2152)\n    {\n        int param = _2137 - 1;\n        _2161 = _2147 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2161 = _2152;\n    }\n    if (_2161)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2168 = _2137 > 1;\n        bool _2175;\n        if (_2168)\n        {\n            _2175 = _2147 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2175 = _2168;\n        }\n        if (_2175)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2181 = _2137 > 2;\n        bool _2188;\n        if (_2181)\n        {\n            _2188 = _2147 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2188 = _2181;\n        }\n        if (_2188)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2194 = _2137 > 3;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2147 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3154 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3154 = -_3154;\n    }\n    vec3 _2738 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3154, fa_world_tangent, fa_uv, fa_vertex_color, _2738, gl_FrontFacing);\n    Surface _2746 = fa_standard_surface(param_1);\n    vec3 _3185 = _2746.albedo;\n    float _3186 = _2746.alpha;\n    vec3 _3187 = _2746.normal;\n    float _3188 = _2746.metallic;\n    float _3189 = _2746.roughness;\n    float _3190 = _2746.occlusion;\n    vec3 _3191 = _2746.emission;\n    float _3192 = _2746.clearcoat;\n    float _3193 = _2746.clearcoat_roughness;\n    vec3 _3194 = _2746.sheen_color;\n    float _3195 = _2746.sheen_roughness;\n    float _3196 = _2746.anisotropy;\n    float _3197 = _2746.anisotropy_rotation;\n    float _3198 = _2746.specular;\n    float _3199 = _2746.ior;\n    vec3 _3200 = _2746.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3154, fa_world_tangent, fa_uv, fa_vertex_color, _2738, gl_FrontFacing);\n    Surface param_3 = _2746;\n    surface(param_2, param_3);\n    _3185 = param_3.albedo;\n    _3186 = param_3.alpha;\n    _3187 = param_3.normal;\n    _3188 = param_3.metallic;\n    _3189 = param_3.roughness;\n    _3190 = param_3.occlusion;\n    _3191 = param_3.emission;\n    _3192 = param_3.clearcoat;\n    _3193 = param_3.clearcoat_roughness;\n    _3194 = param_3.sheen_color;\n    _3195 = param_3.sheen_roughness;\n    _3196 = param_3.anisotropy;\n    _3197 = param_3.anisotropy_rotation;\n    _3198 = param_3.specular;\n    _3199 = param_3.ior;\n    _3200 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3154;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3185 = param_6;\n    _3187 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3185;\n    }\n    else\n    {\n        vec3 _2784 = _3187;\n        vec3 _2785 = normalize(_2784);\n        _3187 = _2785;\n        vec3 param_8 = _2785;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _3185) * _3190;\n        int _2804 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2804; ln++)\n        {\n            int param_9 = ln;\n            int _2817 = fa_cl_light(param_9);\n            bool _2820 = fa_lm.z > 0.5;\n            bool _2826;\n            if (_2820)\n            {\n                int param_10 = _2817;\n                _2826 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _2826 = _2820;\n            }\n            if (_2826)\n            {\n                continue;\n            }\n            int param_11 = _2817;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _3154;\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _3154, fa_world_tangent, fa_uv, fa_vertex_color, _2738, gl_FrontFacing);\n            Surface param_15 = Surface(_3185, _3186, _3187, _3188, _3189, _3190, _3191, _3192, _3193, _3194, _3195, _3196, _3197, _3198, _3199, _3200);\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _2853 = result;\n    vec3 _2854 = _2853 + _3191;\n    result = _2854;\n    vec3 param_17 = _2854;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _2863 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2870;\n    if (!_2863)\n    {\n        _2870 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2870 = _2863;\n    }\n    if (_2870)\n    {\n        vec3 _2879 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2885 = dot(_2879, fa_mesh_fs_params[9].xyz);\n        bool _2889 = fa_mesh_fs_params[9].w > 0.5;\n        float _2890;\n        if (_2889)\n        {\n            _2890 = _2885;\n        }\n        else\n        {\n            _2890 = length(_2879);\n        }\n        float _2902 = _2890 - fa_mesh_fs_params[8].x;\n        if (_2902 > 0.0)\n        {\n            float _2911 = fa_mesh_fs_params[7].w * _2902;\n            float tau = _2911 * _2911;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2927;\n                if (_2889)\n                {\n                    _2927 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2885);\n                }\n                else\n                {\n                    _2927 = fa_mesh_fs_params[0].y;\n                }\n                float _2948 = mix(_2927, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2890, 0.0, 1.0));\n                float _2952 = fa_world_pos.y - _2948;\n                float _2957 = _2948 - fa_mesh_fs_params[8].z;\n                float _2962 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2965 = _2957 <= 0.0;\n                bool _2966 = !_2965;\n                bool _2972;\n                if (_2966)\n                {\n                    _2972 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2972 = _2965;\n                }\n                float _2973;\n                if (_2972)\n                {\n                    _2973 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2973 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2957, 80.0));\n                }\n                bool _3000;\n                if (_2966)\n                {\n                    _3000 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3000 = _2965;\n                }\n                float _3001;\n                if (_3000)\n                {\n                    _3001 = fa_mesh_fs_params[8].y * _2957;\n                }\n                else\n                {\n                    _3001 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2957, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3026 = _2962 <= 0.0;\n                bool _3033;\n                if (!_3026)\n                {\n                    _3033 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3033 = _3026;\n                }\n                float _3034;\n                if (_3033)\n                {\n                    _3034 = fa_mesh_fs_params[8].y * _2962;\n                }\n                else\n                {\n                    _3034 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2962, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3061;\n                if (abs(_2952) < 0.001000000047497451305389404296875)\n                {\n                    _3061 = _2973;\n                }\n                else\n                {\n                    _3061 = (_3034 - _3001) / _2952;\n                }\n                tau += (_2902 * max(_3061, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3186);\n}\n\n",
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
            "inst_name": "_440",
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
            "inst_name": "_1180",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _445 = fa_mesh_fs_params[19].x < 0.0;\n    bool _452;\n    if (!_445)\n    {\n        _452 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    bool _460;\n    if (!_452)\n    {\n        _460 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _460 = _452;\n    }\n    bool _467;\n    if (!_460)\n    {\n        _467 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _467 = _460;\n    }\n    bool _474;\n    if (!_467)\n    {\n        _474 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _474 = _467;\n    }\n    if (_474)\n    {\n        return vec4(0.0);\n    }\n    vec4 _484 = vec4(world_pos, 1.0);\n    float _491 = dot(fa_mesh_fs_params[16], _484);\n    if (!(_491 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _513 = vec2(dot(fa_mesh_fs_params[14], _484), dot(fa_mesh_fs_params[15], _484)) / vec2(_491);\n    int _517 = int(fa_mesh_fs_params[18].x);\n    int _521 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _521) + clamp(int(floor(((_513.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _521 - 1)) * _517)) + clamp(int(floor(((_513.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _517 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _597 = fa_cluster_texel(param);\n    return ivec2(int(_597.x), int(_597.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2254 = fa_cluster_lookup(param);\n    fa_cl_slot = _2254.x;\n    fa_cl_local = _2254.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2402 = fa_linear_to_srgb(param);\n        c = _2402;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2410 = fa_srgb_to_linear(param_1);\n            c = _2410;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _204;\n    if (i.front_facing)\n    {\n        _204 = i.world_normal;\n    }\n    else\n    {\n        _204 = -i.world_normal;\n    }\n    vec3 _228 = normalize(i.world_tangent.xyz - (_204 * dot(_204, i.world_tangent.xyz)));\n    vec3 _256 = normalize(((_228 * m.x) + ((cross(_204, _228) * i.world_tangent.w) * m.y)) + (_204 * m.z));\n    vec3 _259;\n    if (i.front_facing)\n    {\n        _259 = _256;\n    }\n    else\n    {\n        _259 = -_256;\n    }\n    return _259;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2441 = fa_tex_fix(param_2, param_3);\n    vec4 _3453 = base_t;\n    _3453.x = _2441.x;\n    _3453.y = _2441.y;\n    _3453.z = _2441.z;\n    base_t = _3453;\n    vec4 _2455 = (_3453 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3333 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2487 = fa_tex_fix(param_6, param_7);\n        vec3 _2490 = (_2487 * 2.0) - vec3(1.0);\n        vec2 _2495 = _2490.xy * fa_mesh_fs_params[6].x;\n        vec3 _3461 = _2490;\n        _3461.x = _2495.x;\n        _3461.y = _2495.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3461;\n        _3333 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2524 = fa_tex_fix(param_12, param_13);\n    vec4 _3464 = mrt;\n    _3464.x = _2524.x;\n    _3464.y = _2524.y;\n    _3464.z = _2524.z;\n    mrt = _3464;\n    vec4 _2552 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2552.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2564 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2594 = fa_tex_fix(param_20, param_21);\n    float _3338 = fa_mesh_fs_params[20].x;\n    float _3339 = fa_mesh_fs_params[20].y;\n    float _3342 = fa_mesh_fs_params[20].z;\n    float _3341 = fa_mesh_fs_params[21].w;\n    float _3344 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3338 *= _2564.y;\n            _3339 *= _2564.z;\n            _3341 *= _2552.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3342 *= mrt.x;\n            _3344 *= mrt.w;\n        }\n    }\n    return Surface(_2455.xyz, _2455.w, _3333, clamp(fa_mesh_fs_params[5].x * _2524.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2524.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2564.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2594), _3338, _3339, fa_mesh_fs_params[21].xyz, _3341, _3342, fa_mesh_fs_params[20].w, _3344, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _678 = rect.zw - rect.xy;\n    vec2 _682 = _678 * atlas;\n    vec2 _686 = ddx * _682;\n    vec2 _690 = ddy * _682;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _678), clamp(0.5 * log2(max(max(dot(_686, _686), dot(_690, _690)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _725 = fa_mesh_fs_params[10].y < 0.5;\n    bool _732;\n    if (!_725)\n    {\n        _732 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _732 = _725;\n    }\n    if (_732)\n    {\n        return;\n    }\n    vec3 _738 = dFdx(world_pos);\n    vec3 _741 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _745 = fa_cluster_texel(param);\n    int _749 = int(_745.w);\n    if (_749 < 1)\n    {\n        return;\n    }\n    int _759 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _759;\n    vec4 _763 = fa_light_texel(param_1);\n    vec2 _766 = _763.yz;\n    int _770 = int(_763.w);\n    int param_2 = _759 + 1;\n    vec4 _775 = fa_light_texel(param_2);\n    float _776 = _775.x;\n    int _782 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _786 = int(_745.z);\n    vec3 _1052;\n    for (int k = 0; k < _749; k++)\n    {\n        int _799 = _786 + k;\n        int param_3 = _770 + (_799 >> 2);\n        int _817 = (_759 + 2) + (int(fa_light_texel(param_3)[_799 & 3]) * 7);\n        int param_4 = _817 + 6;\n        vec4 _822 = fa_light_texel(param_4);\n        if (((int(_822.w + 0.5) >> _782) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _817;\n        vec4 _837 = fa_light_texel(param_5);\n        int param_6 = _817 + 1;\n        vec4 _842 = fa_light_texel(param_6);\n        int param_7 = _817 + 2;\n        vec4 _847 = fa_light_texel(param_7);\n        vec3 _850 = _837.xyz;\n        float _855 = dot(_850, world_pos) + _837.w;\n        vec3 _857 = _842.xyz;\n        float _862 = dot(_857, world_pos) + _842.w;\n        vec3 _864 = _847.xyz;\n        float _869 = dot(_864, world_pos) + _847.w;\n        bool _874 = abs(_855) > 0.5;\n        bool _882;\n        if (!_874)\n        {\n            _882 = abs(_862) > 0.5;\n        }\n        else\n        {\n            _882 = _874;\n        }\n        bool _890;\n        if (!_882)\n        {\n            _890 = abs(_869) > 0.5;\n        }\n        else\n        {\n            _890 = _882;\n        }\n        if (_890)\n        {\n            continue;\n        }\n        float _905 = clamp(dot(geo_normal, normalize(_864)) * _822.z, 0.0, 1.0);\n        if (_905 <= 0.0)\n        {\n            continue;\n        }\n        float _925 = (clamp((0.5 - abs(_869)) * 10.0, 0.0, 1.0) * _905) * _822.x;\n        vec2 _933 = vec2(_855 + 0.5, 0.5 - _862);\n        vec2 _943 = vec2(dot(_850, _738), dot(_857, _738));\n        vec2 _953 = vec2(dot(_850, _741), dot(_857, _741));\n        int param_8 = _817 + 5;\n        vec4 _958 = fa_light_texel(param_8);\n        int param_9 = _817 + 3;\n        vec4 _963 = fa_light_texel(param_9);\n        int param_10 = _817 + 4;\n        vec4 _968 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _958.xyz;\n        bool _978 = _963.z > _963.x;\n        if (_978)\n        {\n            vec4 param_11 = _963;\n            vec2 param_12 = _933;\n            vec2 param_13 = _766;\n            vec2 param_14 = _943;\n            vec2 param_15 = _953;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_776 > 0.5) && (_776 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1004 = fa_dc_to_linear(param_16);\n                vec4 _3389 = tx;\n                _3389.x = _1004.x;\n                _3389.y = _1004.y;\n                _3389.z = _1004.z;\n                tx = _3389;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_925 * tex_a) * _958.w, 0.0, 1.0)));\n        if (_968.z > _968.x)\n        {\n            vec4 param_17 = _968;\n            vec2 param_18 = _933;\n            vec2 param_19 = _766;\n            vec2 param_20 = _943;\n            vec2 param_21 = _953;\n            vec4 _1048 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_776 > 1.5)\n            {\n                vec3 param_22 = _1048.xyz;\n                vec3 _1058 = fa_dc_to_srgb(param_22);\n                _1052 = _1058;\n            }\n            else\n            {\n                _1052 = _1048.xyz;\n            }\n            vec3 _1068 = (_1052 * 2.0) - vec3(1.0);\n            vec2 _1073 = _1068.xy * _822.y;\n            vec3 _1095 = (normalize(_850) * _1073.x) + (normalize(_857) * _1073.y);\n            vec3 _1098 = normalize(normal);\n            normal = normalize(mix(_1098, normalize((_1098 * max(_1068.z, 0.0500000007450580596923828125)) + (_1095 - (_1098 * dot(_1098, _1095)))), vec3(clamp(_925 * (_978 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _315 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _321 = fa_light_texel(param_1);\n    float _324 = _321.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _330 = _324 < 0.5;\n    vec3 l;\n    if (_330)\n    {\n        l = normalize(_315.xyz);\n    }\n    else\n    {\n        vec3 _342 = _315.xyz - world_pos;\n        float _344 = length(_342);\n        dist = _344;\n        l = _342 / vec3(max(_344, 9.9999997473787516355514526367188e-05));\n        float _359 = _344 / max(_315.w, 0.001000000047497451305389404296875);\n        float _365 = clamp(1.0 - (_359 * _359), 0.0, 1.0);\n        atten = _365 * _365;\n        if (_324 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _379 = fa_light_texel(param_2);\n            float _389 = _379.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _395 = fa_light_texel(param_3);\n            float _396 = _395.x;\n            float cos_inner = _396;\n            if (_396 > 1.5)\n            {\n                cos_inner = mix(_389, 1.0, 0.25);\n            }\n            atten *= smoothstep(_389, cos_inner, dot(-l, normalize(_379.xyz)));\n        }\n    }\n    int _426;\n    if (_330)\n    {\n        _426 = 0;\n    }\n    else\n    {\n        _426 = (_324 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _321.xyz * atten, atten, 1.0, dist, _426);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1170;\n    if (i == 0)\n    {\n        _1170 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1186;\n        if (i == 1)\n        {\n            _1186 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1194;\n            if (i == 2)\n            {\n                _1194 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1194 = fa_shadows[24].w;\n            }\n            _1186 = _1194;\n        }\n        _1170 = _1186;\n    }\n    return _1170;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1227 = fa_shadow_depth(param, param_1);\n    float _1231;\n    if (conv.x < 0.5)\n    {\n        _1231 = _1227;\n    }\n    else\n    {\n        _1231 = (conv.y * conv.z) / (conv.z - (_1227 * (conv.z - conv.y)));\n    }\n    return _1231;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1158 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1158), sin(_1158)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1277 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1291 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1277;\n            vec2 _1310 = fa_shadow_vogel(param_3, param_4, param_5) * _1291;\n            vec2 param_6 = uv + (_1310 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1322 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1322 < (zr - (length(_1310) * plane)))\n            {\n                sum += _1322;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1366 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1366; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1366;\n        float param_11 = _1277;\n        vec2 _1385 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1385 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1385) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1366);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1427 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1432 = clamp(dot(n, l), 0.0, 1.0);\n    float _1438 = sqrt(1.0 - (_1432 * _1432));\n    float _1445 = min(_1438 / max(_1432, 0.20000000298023223876953125), 4.0);\n    float _1450;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1450 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1450 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1475 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1450 * _1438)), 1.0);\n    float _1482 = _1475.x;\n    bool _1485 = _1482 < fa_shadows[ci * 1 + 16].x;\n    bool _1494;\n    if (!_1485)\n    {\n        _1494 = _1482 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1494 = _1485;\n    }\n    bool _1503;\n    if (!_1494)\n    {\n        _1503 = _1475.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1503 = _1494;\n    }\n    bool _1512;\n    if (!_1503)\n    {\n        _1512 = _1475.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1512 = _1503;\n    }\n    bool _1519;\n    if (!_1512)\n    {\n        _1519 = _1475.z > 1.0;\n    }\n    else\n    {\n        _1519 = _1512;\n    }\n    if (_1519)\n    {\n        return -1.0;\n    }\n    float _1528;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1528 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1528 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1475.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1475.z - ((_1528 * (1.0 + (0.5 * _1445))) / _1427);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1427;\n    float param_5 = _1427 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1445, 3.0)) * 0.5) / _1427;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1955 = int(fa_shadows[25].x + 0.5);\n    if (_1955 < 1)\n    {\n        return 1.0;\n    }\n    float _1970 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1955 - 1;\n    if (_1970 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1982 = _1955 > 1;\n    bool _1989;\n    if (_1982)\n    {\n        _1989 = _1970 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1989 = _1982;\n    }\n    if (_1989)\n    {\n        ci = 1;\n    }\n    bool _1993 = _1955 > 2;\n    bool _2000;\n    if (_1993)\n    {\n        _2000 = _1970 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2000 = _1993;\n    }\n    if (_2000)\n    {\n        ci = 2;\n    }\n    bool _2004 = _1955 > 3;\n    bool _2011;\n    if (_2004)\n    {\n        _2011 = _1970 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2011 = _2004;\n    }\n    if (_2011)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1955)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2037 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2037;\n        if (_2037 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2062;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2062 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2062 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2081 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2062, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2092 = clamp((_1970 - (fa_shadow_split_at(param_7) - _2081)) / _2081, 0.0, 1.0);\n        if (_2092 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1955)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2113 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2113;\n                if (_2113 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2092);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1586 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1594;\n    if (!_1586)\n    {\n        _1594 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1594 = _1586;\n    }\n    if (_1594)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1607 = fa_light_texel(param);\n    float _1608 = _1607.x;\n    if (_1608 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1617 = int(_1608 + 0.5);\n    int param_1 = _1617;\n    vec4 _1621 = fa_light_texel(param_1);\n    int param_2 = _1617 + 1;\n    vec4 _1626 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1629 = _1621.y;\n    if (_1629 > 0.0)\n    {\n        float _1646 = 1.0 - smoothstep(0.75 * _1629, _1629, length(world - fa_shadows[27].xyz));\n        fade = _1646;\n        if (_1646 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1621.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1665 = world - fa_light_texel(param_3).xyz;\n        vec3 _1668 = abs(_1665);\n        float _1670 = _1668.x;\n        float _1672 = _1668.y;\n        bool _1673 = _1670 >= _1672;\n        bool _1681;\n        if (_1673)\n        {\n            _1681 = _1670 >= _1668.z;\n        }\n        else\n        {\n            _1681 = _1673;\n        }\n        int _1682;\n        if (_1681)\n        {\n            _1682 = (_1665.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1695;\n            if (_1672 >= _1668.z)\n            {\n                _1695 = (_1665.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1695 = (_1665.z > 0.0) ? 4 : 5;\n            }\n            _1682 = _1695;\n        }\n        face = _1682;\n    }\n    int _1714 = (_1617 + 2) + (face * 6);\n    int param_4 = _1714;\n    int param_5 = _1714 + 1;\n    int param_6 = _1714 + 3;\n    vec4 _1728 = fa_light_texel(param_6);\n    int param_7 = _1714 + 4;\n    vec4 _1733 = fa_light_texel(param_7);\n    int param_8 = _1714 + 5;\n    vec4 _1738 = fa_light_texel(param_8);\n    float _1750 = _1738.x * max(dot(_1728, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1755 = clamp(dot(n, l), 0.0, 1.0);\n    float _1778 = clamp(dot(n, _1728.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1801 = min(sqrt(1.0 - (_1778 * _1778)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1728, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1804 = _1626.y;\n    float _1806;\n    if (_1804 > 0.0)\n    {\n        _1806 = _1804;\n    }\n    else\n    {\n        _1806 = 1.5 * _1750;\n    }\n    vec4 _1826 = vec4(world + (n * (_1806 * sqrt(1.0 - (_1755 * _1755)))), 1.0);\n    float _1830 = dot(_1728, _1826);\n    float _1833 = _1738.y;\n    if (_1830 < _1833)\n    {\n        return 1.0;\n    }\n    vec2 _1848 = vec2(dot(fa_light_texel(param_4), _1826), dot(fa_light_texel(param_5), _1826)) / vec2(_1830);\n    float _1850 = _1848.x;\n    bool _1853 = _1850 < _1733.x;\n    bool _1862;\n    if (!_1853)\n    {\n        _1862 = _1850 > _1733.z;\n    }\n    else\n    {\n        _1862 = _1853;\n    }\n    bool _1871;\n    if (!_1862)\n    {\n        _1871 = _1848.y < _1733.y;\n    }\n    else\n    {\n        _1871 = _1862;\n    }\n    bool _1880;\n    if (!_1871)\n    {\n        _1880 = _1848.y > _1733.w;\n    }\n    else\n    {\n        _1880 = _1871;\n    }\n    if (_1880)\n    {\n        return 1.0;\n    }\n    float _1886 = _1626.x;\n    float _1888;\n    if (_1886 > 0.0)\n    {\n        _1888 = _1886;\n    }\n    else\n    {\n        _1888 = 1.5 * _1750;\n    }\n    vec2 param_10 = _1848;\n    vec4 param_11 = _1733;\n    float param_12 = _1830 - (_1888 * (1.0 + (0.5 * _1801)));\n    float param_13 = _1750;\n    float param_14 = 1.0;\n    float param_15 = _1738.z * 0.25;\n    float param_16 = (_1750 * min(_1801, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1833, _1738.z);\n    int param_18 = int(_1621.z + 0.5);\n    float param_19 = _1621.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2281 = fa_lm.z > 0.5;\n    bool _2287;\n    if (_2281)\n    {\n        int param = li;\n        _2287 = fa_light_baked(param);\n    }\n    else\n    {\n        _2287 = _2281;\n    }\n    if (_2287)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2310 = fa_light_sample(param_2, param_3);\n    vec3 _3318 = _2310.direction;\n    vec3 _3313 = _2310.color;\n    float _3320 = _2310.attenuation;\n    float _3315 = _2310.shadow;\n    int _3323 = _2310.type;\n    if ((_3323 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3318;\n        float _2324 = fa_shadow_factor(param_4, param_5);\n        _3315 = _2324;\n        _3313 *= _2324;\n    }\n    else\n    {\n        bool _2335 = _3323 != 0;\n        bool _2341;\n        if (_2335)\n        {\n            _2341 = _3320 > 0.0;\n        }\n        else\n        {\n            _2341 = _2335;\n        }\n        if (_2341)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3318;\n            float _2353 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3315 = _2353;\n            _3313 *= _2353;\n        }\n    }\n    return LightSample(_3318, _3313, _3320, _3315, _2310._distance, _3323);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2137 = int(fa_shadows[25].x + 0.5);\n    float _2147 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2152 = _2137 > 0;\n    bool _2161;\n    if (_2152)\n    {\n        int param = _2137 - 1;\n        _2161 = _2147 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2161 = _2152;\n    }\n    if (_2161)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2168 = _2137 > 1;\n        bool _2175;\n        if (_2168)\n        {\n            _2175 = _2147 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2175 = _2168;\n        }\n        if (_2175)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2181 = _2137 > 2;\n        bool _2188;\n        if (_2181)\n        {\n            _2188 = _2147 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2188 = _2181;\n        }\n        if (_2188)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2194 = _2137 > 3;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2147 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3154 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3154 = -_3154;\n    }\n    vec3 _2738 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3154, fa_world_tangent, fa_uv, fa_vertex_color, _2738, gl_FrontFacing);\n    Surface _2746 = fa_standard_surface(param_1);\n    vec3 _3185 = _2746.albedo;\n    float _3186 = _2746.alpha;\n    vec3 _3187 = _2746.normal;\n    float _3188 = _2746.metallic;\n    float _3189 = _2746.roughness;\n    float _3190 = _2746.occlusion;\n    vec3 _3191 = _2746.emission;\n    float _3192 = _2746.clearcoat;\n    float _3193 = _2746.clearcoat_roughness;\n    vec3 _3194 = _2746.sheen_color;\n    float _3195 = _2746.sheen_roughness;\n    float _3196 = _2746.anisotropy;\n    float _3197 = _2746.anisotropy_rotation;\n    float _3198 = _2746.specular;\n    float _3199 = _2746.ior;\n    vec3 _3200 = _2746.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3154, fa_world_tangent, fa_uv, fa_vertex_color, _2738, gl_FrontFacing);\n    Surface param_3 = _2746;\n    surface(param_2, param_3);\n    _3185 = param_3.albedo;\n    _3186 = param_3.alpha;\n    _3187 = param_3.normal;\n    _3188 = param_3.metallic;\n    _3189 = param_3.roughness;\n    _3190 = param_3.occlusion;\n    _3191 = param_3.emission;\n    _3192 = param_3.clearcoat;\n    _3193 = param_3.clearcoat_roughness;\n    _3194 = param_3.sheen_color;\n    _3195 = param_3.sheen_roughness;\n    _3196 = param_3.anisotropy;\n    _3197 = param_3.anisotropy_rotation;\n    _3198 = param_3.specular;\n    _3199 = param_3.ior;\n    _3200 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3154;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3185 = param_6;\n    _3187 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3185;\n    }\n    else\n    {\n        vec3 _2784 = _3187;\n        vec3 _2785 = normalize(_2784);\n        _3187 = _2785;\n        vec3 param_8 = _2785;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _3185) * _3190;\n        int _2804 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2804; ln++)\n        {\n            int param_9 = ln;\n            int _2817 = fa_cl_light(param_9);\n            bool _2820 = fa_lm.z > 0.5;\n            bool _2826;\n            if (_2820)\n            {\n                int param_10 = _2817;\n                _2826 = fa_light_baked(param_10);\n            }\n            else\n            {\n                _2826 = _2820;\n            }\n            if (_2826)\n            {\n                continue;\n            }\n            int param_11 = _2817;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _3154;\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _3154, fa_world_tangent, fa_uv, fa_vertex_color, _2738, gl_FrontFacing);\n            Surface param_15 = Surface(_3185, _3186, _3187, _3188, _3189, _3190, _3191, _3192, _3193, _3194, _3195, _3196, _3197, _3198, _3199, _3200);\n            LightSample param_16 = fa_light_shadowed(param_11, param_12, param_13);\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _2853 = result;\n    vec3 _2854 = _2853 + _3191;\n    result = _2854;\n    vec3 param_17 = _2854;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _2863 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2870;\n    if (!_2863)\n    {\n        _2870 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2870 = _2863;\n    }\n    if (_2870)\n    {\n        vec3 _2879 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2885 = dot(_2879, fa_mesh_fs_params[9].xyz);\n        bool _2889 = fa_mesh_fs_params[9].w > 0.5;\n        float _2890;\n        if (_2889)\n        {\n            _2890 = _2885;\n        }\n        else\n        {\n            _2890 = length(_2879);\n        }\n        float _2902 = _2890 - fa_mesh_fs_params[8].x;\n        if (_2902 > 0.0)\n        {\n            float _2911 = fa_mesh_fs_params[7].w * _2902;\n            float tau = _2911 * _2911;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2927;\n                if (_2889)\n                {\n                    _2927 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2885);\n                }\n                else\n                {\n                    _2927 = fa_mesh_fs_params[0].y;\n                }\n                float _2948 = mix(_2927, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2890, 0.0, 1.0));\n                float _2952 = fa_world_pos.y - _2948;\n                float _2957 = _2948 - fa_mesh_fs_params[8].z;\n                float _2962 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2965 = _2957 <= 0.0;\n                bool _2966 = !_2965;\n                bool _2972;\n                if (_2966)\n                {\n                    _2972 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2972 = _2965;\n                }\n                float _2973;\n                if (_2972)\n                {\n                    _2973 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2973 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2957, 80.0));\n                }\n                bool _3000;\n                if (_2966)\n                {\n                    _3000 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3000 = _2965;\n                }\n                float _3001;\n                if (_3000)\n                {\n                    _3001 = fa_mesh_fs_params[8].y * _2957;\n                }\n                else\n                {\n                    _3001 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2957, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3026 = _2962 <= 0.0;\n                bool _3033;\n                if (!_3026)\n                {\n                    _3033 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3033 = _3026;\n                }\n                float _3034;\n                if (_3033)\n                {\n                    _3034 = fa_mesh_fs_params[8].y * _2962;\n                }\n                else\n                {\n                    _3034 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2962, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3061;\n                if (abs(_2952) < 0.001000000047497451305389404296875)\n                {\n                    _3061 = _2973;\n                }\n                else\n                {\n                    _3061 = (_3034 - _3001) / _2952;\n                }\n                tau += (_2902 * max(_3061, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3186);\n}\n\n",
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
            "inst_name": "_440",
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
            "inst_name": "_1180",
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _784 = base_t;\n    _784.x = _225.x;\n    _784.y = _225.y;\n    _784.z = _225.z;\n    base_t = _784;\n    vec4 _241 = (_784 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _747 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _792 = _279;\n        _792.x = _284.x;\n        _792.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _792;\n        _747 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _795 = mrt;\n    _795.x = _313.x;\n    _795.y = _313.y;\n    _795.z = _313.z;\n    mrt = _795;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _752 = fa_mesh_fs_params[20].x;\n    float _753 = fa_mesh_fs_params[20].y;\n    float _756 = fa_mesh_fs_params[20].z;\n    float _755 = fa_mesh_fs_params[21].w;\n    float _758 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _752 *= _355.y;\n            _753 *= _355.z;\n            _755 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _756 *= mrt.x;\n            _758 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _747, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _752, _753, fa_mesh_fs_params[21].xyz, _755, _756, fa_mesh_fs_params[20].w, _758, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _658 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _658 = -_658;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _658, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
