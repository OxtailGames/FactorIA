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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _471 = fa_mesh_fs_params[19].x < 0.0;\n    bool _478;\n    if (!_471)\n    {\n        _478 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _478 = _471;\n    }\n    bool _486;\n    if (!_478)\n    {\n        _486 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _486 = _478;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    bool _500;\n    if (!_493)\n    {\n        _500 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _500 = _493;\n    }\n    if (_500)\n    {\n        return vec4(0.0);\n    }\n    vec4 _510 = vec4(world_pos, 1.0);\n    float _517 = dot(fa_mesh_fs_params[16], _510);\n    if (!(_517 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _539 = vec2(dot(fa_mesh_fs_params[14], _510), dot(fa_mesh_fs_params[15], _510)) / vec2(_517);\n    int _543 = int(fa_mesh_fs_params[18].x);\n    int _547 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _547) + clamp(int(floor(((_539.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _547 - 1)) * _543)) + clamp(int(floor(((_539.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _543 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _623 = fa_cluster_texel(param);\n    return ivec2(int(_623.x), int(_623.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2681 = fa_cluster_lookup(param);\n    fa_cl_slot = _2681.x;\n    fa_cl_local = _2681.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2876 = fa_linear_to_srgb(param);\n        c = _2876;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2884 = fa_srgb_to_linear(param_1);\n            c = _2884;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _231;\n    if (i.front_facing)\n    {\n        _231 = i.world_normal;\n    }\n    else\n    {\n        _231 = -i.world_normal;\n    }\n    vec3 _255 = normalize(i.world_tangent.xyz - (_231 * dot(_231, i.world_tangent.xyz)));\n    vec3 _282 = normalize(((_255 * m.x) + ((cross(_231, _255) * i.world_tangent.w) * m.y)) + (_231 * m.z));\n    vec3 _285;\n    if (i.front_facing)\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2915 = fa_tex_fix(param_2, param_3);\n    vec4 _3961 = base_t;\n    _3961.x = _2915.x;\n    _3961.y = _2915.y;\n    _3961.z = _2915.z;\n    base_t = _3961;\n    vec4 _2929 = (_3961 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3828 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2961 = fa_tex_fix(param_6, param_7);\n        vec3 _2964 = (_2961 * 2.0) - vec3(1.0);\n        vec2 _2969 = _2964.xy * fa_mesh_fs_params[6].x;\n        vec3 _3969 = _2964;\n        _3969.x = _2969.x;\n        _3969.y = _2969.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3969;\n        _3828 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2998 = fa_tex_fix(param_12, param_13);\n    vec4 _3972 = mrt;\n    _3972.x = _2998.x;\n    _3972.y = _2998.y;\n    _3972.z = _2998.z;\n    mrt = _3972;\n    vec4 _3026 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3026.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3038 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3068 = fa_tex_fix(param_20, param_21);\n    float _3833 = fa_mesh_fs_params[20].x;\n    float _3834 = fa_mesh_fs_params[20].y;\n    float _3837 = fa_mesh_fs_params[20].z;\n    float _3836 = fa_mesh_fs_params[21].w;\n    float _3839 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3833 *= _3038.y;\n            _3834 *= _3038.z;\n            _3836 *= _3026.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3837 *= mrt.x;\n            _3839 *= mrt.w;\n        }\n    }\n    return Surface(_2929.xyz, _2929.w, _3828, clamp(fa_mesh_fs_params[5].x * _2998.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2998.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3038.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3068), _3833, _3834, fa_mesh_fs_params[21].xyz, _3836, _3837, fa_mesh_fs_params[20].w, _3839, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _704 = rect.zw - rect.xy;\n    vec2 _708 = _704 * atlas;\n    vec2 _712 = ddx * _708;\n    vec2 _716 = ddy * _708;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _704), clamp(0.5 * log2(max(max(dot(_712, _712), dot(_716, _716)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _751 = fa_mesh_fs_params[10].y < 0.5;\n    bool _758;\n    if (!_751)\n    {\n        _758 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _758 = _751;\n    }\n    if (_758)\n    {\n        return;\n    }\n    vec3 _764 = dFdx(world_pos);\n    vec3 _767 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _771 = fa_cluster_texel(param);\n    int _775 = int(_771.w);\n    if (_775 < 1)\n    {\n        return;\n    }\n    int _785 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _785;\n    vec4 _789 = fa_light_texel(param_1);\n    vec2 _792 = _789.yz;\n    int _796 = int(_789.w);\n    int param_2 = _785 + 1;\n    vec4 _801 = fa_light_texel(param_2);\n    float _802 = _801.x;\n    int _808 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _812 = int(_771.z);\n    vec3 _1078;\n    for (int k = 0; k < _775; k++)\n    {\n        int _825 = _812 + k;\n        int param_3 = _796 + (_825 >> 2);\n        int _843 = (_785 + 2) + (int(fa_light_texel(param_3)[_825 & 3]) * 7);\n        int param_4 = _843 + 6;\n        vec4 _848 = fa_light_texel(param_4);\n        if (((int(_848.w + 0.5) >> _808) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _843;\n        vec4 _863 = fa_light_texel(param_5);\n        int param_6 = _843 + 1;\n        vec4 _868 = fa_light_texel(param_6);\n        int param_7 = _843 + 2;\n        vec4 _873 = fa_light_texel(param_7);\n        vec3 _876 = _863.xyz;\n        float _881 = dot(_876, world_pos) + _863.w;\n        vec3 _883 = _868.xyz;\n        float _888 = dot(_883, world_pos) + _868.w;\n        vec3 _890 = _873.xyz;\n        float _895 = dot(_890, world_pos) + _873.w;\n        bool _900 = abs(_881) > 0.5;\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_888) > 0.5;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        bool _916;\n        if (!_908)\n        {\n            _916 = abs(_895) > 0.5;\n        }\n        else\n        {\n            _916 = _908;\n        }\n        if (_916)\n        {\n            continue;\n        }\n        float _931 = clamp(dot(geo_normal, normalize(_890)) * _848.z, 0.0, 1.0);\n        if (_931 <= 0.0)\n        {\n            continue;\n        }\n        float _951 = (clamp((0.5 - abs(_895)) * 10.0, 0.0, 1.0) * _931) * _848.x;\n        vec2 _959 = vec2(_881 + 0.5, 0.5 - _888);\n        vec2 _969 = vec2(dot(_876, _764), dot(_883, _764));\n        vec2 _979 = vec2(dot(_876, _767), dot(_883, _767));\n        int param_8 = _843 + 5;\n        vec4 _984 = fa_light_texel(param_8);\n        int param_9 = _843 + 3;\n        vec4 _989 = fa_light_texel(param_9);\n        int param_10 = _843 + 4;\n        vec4 _994 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _984.xyz;\n        bool _1004 = _989.z > _989.x;\n        if (_1004)\n        {\n            vec4 param_11 = _989;\n            vec2 param_12 = _959;\n            vec2 param_13 = _792;\n            vec2 param_14 = _969;\n            vec2 param_15 = _979;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_802 > 0.5) && (_802 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1030 = fa_dc_to_linear(param_16);\n                vec4 _3884 = tx;\n                _3884.x = _1030.x;\n                _3884.y = _1030.y;\n                _3884.z = _1030.z;\n                tx = _3884;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_951 * tex_a) * _984.w, 0.0, 1.0)));\n        if (_994.z > _994.x)\n        {\n            vec4 param_17 = _994;\n            vec2 param_18 = _959;\n            vec2 param_19 = _792;\n            vec2 param_20 = _969;\n            vec2 param_21 = _979;\n            vec4 _1074 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_802 > 1.5)\n            {\n                vec3 param_22 = _1074.xyz;\n                vec3 _1084 = fa_dc_to_srgb(param_22);\n                _1078 = _1084;\n            }\n            else\n            {\n                _1078 = _1074.xyz;\n            }\n            vec3 _1094 = (_1078 * 2.0) - vec3(1.0);\n            vec2 _1099 = _1094.xy * _848.y;\n            vec3 _1121 = (normalize(_876) * _1099.x) + (normalize(_883) * _1099.y);\n            vec3 _1124 = normalize(normal);\n            normal = normalize(mix(_1124, normalize((_1124 * max(_1094.z, 0.0500000007450580596923828125)) + (_1121 - (_1124 * dot(_1124, _1121)))), vec3(clamp(_951 * (_1004 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2341 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2341;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _341 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _347 = fa_light_texel(param_1);\n    float _350 = _347.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _356 = _350 < 0.5;\n    vec3 l;\n    if (_356)\n    {\n        l = normalize(_341.xyz);\n    }\n    else\n    {\n        vec3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / vec3(max(_370, 9.9999997473787516355514526367188e-05));\n        float _385 = _370 / max(_341.w, 0.001000000047497451305389404296875);\n        float _391 = clamp(1.0 - (_385 * _385), 0.0, 1.0);\n        atten = _391 * _391;\n        if (_350 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _405 = fa_light_texel(param_2);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _421 = fa_light_texel(param_3);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5)\n            {\n                cos_inner = mix(_415, 1.0, 0.25);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, normalize(_405.xyz)));\n        }\n    }\n    int _452;\n    if (_356)\n    {\n        _452 = 0;\n    }\n    else\n    {\n        _452 = (_350 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _347.xyz * atten, atten, 1.0, dist, _452);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1196;\n    if (i == 0)\n    {\n        _1196 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1212;\n        if (i == 1)\n        {\n            _1212 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1220;\n            if (i == 2)\n            {\n                _1220 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1220 = fa_shadows[24].w;\n            }\n            _1212 = _1220;\n        }\n        _1196 = _1212;\n    }\n    return _1196;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1253 = fa_shadow_depth(param, param_1);\n    float _1257;\n    if (conv.x < 0.5)\n    {\n        _1257 = _1253;\n    }\n    else\n    {\n        _1257 = (conv.y * conv.z) / (conv.z - (_1253 * (conv.z - conv.y)));\n    }\n    return _1257;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1184 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1184), sin(_1184)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1303 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1317 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1303;\n            vec2 _1336 = fa_shadow_vogel(param_3, param_4, param_5) * _1317;\n            vec2 param_6 = uv + (_1336 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1348 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1348 < (zr - (length(_1336) * plane)))\n            {\n                sum += _1348;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1392 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1392; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1392;\n        float param_11 = _1303;\n        vec2 _1411 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1411 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1411) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1392);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1453 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1458 = clamp(dot(n, l), 0.0, 1.0);\n    float _1464 = sqrt(1.0 - (_1458 * _1458));\n    float _1471 = min(_1464 / max(_1458, 0.20000000298023223876953125), 4.0);\n    float _1476;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1476 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1476 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1501 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1476 * _1464)), 1.0);\n    float _1508 = _1501.x;\n    bool _1511 = _1508 < fa_shadows[ci * 1 + 16].x;\n    bool _1520;\n    if (!_1511)\n    {\n        _1520 = _1508 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1520 = _1511;\n    }\n    bool _1529;\n    if (!_1520)\n    {\n        _1529 = _1501.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1529 = _1520;\n    }\n    bool _1538;\n    if (!_1529)\n    {\n        _1538 = _1501.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1538 = _1529;\n    }\n    bool _1545;\n    if (!_1538)\n    {\n        _1545 = _1501.z > 1.0;\n    }\n    else\n    {\n        _1545 = _1538;\n    }\n    if (_1545)\n    {\n        return -1.0;\n    }\n    float _1554;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1554 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1554 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1501.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1501.z - ((_1554 * (1.0 + (0.5 * _1471))) / _1453);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1453;\n    float param_5 = _1453 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1471, 3.0)) * 0.5) / _1453;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1981 = int(fa_shadows[25].x + 0.5);\n    if (_1981 < 1)\n    {\n        return 1.0;\n    }\n    float _1996 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1981 - 1;\n    if (_1996 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2008 = _1981 > 1;\n    bool _2015;\n    if (_2008)\n    {\n        _2015 = _1996 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2015 = _2008;\n    }\n    if (_2015)\n    {\n        ci = 1;\n    }\n    bool _2019 = _1981 > 2;\n    bool _2026;\n    if (_2019)\n    {\n        _2026 = _1996 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2026 = _2019;\n    }\n    if (_2026)\n    {\n        ci = 2;\n    }\n    bool _2030 = _1981 > 3;\n    bool _2037;\n    if (_2030)\n    {\n        _2037 = _1996 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2037 = _2030;\n    }\n    if (_2037)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2063 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2063;\n        if (_2063 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2088;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2088 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2088 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2107 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2088, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2118 = clamp((_1996 - (fa_shadow_split_at(param_7) - _2107)) / _2107, 0.0, 1.0);\n        if (_2118 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1981)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2139 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2139;\n                if (_2139 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2118);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1612 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1620;\n    if (!_1612)\n    {\n        _1620 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1620 = _1612;\n    }\n    if (_1620)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1633 = fa_light_texel(param);\n    float _1634 = _1633.x;\n    if (_1634 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1643 = int(_1634 + 0.5);\n    int param_1 = _1643;\n    vec4 _1647 = fa_light_texel(param_1);\n    int param_2 = _1643 + 1;\n    vec4 _1652 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1655 = _1647.y;\n    if (_1655 > 0.0)\n    {\n        float _1672 = 1.0 - smoothstep(0.75 * _1655, _1655, length(world - fa_shadows[27].xyz));\n        fade = _1672;\n        if (_1672 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1647.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1691 = world - fa_light_texel(param_3).xyz;\n        vec3 _1694 = abs(_1691);\n        float _1696 = _1694.x;\n        float _1698 = _1694.y;\n        bool _1699 = _1696 >= _1698;\n        bool _1707;\n        if (_1699)\n        {\n            _1707 = _1696 >= _1694.z;\n        }\n        else\n        {\n            _1707 = _1699;\n        }\n        int _1708;\n        if (_1707)\n        {\n            _1708 = (_1691.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1721;\n            if (_1698 >= _1694.z)\n            {\n                _1721 = (_1691.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1721 = (_1691.z > 0.0) ? 4 : 5;\n            }\n            _1708 = _1721;\n        }\n        face = _1708;\n    }\n    int _1740 = (_1643 + 2) + (face * 6);\n    int param_4 = _1740;\n    int param_5 = _1740 + 1;\n    int param_6 = _1740 + 3;\n    vec4 _1754 = fa_light_texel(param_6);\n    int param_7 = _1740 + 4;\n    vec4 _1759 = fa_light_texel(param_7);\n    int param_8 = _1740 + 5;\n    vec4 _1764 = fa_light_texel(param_8);\n    float _1776 = _1764.x * max(dot(_1754, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1781 = clamp(dot(n, l), 0.0, 1.0);\n    float _1804 = clamp(dot(n, _1754.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1827 = min(sqrt(1.0 - (_1804 * _1804)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1754, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1830 = _1652.y;\n    float _1832;\n    if (_1830 > 0.0)\n    {\n        _1832 = _1830;\n    }\n    else\n    {\n        _1832 = 1.5 * _1776;\n    }\n    vec4 _1852 = vec4(world + (n * (_1832 * sqrt(1.0 - (_1781 * _1781)))), 1.0);\n    float _1856 = dot(_1754, _1852);\n    float _1859 = _1764.y;\n    if (_1856 < _1859)\n    {\n        return 1.0;\n    }\n    vec2 _1874 = vec2(dot(fa_light_texel(param_4), _1852), dot(fa_light_texel(param_5), _1852)) / vec2(_1856);\n    float _1876 = _1874.x;\n    bool _1879 = _1876 < _1759.x;\n    bool _1888;\n    if (!_1879)\n    {\n        _1888 = _1876 > _1759.z;\n    }\n    else\n    {\n        _1888 = _1879;\n    }\n    bool _1897;\n    if (!_1888)\n    {\n        _1897 = _1874.y < _1759.y;\n    }\n    else\n    {\n        _1897 = _1888;\n    }\n    bool _1906;\n    if (!_1897)\n    {\n        _1906 = _1874.y > _1759.w;\n    }\n    else\n    {\n        _1906 = _1897;\n    }\n    if (_1906)\n    {\n        return 1.0;\n    }\n    float _1912 = _1652.x;\n    float _1914;\n    if (_1912 > 0.0)\n    {\n        _1914 = _1912;\n    }\n    else\n    {\n        _1914 = 1.5 * _1776;\n    }\n    vec2 param_10 = _1874;\n    vec4 param_11 = _1759;\n    float param_12 = _1856 - (_1914 * (1.0 + (0.5 * _1827)));\n    float param_13 = _1776;\n    float param_14 = 1.0;\n    float param_15 = _1764.z * 0.25;\n    float param_16 = (_1776 * min(_1827, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1859, _1764.z);\n    int param_18 = int(_1647.z + 0.5);\n    float param_19 = _1647.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _2421 = fa_mesh_fs_params[24].x < 0.5;\n    bool _2428;\n    if (!_2421)\n    {\n        _2428 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2428 = _2421;\n    }\n    if (_2428)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2441 = fa_light_texel(param);\n    float _2442 = _2441.y;\n    float len = _2442;\n    if (_2442 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2454 = length(world - fa_mesh_fs_params[0].xyz);\n    float _2464 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _2454);\n    if (_2464 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2470 = len;\n    float _2473 = min(_2470, 0.89999997615814208984375 * dist);\n    len = _2473;\n    float _2479 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _2454);\n    float _2484 = _2479 + (0.5 * _2473);\n    vec3 _2490 = world + (gn * _2479);\n    float _2492 = fa_shadow_noise();\n    float occ = 0.0;\n    float _2557;\n    for (int k = 0; k < 12; k++)\n    {\n        float _2508 = (float(k) + _2492) * 0.083333335816860198974609375;\n        vec3 _2516 = _2490 + (l * (_2508 * len));\n        vec4 _2522 = vec4(_2516, 1.0);\n        float _2528 = dot(fa_mesh_fs_params[28], _2522);\n        if (_2528 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _2548 = vec2(dot(fa_mesh_fs_params[26], _2522), dot(fa_mesh_fs_params[27], _2522)) / vec2(_2528);\n        float _2552 = _2548.x * 0.5;\n        float _2553 = _2552 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _2557 = (_2548.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _2557 = 0.5 - (_2548.y * 0.5);\n        }\n        bool _2573 = _2553 < 0.0;\n        bool _2580;\n        if (!_2573)\n        {\n            _2580 = _2553 >= 1.0;\n        }\n        else\n        {\n            _2580 = _2573;\n        }\n        bool _2587;\n        if (!_2580)\n        {\n            _2587 = _2557 < 0.0;\n        }\n        else\n        {\n            _2587 = _2580;\n        }\n        bool _2594;\n        if (!_2587)\n        {\n            _2594 = _2557 >= 1.0;\n        }\n        else\n        {\n            _2594 = _2587;\n        }\n        if (_2594)\n        {\n            break;\n        }\n        vec4 _2613 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_2553, _2557) * fa_mesh_fs_params[24].zw), 0);\n        if (_2613.w < 0.5)\n        {\n            continue;\n        }\n        float _2632 = (dot(fa_mesh_fs_params[29].xyz, _2516) + fa_mesh_fs_params[29].w) - _2613.x;\n        if ((_2632 > _2479) && (_2632 < _2484))\n        {\n            occ = max(occ, (1.0 - (_2508 * _2508)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_2553, 0.5 - _2552), min(_2557, 1.0 - _2557))));\n        }\n    }\n    return 1.0 - (occ * _2464);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2708 = fa_lm.z > 0.5;\n    bool _2714;\n    if (_2708)\n    {\n        int param = li;\n        _2714 = fa_light_baked(param);\n    }\n    else\n    {\n        _2714 = _2708;\n    }\n    if (_2714)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2737 = fa_light_sample(param_2, param_3);\n    vec3 _3813 = _2737.direction;\n    vec3 _3808 = _2737.color;\n    float _3815 = _2737.attenuation;\n    float _3810 = _2737.shadow;\n    float _3817 = _2737._distance;\n    int _3818 = _2737.type;\n    bool _2740 = _3818 == 0;\n    if (_2740 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3813;\n        float _2751 = fa_shadow_factor(param_4, param_5);\n        _3810 = _2751;\n        _3808 *= _2751;\n    }\n    else\n    {\n        bool _2762 = _3818 != 0;\n        bool _2768;\n        if (_2762)\n        {\n            _2768 = _3815 > 0.0;\n        }\n        else\n        {\n            _2768 = _2762;\n        }\n        if (_2768)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3813;\n            float _2780 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3810 = _2780;\n            _3808 *= _2780;\n        }\n    }\n    bool _2790 = fa_mesh_fs_params[24].x > 0.5;\n    bool _2796;\n    if (_2790)\n    {\n        _2796 = _3815 > 0.0;\n    }\n    else\n    {\n        _2796 = _2790;\n    }\n    if (_2796)\n    {\n        float _2803;\n        if (_2740)\n        {\n            _2803 = 1000000000.0;\n        }\n        else\n        {\n            _2803 = _3817;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _3813;\n        float param_14 = _2803;\n        float _2821 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _3810 *= _2821;\n        _3808 *= _2821;\n    }\n    return LightSample(_3813, _3808, _3815, _3810, _3817, _3818);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2163 = int(fa_shadows[25].x + 0.5);\n    float _2173 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2178 = _2163 > 0;\n    bool _2187;\n    if (_2178)\n    {\n        int param = _2163 - 1;\n        _2187 = _2173 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2187 = _2178;\n    }\n    if (_2187)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2194 = _2163 > 1;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2173 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2207 = _2163 > 2;\n        bool _2214;\n        if (_2207)\n        {\n            _2214 = _2173 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2214 = _2207;\n        }\n        if (_2214)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2220 = _2163 > 3;\n        bool _2227;\n        if (_2220)\n        {\n            _2227 = _2173 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2227 = _2220;\n        }\n        if (_2227)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3624 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3624 = -_3624;\n    }\n    vec3 _3210 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3624, fa_world_tangent, fa_uv, fa_vertex_color, _3210, gl_FrontFacing);\n    Surface _3218 = fa_standard_surface(param_1);\n    vec3 _3663 = _3218.albedo;\n    float _3664 = _3218.alpha;\n    vec3 _3665 = _3218.normal;\n    float _3666 = _3218.metallic;\n    float _3667 = _3218.roughness;\n    float _3668 = _3218.occlusion;\n    vec3 _3669 = _3218.emission;\n    float _3670 = _3218.clearcoat;\n    float _3671 = _3218.clearcoat_roughness;\n    vec3 _3672 = _3218.sheen_color;\n    float _3673 = _3218.sheen_roughness;\n    float _3674 = _3218.anisotropy;\n    float _3675 = _3218.anisotropy_rotation;\n    float _3676 = _3218.specular;\n    float _3677 = _3218.ior;\n    vec3 _3678 = _3218.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3624, fa_world_tangent, fa_uv, fa_vertex_color, _3210, gl_FrontFacing);\n    Surface param_3 = _3218;\n    surface(param_2, param_3);\n    _3663 = param_3.albedo;\n    _3664 = param_3.alpha;\n    _3665 = param_3.normal;\n    _3666 = param_3.metallic;\n    _3667 = param_3.roughness;\n    _3668 = param_3.occlusion;\n    _3669 = param_3.emission;\n    _3670 = param_3.clearcoat;\n    _3671 = param_3.clearcoat_roughness;\n    _3672 = param_3.sheen_color;\n    _3673 = param_3.sheen_roughness;\n    _3674 = param_3.anisotropy;\n    _3675 = param_3.anisotropy_rotation;\n    _3676 = param_3.specular;\n    _3677 = param_3.ior;\n    _3678 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3624;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3663 = param_6;\n    _3665 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3663;\n    }\n    else\n    {\n        vec3 _3256 = _3665;\n        vec3 _3257 = normalize(_3256);\n        _3665 = _3257;\n        vec3 param_8 = _3257;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _3624, fa_world_tangent, fa_uv, fa_vertex_color, _3210, gl_FrontFacing);\n        Surface param_10 = Surface(_3663, _3664, _3665, _3666, _3667, _3668, _3669, _3670, _3671, _3672, _3673, _3674, _3675, _3676, _3677, _3678);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _3276 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3276; ln++)\n        {\n            int param_12 = ln;\n            int _3289 = fa_cl_light(param_12);\n            bool _3292 = fa_lm.z > 0.5;\n            bool _3298;\n            if (_3292)\n            {\n                int param_13 = _3289;\n                _3298 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3298 = _3292;\n            }\n            if (_3298)\n            {\n                continue;\n            }\n            int param_14 = _3289;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3624;\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _3624, fa_world_tangent, fa_uv, fa_vertex_color, _3210, gl_FrontFacing);\n            Surface param_18 = Surface(_3663, _3664, _3665, _3666, _3667, _3668, _3669, _3670, _3671, _3672, _3673, _3674, _3675, _3676, _3677, _3678);\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _3325 = result;\n    vec3 _3326 = _3325 + _3669;\n    result = _3326;\n    vec3 param_20 = _3326;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3335 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3342;\n    if (!_3335)\n    {\n        _3342 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3342 = _3335;\n    }\n    if (_3342)\n    {\n        vec3 _3351 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3357 = dot(_3351, fa_mesh_fs_params[9].xyz);\n        bool _3361 = fa_mesh_fs_params[9].w > 0.5;\n        float _3362;\n        if (_3361)\n        {\n            _3362 = _3357;\n        }\n        else\n        {\n            _3362 = length(_3351);\n        }\n        float _3374 = _3362 - fa_mesh_fs_params[8].x;\n        if (_3374 > 0.0)\n        {\n            float _3383 = fa_mesh_fs_params[7].w * _3374;\n            float tau = _3383 * _3383;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3399;\n                if (_3361)\n                {\n                    _3399 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3357);\n                }\n                else\n                {\n                    _3399 = fa_mesh_fs_params[0].y;\n                }\n                float _3420 = mix(_3399, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3362, 0.0, 1.0));\n                float _3424 = fa_world_pos.y - _3420;\n                float _3429 = _3420 - fa_mesh_fs_params[8].z;\n                float _3434 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3437 = _3429 <= 0.0;\n                bool _3438 = !_3437;\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3444 = _3437;\n                }\n                float _3445;\n                if (_3444)\n                {\n                    _3445 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3445 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3429, 80.0));\n                }\n                bool _3472;\n                if (_3438)\n                {\n                    _3472 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3472 = _3437;\n                }\n                float _3473;\n                if (_3472)\n                {\n                    _3473 = fa_mesh_fs_params[8].y * _3429;\n                }\n                else\n                {\n                    _3473 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3429, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3498 = _3434 <= 0.0;\n                bool _3505;\n                if (!_3498)\n                {\n                    _3505 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3505 = _3498;\n                }\n                float _3506;\n                if (_3505)\n                {\n                    _3506 = fa_mesh_fs_params[8].y * _3434;\n                }\n                else\n                {\n                    _3506 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3434, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3533;\n                if (abs(_3424) < 0.001000000047497451305389404296875)\n                {\n                    _3533 = _3445;\n                }\n                else\n                {\n                    _3533 = (_3506 - _3473) / _3424;\n                }\n                tau += (_3374 * max(_3533, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3664);\n}\n\n",
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
            "inst_name": "_466",
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
            "inst_name": "_1206",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[30];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _471 = fa_mesh_fs_params[19].x < 0.0;\n    bool _478;\n    if (!_471)\n    {\n        _478 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _478 = _471;\n    }\n    bool _486;\n    if (!_478)\n    {\n        _486 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _486 = _478;\n    }\n    bool _493;\n    if (!_486)\n    {\n        _493 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _493 = _486;\n    }\n    bool _500;\n    if (!_493)\n    {\n        _500 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _500 = _493;\n    }\n    if (_500)\n    {\n        return vec4(0.0);\n    }\n    vec4 _510 = vec4(world_pos, 1.0);\n    float _517 = dot(fa_mesh_fs_params[16], _510);\n    if (!(_517 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _539 = vec2(dot(fa_mesh_fs_params[14], _510), dot(fa_mesh_fs_params[15], _510)) / vec2(_517);\n    int _543 = int(fa_mesh_fs_params[18].x);\n    int _547 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _547) + clamp(int(floor(((_539.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _547 - 1)) * _543)) + clamp(int(floor(((_539.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _543 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _623 = fa_cluster_texel(param);\n    return ivec2(int(_623.x), int(_623.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2681 = fa_cluster_lookup(param);\n    fa_cl_slot = _2681.x;\n    fa_cl_local = _2681.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2876 = fa_linear_to_srgb(param);\n        c = _2876;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2884 = fa_srgb_to_linear(param_1);\n            c = _2884;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _231;\n    if (i.front_facing)\n    {\n        _231 = i.world_normal;\n    }\n    else\n    {\n        _231 = -i.world_normal;\n    }\n    vec3 _255 = normalize(i.world_tangent.xyz - (_231 * dot(_231, i.world_tangent.xyz)));\n    vec3 _282 = normalize(((_255 * m.x) + ((cross(_231, _255) * i.world_tangent.w) * m.y)) + (_231 * m.z));\n    vec3 _285;\n    if (i.front_facing)\n    {\n        _285 = _282;\n    }\n    else\n    {\n        _285 = -_282;\n    }\n    return _285;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2915 = fa_tex_fix(param_2, param_3);\n    vec4 _3961 = base_t;\n    _3961.x = _2915.x;\n    _3961.y = _2915.y;\n    _3961.z = _2915.z;\n    base_t = _3961;\n    vec4 _2929 = (_3961 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3828 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2961 = fa_tex_fix(param_6, param_7);\n        vec3 _2964 = (_2961 * 2.0) - vec3(1.0);\n        vec2 _2969 = _2964.xy * fa_mesh_fs_params[6].x;\n        vec3 _3969 = _2964;\n        _3969.x = _2969.x;\n        _3969.y = _2969.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3969;\n        _3828 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2998 = fa_tex_fix(param_12, param_13);\n    vec4 _3972 = mrt;\n    _3972.x = _2998.x;\n    _3972.y = _2998.y;\n    _3972.z = _2998.z;\n    mrt = _3972;\n    vec4 _3026 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3026.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3038 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3068 = fa_tex_fix(param_20, param_21);\n    float _3833 = fa_mesh_fs_params[20].x;\n    float _3834 = fa_mesh_fs_params[20].y;\n    float _3837 = fa_mesh_fs_params[20].z;\n    float _3836 = fa_mesh_fs_params[21].w;\n    float _3839 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3833 *= _3038.y;\n            _3834 *= _3038.z;\n            _3836 *= _3026.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3837 *= mrt.x;\n            _3839 *= mrt.w;\n        }\n    }\n    return Surface(_2929.xyz, _2929.w, _3828, clamp(fa_mesh_fs_params[5].x * _2998.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2998.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3038.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3068), _3833, _3834, fa_mesh_fs_params[21].xyz, _3836, _3837, fa_mesh_fs_params[20].w, _3839, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _704 = rect.zw - rect.xy;\n    vec2 _708 = _704 * atlas;\n    vec2 _712 = ddx * _708;\n    vec2 _716 = ddy * _708;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _704), clamp(0.5 * log2(max(max(dot(_712, _712), dot(_716, _716)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _751 = fa_mesh_fs_params[10].y < 0.5;\n    bool _758;\n    if (!_751)\n    {\n        _758 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _758 = _751;\n    }\n    if (_758)\n    {\n        return;\n    }\n    vec3 _764 = dFdx(world_pos);\n    vec3 _767 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _771 = fa_cluster_texel(param);\n    int _775 = int(_771.w);\n    if (_775 < 1)\n    {\n        return;\n    }\n    int _785 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _785;\n    vec4 _789 = fa_light_texel(param_1);\n    vec2 _792 = _789.yz;\n    int _796 = int(_789.w);\n    int param_2 = _785 + 1;\n    vec4 _801 = fa_light_texel(param_2);\n    float _802 = _801.x;\n    int _808 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _812 = int(_771.z);\n    vec3 _1078;\n    for (int k = 0; k < _775; k++)\n    {\n        int _825 = _812 + k;\n        int param_3 = _796 + (_825 >> 2);\n        int _843 = (_785 + 2) + (int(fa_light_texel(param_3)[_825 & 3]) * 7);\n        int param_4 = _843 + 6;\n        vec4 _848 = fa_light_texel(param_4);\n        if (((int(_848.w + 0.5) >> _808) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _843;\n        vec4 _863 = fa_light_texel(param_5);\n        int param_6 = _843 + 1;\n        vec4 _868 = fa_light_texel(param_6);\n        int param_7 = _843 + 2;\n        vec4 _873 = fa_light_texel(param_7);\n        vec3 _876 = _863.xyz;\n        float _881 = dot(_876, world_pos) + _863.w;\n        vec3 _883 = _868.xyz;\n        float _888 = dot(_883, world_pos) + _868.w;\n        vec3 _890 = _873.xyz;\n        float _895 = dot(_890, world_pos) + _873.w;\n        bool _900 = abs(_881) > 0.5;\n        bool _908;\n        if (!_900)\n        {\n            _908 = abs(_888) > 0.5;\n        }\n        else\n        {\n            _908 = _900;\n        }\n        bool _916;\n        if (!_908)\n        {\n            _916 = abs(_895) > 0.5;\n        }\n        else\n        {\n            _916 = _908;\n        }\n        if (_916)\n        {\n            continue;\n        }\n        float _931 = clamp(dot(geo_normal, normalize(_890)) * _848.z, 0.0, 1.0);\n        if (_931 <= 0.0)\n        {\n            continue;\n        }\n        float _951 = (clamp((0.5 - abs(_895)) * 10.0, 0.0, 1.0) * _931) * _848.x;\n        vec2 _959 = vec2(_881 + 0.5, 0.5 - _888);\n        vec2 _969 = vec2(dot(_876, _764), dot(_883, _764));\n        vec2 _979 = vec2(dot(_876, _767), dot(_883, _767));\n        int param_8 = _843 + 5;\n        vec4 _984 = fa_light_texel(param_8);\n        int param_9 = _843 + 3;\n        vec4 _989 = fa_light_texel(param_9);\n        int param_10 = _843 + 4;\n        vec4 _994 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _984.xyz;\n        bool _1004 = _989.z > _989.x;\n        if (_1004)\n        {\n            vec4 param_11 = _989;\n            vec2 param_12 = _959;\n            vec2 param_13 = _792;\n            vec2 param_14 = _969;\n            vec2 param_15 = _979;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_802 > 0.5) && (_802 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1030 = fa_dc_to_linear(param_16);\n                vec4 _3884 = tx;\n                _3884.x = _1030.x;\n                _3884.y = _1030.y;\n                _3884.z = _1030.z;\n                tx = _3884;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_951 * tex_a) * _984.w, 0.0, 1.0)));\n        if (_994.z > _994.x)\n        {\n            vec4 param_17 = _994;\n            vec2 param_18 = _959;\n            vec2 param_19 = _792;\n            vec2 param_20 = _969;\n            vec2 param_21 = _979;\n            vec4 _1074 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_802 > 1.5)\n            {\n                vec3 param_22 = _1074.xyz;\n                vec3 _1084 = fa_dc_to_srgb(param_22);\n                _1078 = _1084;\n            }\n            else\n            {\n                _1078 = _1074.xyz;\n            }\n            vec3 _1094 = (_1078 * 2.0) - vec3(1.0);\n            vec2 _1099 = _1094.xy * _848.y;\n            vec3 _1121 = (normalize(_876) * _1099.x) + (normalize(_883) * _1099.y);\n            vec3 _1124 = normalize(normal);\n            normal = normalize(mix(_1124, normalize((_1124 * max(_1094.z, 0.0500000007450580596923828125)) + (_1121 - (_1124 * dot(_1124, _1121)))), vec3(clamp(_951 * (_1004 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2341 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2341;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return ambientColor;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _341 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _347 = fa_light_texel(param_1);\n    float _350 = _347.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _356 = _350 < 0.5;\n    vec3 l;\n    if (_356)\n    {\n        l = normalize(_341.xyz);\n    }\n    else\n    {\n        vec3 _368 = _341.xyz - world_pos;\n        float _370 = length(_368);\n        dist = _370;\n        l = _368 / vec3(max(_370, 9.9999997473787516355514526367188e-05));\n        float _385 = _370 / max(_341.w, 0.001000000047497451305389404296875);\n        float _391 = clamp(1.0 - (_385 * _385), 0.0, 1.0);\n        atten = _391 * _391;\n        if (_350 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _405 = fa_light_texel(param_2);\n            float _415 = _405.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _421 = fa_light_texel(param_3);\n            float _422 = _421.x;\n            float cos_inner = _422;\n            if (_422 > 1.5)\n            {\n                cos_inner = mix(_415, 1.0, 0.25);\n            }\n            atten *= smoothstep(_415, cos_inner, dot(-l, normalize(_405.xyz)));\n        }\n    }\n    int _452;\n    if (_356)\n    {\n        _452 = 0;\n    }\n    else\n    {\n        _452 = (_350 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _347.xyz * atten, atten, 1.0, dist, _452);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1196;\n    if (i == 0)\n    {\n        _1196 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1212;\n        if (i == 1)\n        {\n            _1212 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1220;\n            if (i == 2)\n            {\n                _1220 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1220 = fa_shadows[24].w;\n            }\n            _1212 = _1220;\n        }\n        _1196 = _1212;\n    }\n    return _1196;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1253 = fa_shadow_depth(param, param_1);\n    float _1257;\n    if (conv.x < 0.5)\n    {\n        _1257 = _1253;\n    }\n    else\n    {\n        _1257 = (conv.y * conv.z) / (conv.z - (_1253 * (conv.z - conv.y)));\n    }\n    return _1257;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1184 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1184), sin(_1184)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1303 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1317 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1303;\n            vec2 _1336 = fa_shadow_vogel(param_3, param_4, param_5) * _1317;\n            vec2 param_6 = uv + (_1336 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1348 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1348 < (zr - (length(_1336) * plane)))\n            {\n                sum += _1348;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1392 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1392; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1392;\n        float param_11 = _1303;\n        vec2 _1411 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1411 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1411) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1392);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1453 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1458 = clamp(dot(n, l), 0.0, 1.0);\n    float _1464 = sqrt(1.0 - (_1458 * _1458));\n    float _1471 = min(_1464 / max(_1458, 0.20000000298023223876953125), 4.0);\n    float _1476;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1476 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1476 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1501 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1476 * _1464)), 1.0);\n    float _1508 = _1501.x;\n    bool _1511 = _1508 < fa_shadows[ci * 1 + 16].x;\n    bool _1520;\n    if (!_1511)\n    {\n        _1520 = _1508 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1520 = _1511;\n    }\n    bool _1529;\n    if (!_1520)\n    {\n        _1529 = _1501.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1529 = _1520;\n    }\n    bool _1538;\n    if (!_1529)\n    {\n        _1538 = _1501.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1538 = _1529;\n    }\n    bool _1545;\n    if (!_1538)\n    {\n        _1545 = _1501.z > 1.0;\n    }\n    else\n    {\n        _1545 = _1538;\n    }\n    if (_1545)\n    {\n        return -1.0;\n    }\n    float _1554;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1554 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1554 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1501.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1501.z - ((_1554 * (1.0 + (0.5 * _1471))) / _1453);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1453;\n    float param_5 = _1453 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1471, 3.0)) * 0.5) / _1453;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1981 = int(fa_shadows[25].x + 0.5);\n    if (_1981 < 1)\n    {\n        return 1.0;\n    }\n    float _1996 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1981 - 1;\n    if (_1996 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2008 = _1981 > 1;\n    bool _2015;\n    if (_2008)\n    {\n        _2015 = _1996 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2015 = _2008;\n    }\n    if (_2015)\n    {\n        ci = 1;\n    }\n    bool _2019 = _1981 > 2;\n    bool _2026;\n    if (_2019)\n    {\n        _2026 = _1996 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2026 = _2019;\n    }\n    if (_2026)\n    {\n        ci = 2;\n    }\n    bool _2030 = _1981 > 3;\n    bool _2037;\n    if (_2030)\n    {\n        _2037 = _1996 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2037 = _2030;\n    }\n    if (_2037)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2063 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2063;\n        if (_2063 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2088;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2088 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2088 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2107 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2088, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2118 = clamp((_1996 - (fa_shadow_split_at(param_7) - _2107)) / _2107, 0.0, 1.0);\n        if (_2118 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1981)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2139 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2139;\n                if (_2139 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2118);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1612 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1620;\n    if (!_1612)\n    {\n        _1620 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1620 = _1612;\n    }\n    if (_1620)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1633 = fa_light_texel(param);\n    float _1634 = _1633.x;\n    if (_1634 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1643 = int(_1634 + 0.5);\n    int param_1 = _1643;\n    vec4 _1647 = fa_light_texel(param_1);\n    int param_2 = _1643 + 1;\n    vec4 _1652 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1655 = _1647.y;\n    if (_1655 > 0.0)\n    {\n        float _1672 = 1.0 - smoothstep(0.75 * _1655, _1655, length(world - fa_shadows[27].xyz));\n        fade = _1672;\n        if (_1672 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1647.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1691 = world - fa_light_texel(param_3).xyz;\n        vec3 _1694 = abs(_1691);\n        float _1696 = _1694.x;\n        float _1698 = _1694.y;\n        bool _1699 = _1696 >= _1698;\n        bool _1707;\n        if (_1699)\n        {\n            _1707 = _1696 >= _1694.z;\n        }\n        else\n        {\n            _1707 = _1699;\n        }\n        int _1708;\n        if (_1707)\n        {\n            _1708 = (_1691.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1721;\n            if (_1698 >= _1694.z)\n            {\n                _1721 = (_1691.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1721 = (_1691.z > 0.0) ? 4 : 5;\n            }\n            _1708 = _1721;\n        }\n        face = _1708;\n    }\n    int _1740 = (_1643 + 2) + (face * 6);\n    int param_4 = _1740;\n    int param_5 = _1740 + 1;\n    int param_6 = _1740 + 3;\n    vec4 _1754 = fa_light_texel(param_6);\n    int param_7 = _1740 + 4;\n    vec4 _1759 = fa_light_texel(param_7);\n    int param_8 = _1740 + 5;\n    vec4 _1764 = fa_light_texel(param_8);\n    float _1776 = _1764.x * max(dot(_1754, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1781 = clamp(dot(n, l), 0.0, 1.0);\n    float _1804 = clamp(dot(n, _1754.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1827 = min(sqrt(1.0 - (_1804 * _1804)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1754, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1830 = _1652.y;\n    float _1832;\n    if (_1830 > 0.0)\n    {\n        _1832 = _1830;\n    }\n    else\n    {\n        _1832 = 1.5 * _1776;\n    }\n    vec4 _1852 = vec4(world + (n * (_1832 * sqrt(1.0 - (_1781 * _1781)))), 1.0);\n    float _1856 = dot(_1754, _1852);\n    float _1859 = _1764.y;\n    if (_1856 < _1859)\n    {\n        return 1.0;\n    }\n    vec2 _1874 = vec2(dot(fa_light_texel(param_4), _1852), dot(fa_light_texel(param_5), _1852)) / vec2(_1856);\n    float _1876 = _1874.x;\n    bool _1879 = _1876 < _1759.x;\n    bool _1888;\n    if (!_1879)\n    {\n        _1888 = _1876 > _1759.z;\n    }\n    else\n    {\n        _1888 = _1879;\n    }\n    bool _1897;\n    if (!_1888)\n    {\n        _1897 = _1874.y < _1759.y;\n    }\n    else\n    {\n        _1897 = _1888;\n    }\n    bool _1906;\n    if (!_1897)\n    {\n        _1906 = _1874.y > _1759.w;\n    }\n    else\n    {\n        _1906 = _1897;\n    }\n    if (_1906)\n    {\n        return 1.0;\n    }\n    float _1912 = _1652.x;\n    float _1914;\n    if (_1912 > 0.0)\n    {\n        _1914 = _1912;\n    }\n    else\n    {\n        _1914 = 1.5 * _1776;\n    }\n    vec2 param_10 = _1874;\n    vec4 param_11 = _1759;\n    float param_12 = _1856 - (_1914 * (1.0 + (0.5 * _1827)));\n    float param_13 = _1776;\n    float param_14 = 1.0;\n    float param_15 = _1764.z * 0.25;\n    float param_16 = (_1776 * min(_1827, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1859, _1764.z);\n    int param_18 = int(_1647.z + 0.5);\n    float param_19 = _1647.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _2421 = fa_mesh_fs_params[24].x < 0.5;\n    bool _2428;\n    if (!_2421)\n    {\n        _2428 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2428 = _2421;\n    }\n    if (_2428)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2441 = fa_light_texel(param);\n    float _2442 = _2441.y;\n    float len = _2442;\n    if (_2442 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2454 = length(world - fa_mesh_fs_params[0].xyz);\n    float _2464 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _2454);\n    if (_2464 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _2470 = len;\n    float _2473 = min(_2470, 0.89999997615814208984375 * dist);\n    len = _2473;\n    float _2479 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _2454);\n    float _2484 = _2479 + (0.5 * _2473);\n    vec3 _2490 = world + (gn * _2479);\n    float _2492 = fa_shadow_noise();\n    float occ = 0.0;\n    float _2557;\n    for (int k = 0; k < 12; k++)\n    {\n        float _2508 = (float(k) + _2492) * 0.083333335816860198974609375;\n        vec3 _2516 = _2490 + (l * (_2508 * len));\n        vec4 _2522 = vec4(_2516, 1.0);\n        float _2528 = dot(fa_mesh_fs_params[28], _2522);\n        if (_2528 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _2548 = vec2(dot(fa_mesh_fs_params[26], _2522), dot(fa_mesh_fs_params[27], _2522)) / vec2(_2528);\n        float _2552 = _2548.x * 0.5;\n        float _2553 = _2552 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _2557 = (_2548.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _2557 = 0.5 - (_2548.y * 0.5);\n        }\n        bool _2573 = _2553 < 0.0;\n        bool _2580;\n        if (!_2573)\n        {\n            _2580 = _2553 >= 1.0;\n        }\n        else\n        {\n            _2580 = _2573;\n        }\n        bool _2587;\n        if (!_2580)\n        {\n            _2587 = _2557 < 0.0;\n        }\n        else\n        {\n            _2587 = _2580;\n        }\n        bool _2594;\n        if (!_2587)\n        {\n            _2594 = _2557 >= 1.0;\n        }\n        else\n        {\n            _2594 = _2587;\n        }\n        if (_2594)\n        {\n            break;\n        }\n        vec4 _2613 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_2553, _2557) * fa_mesh_fs_params[24].zw), 0);\n        if (_2613.w < 0.5)\n        {\n            continue;\n        }\n        float _2632 = (dot(fa_mesh_fs_params[29].xyz, _2516) + fa_mesh_fs_params[29].w) - _2613.x;\n        if ((_2632 > _2479) && (_2632 < _2484))\n        {\n            occ = max(occ, (1.0 - (_2508 * _2508)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_2553, 0.5 - _2552), min(_2557, 1.0 - _2557))));\n        }\n    }\n    return 1.0 - (occ * _2464);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2708 = fa_lm.z > 0.5;\n    bool _2714;\n    if (_2708)\n    {\n        int param = li;\n        _2714 = fa_light_baked(param);\n    }\n    else\n    {\n        _2714 = _2708;\n    }\n    if (_2714)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2737 = fa_light_sample(param_2, param_3);\n    vec3 _3813 = _2737.direction;\n    vec3 _3808 = _2737.color;\n    float _3815 = _2737.attenuation;\n    float _3810 = _2737.shadow;\n    float _3817 = _2737._distance;\n    int _3818 = _2737.type;\n    bool _2740 = _3818 == 0;\n    if (_2740 && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3813;\n        float _2751 = fa_shadow_factor(param_4, param_5);\n        _3810 = _2751;\n        _3808 *= _2751;\n    }\n    else\n    {\n        bool _2762 = _3818 != 0;\n        bool _2768;\n        if (_2762)\n        {\n            _2768 = _3815 > 0.0;\n        }\n        else\n        {\n            _2768 = _2762;\n        }\n        if (_2768)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3813;\n            float _2780 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3810 = _2780;\n            _3808 *= _2780;\n        }\n    }\n    bool _2790 = fa_mesh_fs_params[24].x > 0.5;\n    bool _2796;\n    if (_2790)\n    {\n        _2796 = _3815 > 0.0;\n    }\n    else\n    {\n        _2796 = _2790;\n    }\n    if (_2796)\n    {\n        float _2803;\n        if (_2740)\n        {\n            _2803 = 1000000000.0;\n        }\n        else\n        {\n            _2803 = _3817;\n        }\n        int param_10 = li;\n        vec3 param_11 = world_pos;\n        vec3 param_12 = gn;\n        vec3 param_13 = _3813;\n        float param_14 = _2803;\n        float _2821 = fa_contact_shadow(param_10, param_11, param_12, param_13, param_14);\n        _3810 *= _2821;\n        _3808 *= _2821;\n    }\n    return LightSample(_3813, _3808, _3815, _3810, _3817, _3818);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2163 = int(fa_shadows[25].x + 0.5);\n    float _2173 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2178 = _2163 > 0;\n    bool _2187;\n    if (_2178)\n    {\n        int param = _2163 - 1;\n        _2187 = _2173 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2187 = _2178;\n    }\n    if (_2187)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2194 = _2163 > 1;\n        bool _2201;\n        if (_2194)\n        {\n            _2201 = _2173 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2201 = _2194;\n        }\n        if (_2201)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2207 = _2163 > 2;\n        bool _2214;\n        if (_2207)\n        {\n            _2214 = _2173 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2214 = _2207;\n        }\n        if (_2214)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2220 = _2163 > 3;\n        bool _2227;\n        if (_2220)\n        {\n            _2227 = _2173 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2227 = _2220;\n        }\n        if (_2227)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3624 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3624 = -_3624;\n    }\n    vec3 _3210 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3624, fa_world_tangent, fa_uv, fa_vertex_color, _3210, gl_FrontFacing);\n    Surface _3218 = fa_standard_surface(param_1);\n    vec3 _3663 = _3218.albedo;\n    float _3664 = _3218.alpha;\n    vec3 _3665 = _3218.normal;\n    float _3666 = _3218.metallic;\n    float _3667 = _3218.roughness;\n    float _3668 = _3218.occlusion;\n    vec3 _3669 = _3218.emission;\n    float _3670 = _3218.clearcoat;\n    float _3671 = _3218.clearcoat_roughness;\n    vec3 _3672 = _3218.sheen_color;\n    float _3673 = _3218.sheen_roughness;\n    float _3674 = _3218.anisotropy;\n    float _3675 = _3218.anisotropy_rotation;\n    float _3676 = _3218.specular;\n    float _3677 = _3218.ior;\n    vec3 _3678 = _3218.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3624, fa_world_tangent, fa_uv, fa_vertex_color, _3210, gl_FrontFacing);\n    Surface param_3 = _3218;\n    surface(param_2, param_3);\n    _3663 = param_3.albedo;\n    _3664 = param_3.alpha;\n    _3665 = param_3.normal;\n    _3666 = param_3.metallic;\n    _3667 = param_3.roughness;\n    _3668 = param_3.occlusion;\n    _3669 = param_3.emission;\n    _3670 = param_3.clearcoat;\n    _3671 = param_3.clearcoat_roughness;\n    _3672 = param_3.sheen_color;\n    _3673 = param_3.sheen_roughness;\n    _3674 = param_3.anisotropy;\n    _3675 = param_3.anisotropy_rotation;\n    _3676 = param_3.specular;\n    _3677 = param_3.ior;\n    _3678 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3624;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3663 = param_6;\n    _3665 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3663;\n    }\n    else\n    {\n        vec3 _3256 = _3665;\n        vec3 _3257 = normalize(_3256);\n        _3665 = _3257;\n        vec3 param_8 = _3257;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _3624, fa_world_tangent, fa_uv, fa_vertex_color, _3210, gl_FrontFacing);\n        Surface param_10 = Surface(_3663, _3664, _3665, _3666, _3667, _3668, _3669, _3670, _3671, _3672, _3673, _3674, _3675, _3676, _3677, _3678);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _3276 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3276; ln++)\n        {\n            int param_12 = ln;\n            int _3289 = fa_cl_light(param_12);\n            bool _3292 = fa_lm.z > 0.5;\n            bool _3298;\n            if (_3292)\n            {\n                int param_13 = _3289;\n                _3298 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3298 = _3292;\n            }\n            if (_3298)\n            {\n                continue;\n            }\n            int param_14 = _3289;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3624;\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _3624, fa_world_tangent, fa_uv, fa_vertex_color, _3210, gl_FrontFacing);\n            Surface param_18 = Surface(_3663, _3664, _3665, _3666, _3667, _3668, _3669, _3670, _3671, _3672, _3673, _3674, _3675, _3676, _3677, _3678);\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _3325 = result;\n    vec3 _3326 = _3325 + _3669;\n    result = _3326;\n    vec3 param_20 = _3326;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _3335 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3342;\n    if (!_3335)\n    {\n        _3342 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3342 = _3335;\n    }\n    if (_3342)\n    {\n        vec3 _3351 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3357 = dot(_3351, fa_mesh_fs_params[9].xyz);\n        bool _3361 = fa_mesh_fs_params[9].w > 0.5;\n        float _3362;\n        if (_3361)\n        {\n            _3362 = _3357;\n        }\n        else\n        {\n            _3362 = length(_3351);\n        }\n        float _3374 = _3362 - fa_mesh_fs_params[8].x;\n        if (_3374 > 0.0)\n        {\n            float _3383 = fa_mesh_fs_params[7].w * _3374;\n            float tau = _3383 * _3383;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3399;\n                if (_3361)\n                {\n                    _3399 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3357);\n                }\n                else\n                {\n                    _3399 = fa_mesh_fs_params[0].y;\n                }\n                float _3420 = mix(_3399, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3362, 0.0, 1.0));\n                float _3424 = fa_world_pos.y - _3420;\n                float _3429 = _3420 - fa_mesh_fs_params[8].z;\n                float _3434 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3437 = _3429 <= 0.0;\n                bool _3438 = !_3437;\n                bool _3444;\n                if (_3438)\n                {\n                    _3444 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3444 = _3437;\n                }\n                float _3445;\n                if (_3444)\n                {\n                    _3445 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3445 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3429, 80.0));\n                }\n                bool _3472;\n                if (_3438)\n                {\n                    _3472 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3472 = _3437;\n                }\n                float _3473;\n                if (_3472)\n                {\n                    _3473 = fa_mesh_fs_params[8].y * _3429;\n                }\n                else\n                {\n                    _3473 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3429, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3498 = _3434 <= 0.0;\n                bool _3505;\n                if (!_3498)\n                {\n                    _3505 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3505 = _3498;\n                }\n                float _3506;\n                if (_3505)\n                {\n                    _3506 = fa_mesh_fs_params[8].y * _3434;\n                }\n                else\n                {\n                    _3506 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3434, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3533;\n                if (abs(_3424) < 0.001000000047497451305389404296875)\n                {\n                    _3533 = _3445;\n                }\n                else\n                {\n                    _3533 = (_3506 - _3473) / _3424;\n                }\n                tau += (_3374 * max(_3533, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3664);\n}\n\n",
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
            "inst_name": "_466",
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
            "inst_name": "_1206",
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
