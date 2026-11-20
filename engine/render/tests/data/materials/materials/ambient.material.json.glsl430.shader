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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _451 = fa_mesh_fs_params[19].x < 0.0;\n    bool _458;\n    if (!_451)\n    {\n        _458 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _458 = _451;\n    }\n    bool _466;\n    if (!_458)\n    {\n        _466 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _466 = _458;\n    }\n    bool _473;\n    if (!_466)\n    {\n        _473 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _473 = _466;\n    }\n    bool _480;\n    if (!_473)\n    {\n        _480 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _480 = _473;\n    }\n    if (_480)\n    {\n        return vec4(0.0);\n    }\n    vec4 _490 = vec4(world_pos, 1.0);\n    float _497 = dot(fa_mesh_fs_params[16], _490);\n    if (!(_497 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _519 = vec2(dot(fa_mesh_fs_params[14], _490), dot(fa_mesh_fs_params[15], _490)) / vec2(_497);\n    int _523 = int(fa_mesh_fs_params[18].x);\n    int _527 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _527) + clamp(int(floor(((_519.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _527 - 1)) * _523)) + clamp(int(floor(((_519.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _523 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _603 = fa_cluster_texel(param);\n    return ivec2(int(_603.x), int(_603.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2260 = fa_cluster_lookup(param);\n    fa_cl_slot = _2260.x;\n    fa_cl_local = _2260.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2413 = fa_linear_to_srgb(param);\n        c = _2413;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2421 = fa_srgb_to_linear(param_1);\n            c = _2421;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _210;\n    if (i.front_facing)\n    {\n        _210 = i.world_normal;\n    }\n    else\n    {\n        _210 = -i.world_normal;\n    }\n    vec3 _234 = normalize(i.world_tangent.xyz - (_210 * dot(_210, i.world_tangent.xyz)));\n    vec3 _262 = normalize(((_234 * m.x) + ((cross(_210, _234) * i.world_tangent.w) * m.y)) + (_210 * m.z));\n    vec3 _265;\n    if (i.front_facing)\n    {\n        _265 = _262;\n    }\n    else\n    {\n        _265 = -_262;\n    }\n    return _265;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2452 = fa_tex_fix(param_2, param_3);\n    vec4 _3489 = base_t;\n    _3489.x = _2452.x;\n    _3489.y = _2452.y;\n    _3489.z = _2452.z;\n    base_t = _3489;\n    vec4 _2466 = (_3489 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3369 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2498 = fa_tex_fix(param_6, param_7);\n        vec3 _2501 = (_2498 * 2.0) - vec3(1.0);\n        vec2 _2506 = _2501.xy * fa_mesh_fs_params[6].x;\n        vec3 _3497 = _2501;\n        _3497.x = _2506.x;\n        _3497.y = _2506.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3497;\n        _3369 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2535 = fa_tex_fix(param_12, param_13);\n    vec4 _3500 = mrt;\n    _3500.x = _2535.x;\n    _3500.y = _2535.y;\n    _3500.z = _2535.z;\n    mrt = _3500;\n    vec4 _2563 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2563.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2575 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2605 = fa_tex_fix(param_20, param_21);\n    float _3374 = fa_mesh_fs_params[20].x;\n    float _3375 = fa_mesh_fs_params[20].y;\n    float _3378 = fa_mesh_fs_params[20].z;\n    float _3377 = fa_mesh_fs_params[21].w;\n    float _3380 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3374 *= _2575.y;\n            _3375 *= _2575.z;\n            _3377 *= _2563.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3378 *= mrt.x;\n            _3380 *= mrt.w;\n        }\n    }\n    return Surface(_2466.xyz, _2466.w, _3369, clamp(fa_mesh_fs_params[5].x * _2535.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2535.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2575.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2605), _3374, _3375, fa_mesh_fs_params[21].xyz, _3377, _3378, fa_mesh_fs_params[20].w, _3380, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _684 = rect.zw - rect.xy;\n    vec2 _688 = _684 * atlas;\n    vec2 _692 = ddx * _688;\n    vec2 _696 = ddy * _688;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _684), clamp(0.5 * log2(max(max(dot(_692, _692), dot(_696, _696)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _731 = fa_mesh_fs_params[10].y < 0.5;\n    bool _738;\n    if (!_731)\n    {\n        _738 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _738 = _731;\n    }\n    if (_738)\n    {\n        return;\n    }\n    vec3 _744 = dFdx(world_pos);\n    vec3 _747 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _751 = fa_cluster_texel(param);\n    int _755 = int(_751.w);\n    if (_755 < 1)\n    {\n        return;\n    }\n    int _765 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _765;\n    vec4 _769 = fa_light_texel(param_1);\n    vec2 _772 = _769.yz;\n    int _776 = int(_769.w);\n    int param_2 = _765 + 1;\n    vec4 _781 = fa_light_texel(param_2);\n    float _782 = _781.x;\n    int _788 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _792 = int(_751.z);\n    vec3 _1058;\n    for (int k = 0; k < _755; k++)\n    {\n        int _805 = _792 + k;\n        int param_3 = _776 + (_805 >> 2);\n        int _823 = (_765 + 2) + (int(fa_light_texel(param_3)[_805 & 3]) * 7);\n        int param_4 = _823 + 6;\n        vec4 _828 = fa_light_texel(param_4);\n        if (((int(_828.w + 0.5) >> _788) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _823;\n        vec4 _843 = fa_light_texel(param_5);\n        int param_6 = _823 + 1;\n        vec4 _848 = fa_light_texel(param_6);\n        int param_7 = _823 + 2;\n        vec4 _853 = fa_light_texel(param_7);\n        vec3 _856 = _843.xyz;\n        float _861 = dot(_856, world_pos) + _843.w;\n        vec3 _863 = _848.xyz;\n        float _868 = dot(_863, world_pos) + _848.w;\n        vec3 _870 = _853.xyz;\n        float _875 = dot(_870, world_pos) + _853.w;\n        bool _880 = abs(_861) > 0.5;\n        bool _888;\n        if (!_880)\n        {\n            _888 = abs(_868) > 0.5;\n        }\n        else\n        {\n            _888 = _880;\n        }\n        bool _896;\n        if (!_888)\n        {\n            _896 = abs(_875) > 0.5;\n        }\n        else\n        {\n            _896 = _888;\n        }\n        if (_896)\n        {\n            continue;\n        }\n        float _911 = clamp(dot(geo_normal, normalize(_870)) * _828.z, 0.0, 1.0);\n        if (_911 <= 0.0)\n        {\n            continue;\n        }\n        float _931 = (clamp((0.5 - abs(_875)) * 10.0, 0.0, 1.0) * _911) * _828.x;\n        vec2 _939 = vec2(_861 + 0.5, 0.5 - _868);\n        vec2 _949 = vec2(dot(_856, _744), dot(_863, _744));\n        vec2 _959 = vec2(dot(_856, _747), dot(_863, _747));\n        int param_8 = _823 + 5;\n        vec4 _964 = fa_light_texel(param_8);\n        int param_9 = _823 + 3;\n        vec4 _969 = fa_light_texel(param_9);\n        int param_10 = _823 + 4;\n        vec4 _974 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _964.xyz;\n        bool _984 = _969.z > _969.x;\n        if (_984)\n        {\n            vec4 param_11 = _969;\n            vec2 param_12 = _939;\n            vec2 param_13 = _772;\n            vec2 param_14 = _949;\n            vec2 param_15 = _959;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_782 > 0.5) && (_782 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1010 = fa_dc_to_linear(param_16);\n                vec4 _3425 = tx;\n                _3425.x = _1010.x;\n                _3425.y = _1010.y;\n                _3425.z = _1010.z;\n                tx = _3425;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_931 * tex_a) * _964.w, 0.0, 1.0)));\n        if (_974.z > _974.x)\n        {\n            vec4 param_17 = _974;\n            vec2 param_18 = _939;\n            vec2 param_19 = _772;\n            vec2 param_20 = _949;\n            vec2 param_21 = _959;\n            vec4 _1054 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_782 > 1.5)\n            {\n                vec3 param_22 = _1054.xyz;\n                vec3 _1064 = fa_dc_to_srgb(param_22);\n                _1058 = _1064;\n            }\n            else\n            {\n                _1058 = _1054.xyz;\n            }\n            vec3 _1074 = (_1058 * 2.0) - vec3(1.0);\n            vec2 _1079 = _1074.xy * _828.y;\n            vec3 _1101 = (normalize(_856) * _1079.x) + (normalize(_863) * _1079.y);\n            vec3 _1104 = normalize(normal);\n            normal = normalize(mix(_1104, normalize((_1104 * max(_1074.z, 0.0500000007450580596923828125)) + (_1101 - (_1104 * dot(_1104, _1101)))), vec3(clamp(_931 * (_984 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _321 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _327 = fa_light_texel(param_1);\n    float _330 = _327.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _336 = _330 < 0.5;\n    vec3 l;\n    if (_336)\n    {\n        l = normalize(_321.xyz);\n    }\n    else\n    {\n        vec3 _348 = _321.xyz - world_pos;\n        float _350 = length(_348);\n        dist = _350;\n        l = _348 / vec3(max(_350, 9.9999997473787516355514526367188e-05));\n        float _365 = _350 / max(_321.w, 0.001000000047497451305389404296875);\n        float _371 = clamp(1.0 - (_365 * _365), 0.0, 1.0);\n        atten = _371 * _371;\n        if (_330 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _385 = fa_light_texel(param_2);\n            float _395 = _385.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _401 = fa_light_texel(param_3);\n            float _402 = _401.x;\n            float cos_inner = _402;\n            if (_402 > 1.5)\n            {\n                cos_inner = mix(_395, 1.0, 0.25);\n            }\n            atten *= smoothstep(_395, cos_inner, dot(-l, normalize(_385.xyz)));\n        }\n    }\n    int _432;\n    if (_336)\n    {\n        _432 = 0;\n    }\n    else\n    {\n        _432 = (_330 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _327.xyz * atten, atten, 1.0, dist, _432);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1176;\n    if (i == 0)\n    {\n        _1176 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1192;\n        if (i == 1)\n        {\n            _1192 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1200;\n            if (i == 2)\n            {\n                _1200 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1200 = fa_shadows[24].w;\n            }\n            _1192 = _1200;\n        }\n        _1176 = _1192;\n    }\n    return _1176;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1233 = fa_shadow_depth(param, param_1);\n    float _1237;\n    if (conv.x < 0.5)\n    {\n        _1237 = _1233;\n    }\n    else\n    {\n        _1237 = (conv.y * conv.z) / (conv.z - (_1233 * (conv.z - conv.y)));\n    }\n    return _1237;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1164 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1164), sin(_1164)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1283 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1297 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1283;\n            vec2 _1316 = fa_shadow_vogel(param_3, param_4, param_5) * _1297;\n            vec2 param_6 = uv + (_1316 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1328 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1328 < (zr - (length(_1316) * plane)))\n            {\n                sum += _1328;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1372 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1372; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1372;\n        float param_11 = _1283;\n        vec2 _1391 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1391 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1391) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1372);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1433 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1438 = clamp(dot(n, l), 0.0, 1.0);\n    float _1444 = sqrt(1.0 - (_1438 * _1438));\n    float _1451 = min(_1444 / max(_1438, 0.20000000298023223876953125), 4.0);\n    float _1456;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1456 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1456 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1481 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1456 * _1444)), 1.0);\n    float _1488 = _1481.x;\n    bool _1491 = _1488 < fa_shadows[ci * 1 + 16].x;\n    bool _1500;\n    if (!_1491)\n    {\n        _1500 = _1488 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    bool _1509;\n    if (!_1500)\n    {\n        _1509 = _1481.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1509 = _1500;\n    }\n    bool _1518;\n    if (!_1509)\n    {\n        _1518 = _1481.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1518 = _1509;\n    }\n    bool _1525;\n    if (!_1518)\n    {\n        _1525 = _1481.z > 1.0;\n    }\n    else\n    {\n        _1525 = _1518;\n    }\n    if (_1525)\n    {\n        return -1.0;\n    }\n    float _1534;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1534 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1534 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1481.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1481.z - ((_1534 * (1.0 + (0.5 * _1451))) / _1433);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1433;\n    float param_5 = _1433 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1451, 3.0)) * 0.5) / _1433;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1961 = int(fa_shadows[25].x + 0.5);\n    if (_1961 < 1)\n    {\n        return 1.0;\n    }\n    float _1976 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1961 - 1;\n    if (_1976 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1988 = _1961 > 1;\n    bool _1995;\n    if (_1988)\n    {\n        _1995 = _1976 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1995 = _1988;\n    }\n    if (_1995)\n    {\n        ci = 1;\n    }\n    bool _1999 = _1961 > 2;\n    bool _2006;\n    if (_1999)\n    {\n        _2006 = _1976 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2006 = _1999;\n    }\n    if (_2006)\n    {\n        ci = 2;\n    }\n    bool _2010 = _1961 > 3;\n    bool _2017;\n    if (_2010)\n    {\n        _2017 = _1976 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2017 = _2010;\n    }\n    if (_2017)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1961)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2043 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2043;\n        if (_2043 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2068;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2068 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2068 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2087 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2068, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2098 = clamp((_1976 - (fa_shadow_split_at(param_7) - _2087)) / _2087, 0.0, 1.0);\n        if (_2098 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1961)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2119 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2119;\n                if (_2119 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2098);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1592 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1600;\n    if (!_1592)\n    {\n        _1600 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1600 = _1592;\n    }\n    if (_1600)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1613 = fa_light_texel(param);\n    float _1614 = _1613.x;\n    if (_1614 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1623 = int(_1614 + 0.5);\n    int param_1 = _1623;\n    vec4 _1627 = fa_light_texel(param_1);\n    int param_2 = _1623 + 1;\n    vec4 _1632 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1635 = _1627.y;\n    if (_1635 > 0.0)\n    {\n        float _1652 = 1.0 - smoothstep(0.75 * _1635, _1635, length(world - fa_shadows[27].xyz));\n        fade = _1652;\n        if (_1652 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1627.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1671 = world - fa_light_texel(param_3).xyz;\n        vec3 _1674 = abs(_1671);\n        float _1676 = _1674.x;\n        float _1678 = _1674.y;\n        bool _1679 = _1676 >= _1678;\n        bool _1687;\n        if (_1679)\n        {\n            _1687 = _1676 >= _1674.z;\n        }\n        else\n        {\n            _1687 = _1679;\n        }\n        int _1688;\n        if (_1687)\n        {\n            _1688 = (_1671.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1701;\n            if (_1678 >= _1674.z)\n            {\n                _1701 = (_1671.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1701 = (_1671.z > 0.0) ? 4 : 5;\n            }\n            _1688 = _1701;\n        }\n        face = _1688;\n    }\n    int _1720 = (_1623 + 2) + (face * 6);\n    int param_4 = _1720;\n    int param_5 = _1720 + 1;\n    int param_6 = _1720 + 3;\n    vec4 _1734 = fa_light_texel(param_6);\n    int param_7 = _1720 + 4;\n    vec4 _1739 = fa_light_texel(param_7);\n    int param_8 = _1720 + 5;\n    vec4 _1744 = fa_light_texel(param_8);\n    float _1756 = _1744.x * max(dot(_1734, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1761 = clamp(dot(n, l), 0.0, 1.0);\n    float _1784 = clamp(dot(n, _1734.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1807 = min(sqrt(1.0 - (_1784 * _1784)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1734, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1810 = _1632.y;\n    float _1812;\n    if (_1810 > 0.0)\n    {\n        _1812 = _1810;\n    }\n    else\n    {\n        _1812 = 1.5 * _1756;\n    }\n    vec4 _1832 = vec4(world + (n * (_1812 * sqrt(1.0 - (_1761 * _1761)))), 1.0);\n    float _1836 = dot(_1734, _1832);\n    float _1839 = _1744.y;\n    if (_1836 < _1839)\n    {\n        return 1.0;\n    }\n    vec2 _1854 = vec2(dot(fa_light_texel(param_4), _1832), dot(fa_light_texel(param_5), _1832)) / vec2(_1836);\n    float _1856 = _1854.x;\n    bool _1859 = _1856 < _1739.x;\n    bool _1868;\n    if (!_1859)\n    {\n        _1868 = _1856 > _1739.z;\n    }\n    else\n    {\n        _1868 = _1859;\n    }\n    bool _1877;\n    if (!_1868)\n    {\n        _1877 = _1854.y < _1739.y;\n    }\n    else\n    {\n        _1877 = _1868;\n    }\n    bool _1886;\n    if (!_1877)\n    {\n        _1886 = _1854.y > _1739.w;\n    }\n    else\n    {\n        _1886 = _1877;\n    }\n    if (_1886)\n    {\n        return 1.0;\n    }\n    float _1892 = _1632.x;\n    float _1894;\n    if (_1892 > 0.0)\n    {\n        _1894 = _1892;\n    }\n    else\n    {\n        _1894 = 1.5 * _1756;\n    }\n    vec2 param_10 = _1854;\n    vec4 param_11 = _1739;\n    float param_12 = _1836 - (_1894 * (1.0 + (0.5 * _1807)));\n    float param_13 = _1756;\n    float param_14 = 1.0;\n    float param_15 = _1744.z * 0.25;\n    float param_16 = (_1756 * min(_1807, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1839, _1744.z);\n    int param_18 = int(_1627.z + 0.5);\n    float param_19 = _1627.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2287 = fa_lm.z > 0.5;\n    bool _2293;\n    if (_2287)\n    {\n        int param = li;\n        _2293 = fa_light_baked(param);\n    }\n    else\n    {\n        _2293 = _2287;\n    }\n    if (_2293)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2316 = fa_light_sample(param_2, param_3);\n    vec3 _3354 = _2316.direction;\n    vec3 _3349 = _2316.color;\n    float _3356 = _2316.attenuation;\n    float _3351 = _2316.shadow;\n    int _3359 = _2316.type;\n    if ((_3359 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3354;\n        float _2330 = fa_shadow_factor(param_4, param_5);\n        _3351 = _2330;\n        _3349 *= _2330;\n    }\n    else\n    {\n        bool _2341 = _3359 != 0;\n        bool _2347;\n        if (_2341)\n        {\n            _2347 = _3356 > 0.0;\n        }\n        else\n        {\n            _2347 = _2341;\n        }\n        if (_2347)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3354;\n            float _2359 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3351 = _2359;\n            _3349 *= _2359;\n        }\n    }\n    return LightSample(_3354, _3349, _3356, _3351, _2316._distance, _3359);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2143 = int(fa_shadows[25].x + 0.5);\n    float _2153 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2158 = _2143 > 0;\n    bool _2167;\n    if (_2158)\n    {\n        int param = _2143 - 1;\n        _2167 = _2153 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2167 = _2158;\n    }\n    if (_2167)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2174 = _2143 > 1;\n        bool _2181;\n        if (_2174)\n        {\n            _2181 = _2153 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2181 = _2174;\n        }\n        if (_2181)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2187 = _2143 > 2;\n        bool _2194;\n        if (_2187)\n        {\n            _2194 = _2153 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2194 = _2187;\n        }\n        if (_2194)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2200 = _2143 > 3;\n        bool _2207;\n        if (_2200)\n        {\n            _2207 = _2153 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2207 = _2200;\n        }\n        if (_2207)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3165 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3165 = -_3165;\n    }\n    vec3 _2749 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3165, fa_world_tangent, fa_uv, fa_vertex_color, _2749, gl_FrontFacing);\n    Surface _2757 = fa_standard_surface(param_1);\n    vec3 _3204 = _2757.albedo;\n    float _3205 = _2757.alpha;\n    vec3 _3206 = _2757.normal;\n    float _3207 = _2757.metallic;\n    float _3208 = _2757.roughness;\n    float _3209 = _2757.occlusion;\n    vec3 _3210 = _2757.emission;\n    float _3211 = _2757.clearcoat;\n    float _3212 = _2757.clearcoat_roughness;\n    vec3 _3213 = _2757.sheen_color;\n    float _3214 = _2757.sheen_roughness;\n    float _3215 = _2757.anisotropy;\n    float _3216 = _2757.anisotropy_rotation;\n    float _3217 = _2757.specular;\n    float _3218 = _2757.ior;\n    vec3 _3219 = _2757.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3165, fa_world_tangent, fa_uv, fa_vertex_color, _2749, gl_FrontFacing);\n    Surface param_3 = _2757;\n    surface(param_2, param_3);\n    _3204 = param_3.albedo;\n    _3205 = param_3.alpha;\n    _3206 = param_3.normal;\n    _3207 = param_3.metallic;\n    _3208 = param_3.roughness;\n    _3209 = param_3.occlusion;\n    _3210 = param_3.emission;\n    _3211 = param_3.clearcoat;\n    _3212 = param_3.clearcoat_roughness;\n    _3213 = param_3.sheen_color;\n    _3214 = param_3.sheen_roughness;\n    _3215 = param_3.anisotropy;\n    _3216 = param_3.anisotropy_rotation;\n    _3217 = param_3.specular;\n    _3218 = param_3.ior;\n    _3219 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3165;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3204 = param_6;\n    _3206 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3204;\n    }\n    else\n    {\n        vec3 _2795 = _3206;\n        vec3 _2796 = normalize(_2795);\n        _3206 = _2796;\n        vec3 param_8 = _2796;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _3165, fa_world_tangent, fa_uv, fa_vertex_color, _2749, gl_FrontFacing);\n        Surface param_10 = Surface(_3204, _3205, _3206, _3207, _3208, _3209, _3210, _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _2815 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2815; ln++)\n        {\n            int param_12 = ln;\n            int _2828 = fa_cl_light(param_12);\n            bool _2831 = fa_lm.z > 0.5;\n            bool _2837;\n            if (_2831)\n            {\n                int param_13 = _2828;\n                _2837 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _2837 = _2831;\n            }\n            if (_2837)\n            {\n                continue;\n            }\n            int param_14 = _2828;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3165;\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _3165, fa_world_tangent, fa_uv, fa_vertex_color, _2749, gl_FrontFacing);\n            Surface param_18 = Surface(_3204, _3205, _3206, _3207, _3208, _3209, _3210, _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219);\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _2864 = result;\n    vec3 _2865 = _2864 + _3210;\n    result = _2865;\n    vec3 param_20 = _2865;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _2874 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2881;\n    if (!_2874)\n    {\n        _2881 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        vec3 _2890 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2896 = dot(_2890, fa_mesh_fs_params[9].xyz);\n        bool _2900 = fa_mesh_fs_params[9].w > 0.5;\n        float _2901;\n        if (_2900)\n        {\n            _2901 = _2896;\n        }\n        else\n        {\n            _2901 = length(_2890);\n        }\n        float _2913 = _2901 - fa_mesh_fs_params[8].x;\n        if (_2913 > 0.0)\n        {\n            float _2922 = fa_mesh_fs_params[7].w * _2913;\n            float tau = _2922 * _2922;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2938;\n                if (_2900)\n                {\n                    _2938 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2896);\n                }\n                else\n                {\n                    _2938 = fa_mesh_fs_params[0].y;\n                }\n                float _2959 = mix(_2938, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2901, 0.0, 1.0));\n                float _2963 = fa_world_pos.y - _2959;\n                float _2968 = _2959 - fa_mesh_fs_params[8].z;\n                float _2973 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2976 = _2968 <= 0.0;\n                bool _2977 = !_2976;\n                bool _2983;\n                if (_2977)\n                {\n                    _2983 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2983 = _2976;\n                }\n                float _2984;\n                if (_2983)\n                {\n                    _2984 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2984 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2968, 80.0));\n                }\n                bool _3011;\n                if (_2977)\n                {\n                    _3011 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3011 = _2976;\n                }\n                float _3012;\n                if (_3011)\n                {\n                    _3012 = fa_mesh_fs_params[8].y * _2968;\n                }\n                else\n                {\n                    _3012 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2968, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3037 = _2973 <= 0.0;\n                bool _3044;\n                if (!_3037)\n                {\n                    _3044 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3044 = _3037;\n                }\n                float _3045;\n                if (_3044)\n                {\n                    _3045 = fa_mesh_fs_params[8].y * _2973;\n                }\n                else\n                {\n                    _3045 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2973, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3072;\n                if (abs(_2963) < 0.001000000047497451305389404296875)\n                {\n                    _3072 = _2984;\n                }\n                else\n                {\n                    _3072 = (_3045 - _3012) / _2963;\n                }\n                tau += (_2913 * max(_3072, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3205);\n}\n\n",
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
            "inst_name": "_446",
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
            "inst_name": "_1186",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _451 = fa_mesh_fs_params[19].x < 0.0;\n    bool _458;\n    if (!_451)\n    {\n        _458 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _458 = _451;\n    }\n    bool _466;\n    if (!_458)\n    {\n        _466 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _466 = _458;\n    }\n    bool _473;\n    if (!_466)\n    {\n        _473 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _473 = _466;\n    }\n    bool _480;\n    if (!_473)\n    {\n        _480 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _480 = _473;\n    }\n    if (_480)\n    {\n        return vec4(0.0);\n    }\n    vec4 _490 = vec4(world_pos, 1.0);\n    float _497 = dot(fa_mesh_fs_params[16], _490);\n    if (!(_497 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _519 = vec2(dot(fa_mesh_fs_params[14], _490), dot(fa_mesh_fs_params[15], _490)) / vec2(_497);\n    int _523 = int(fa_mesh_fs_params[18].x);\n    int _527 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _527) + clamp(int(floor(((_519.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _527 - 1)) * _523)) + clamp(int(floor(((_519.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _523 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _603 = fa_cluster_texel(param);\n    return ivec2(int(_603.x), int(_603.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2260 = fa_cluster_lookup(param);\n    fa_cl_slot = _2260.x;\n    fa_cl_local = _2260.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2413 = fa_linear_to_srgb(param);\n        c = _2413;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2421 = fa_srgb_to_linear(param_1);\n            c = _2421;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _210;\n    if (i.front_facing)\n    {\n        _210 = i.world_normal;\n    }\n    else\n    {\n        _210 = -i.world_normal;\n    }\n    vec3 _234 = normalize(i.world_tangent.xyz - (_210 * dot(_210, i.world_tangent.xyz)));\n    vec3 _262 = normalize(((_234 * m.x) + ((cross(_210, _234) * i.world_tangent.w) * m.y)) + (_210 * m.z));\n    vec3 _265;\n    if (i.front_facing)\n    {\n        _265 = _262;\n    }\n    else\n    {\n        _265 = -_262;\n    }\n    return _265;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2452 = fa_tex_fix(param_2, param_3);\n    vec4 _3489 = base_t;\n    _3489.x = _2452.x;\n    _3489.y = _2452.y;\n    _3489.z = _2452.z;\n    base_t = _3489;\n    vec4 _2466 = (_3489 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3369 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2498 = fa_tex_fix(param_6, param_7);\n        vec3 _2501 = (_2498 * 2.0) - vec3(1.0);\n        vec2 _2506 = _2501.xy * fa_mesh_fs_params[6].x;\n        vec3 _3497 = _2501;\n        _3497.x = _2506.x;\n        _3497.y = _2506.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3497;\n        _3369 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2535 = fa_tex_fix(param_12, param_13);\n    vec4 _3500 = mrt;\n    _3500.x = _2535.x;\n    _3500.y = _2535.y;\n    _3500.z = _2535.z;\n    mrt = _3500;\n    vec4 _2563 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2563.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2575 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2605 = fa_tex_fix(param_20, param_21);\n    float _3374 = fa_mesh_fs_params[20].x;\n    float _3375 = fa_mesh_fs_params[20].y;\n    float _3378 = fa_mesh_fs_params[20].z;\n    float _3377 = fa_mesh_fs_params[21].w;\n    float _3380 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3374 *= _2575.y;\n            _3375 *= _2575.z;\n            _3377 *= _2563.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3378 *= mrt.x;\n            _3380 *= mrt.w;\n        }\n    }\n    return Surface(_2466.xyz, _2466.w, _3369, clamp(fa_mesh_fs_params[5].x * _2535.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2535.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2575.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2605), _3374, _3375, fa_mesh_fs_params[21].xyz, _3377, _3378, fa_mesh_fs_params[20].w, _3380, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _684 = rect.zw - rect.xy;\n    vec2 _688 = _684 * atlas;\n    vec2 _692 = ddx * _688;\n    vec2 _696 = ddy * _688;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _684), clamp(0.5 * log2(max(max(dot(_692, _692), dot(_696, _696)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _731 = fa_mesh_fs_params[10].y < 0.5;\n    bool _738;\n    if (!_731)\n    {\n        _738 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _738 = _731;\n    }\n    if (_738)\n    {\n        return;\n    }\n    vec3 _744 = dFdx(world_pos);\n    vec3 _747 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _751 = fa_cluster_texel(param);\n    int _755 = int(_751.w);\n    if (_755 < 1)\n    {\n        return;\n    }\n    int _765 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _765;\n    vec4 _769 = fa_light_texel(param_1);\n    vec2 _772 = _769.yz;\n    int _776 = int(_769.w);\n    int param_2 = _765 + 1;\n    vec4 _781 = fa_light_texel(param_2);\n    float _782 = _781.x;\n    int _788 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _792 = int(_751.z);\n    vec3 _1058;\n    for (int k = 0; k < _755; k++)\n    {\n        int _805 = _792 + k;\n        int param_3 = _776 + (_805 >> 2);\n        int _823 = (_765 + 2) + (int(fa_light_texel(param_3)[_805 & 3]) * 7);\n        int param_4 = _823 + 6;\n        vec4 _828 = fa_light_texel(param_4);\n        if (((int(_828.w + 0.5) >> _788) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _823;\n        vec4 _843 = fa_light_texel(param_5);\n        int param_6 = _823 + 1;\n        vec4 _848 = fa_light_texel(param_6);\n        int param_7 = _823 + 2;\n        vec4 _853 = fa_light_texel(param_7);\n        vec3 _856 = _843.xyz;\n        float _861 = dot(_856, world_pos) + _843.w;\n        vec3 _863 = _848.xyz;\n        float _868 = dot(_863, world_pos) + _848.w;\n        vec3 _870 = _853.xyz;\n        float _875 = dot(_870, world_pos) + _853.w;\n        bool _880 = abs(_861) > 0.5;\n        bool _888;\n        if (!_880)\n        {\n            _888 = abs(_868) > 0.5;\n        }\n        else\n        {\n            _888 = _880;\n        }\n        bool _896;\n        if (!_888)\n        {\n            _896 = abs(_875) > 0.5;\n        }\n        else\n        {\n            _896 = _888;\n        }\n        if (_896)\n        {\n            continue;\n        }\n        float _911 = clamp(dot(geo_normal, normalize(_870)) * _828.z, 0.0, 1.0);\n        if (_911 <= 0.0)\n        {\n            continue;\n        }\n        float _931 = (clamp((0.5 - abs(_875)) * 10.0, 0.0, 1.0) * _911) * _828.x;\n        vec2 _939 = vec2(_861 + 0.5, 0.5 - _868);\n        vec2 _949 = vec2(dot(_856, _744), dot(_863, _744));\n        vec2 _959 = vec2(dot(_856, _747), dot(_863, _747));\n        int param_8 = _823 + 5;\n        vec4 _964 = fa_light_texel(param_8);\n        int param_9 = _823 + 3;\n        vec4 _969 = fa_light_texel(param_9);\n        int param_10 = _823 + 4;\n        vec4 _974 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _964.xyz;\n        bool _984 = _969.z > _969.x;\n        if (_984)\n        {\n            vec4 param_11 = _969;\n            vec2 param_12 = _939;\n            vec2 param_13 = _772;\n            vec2 param_14 = _949;\n            vec2 param_15 = _959;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_782 > 0.5) && (_782 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1010 = fa_dc_to_linear(param_16);\n                vec4 _3425 = tx;\n                _3425.x = _1010.x;\n                _3425.y = _1010.y;\n                _3425.z = _1010.z;\n                tx = _3425;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_931 * tex_a) * _964.w, 0.0, 1.0)));\n        if (_974.z > _974.x)\n        {\n            vec4 param_17 = _974;\n            vec2 param_18 = _939;\n            vec2 param_19 = _772;\n            vec2 param_20 = _949;\n            vec2 param_21 = _959;\n            vec4 _1054 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_782 > 1.5)\n            {\n                vec3 param_22 = _1054.xyz;\n                vec3 _1064 = fa_dc_to_srgb(param_22);\n                _1058 = _1064;\n            }\n            else\n            {\n                _1058 = _1054.xyz;\n            }\n            vec3 _1074 = (_1058 * 2.0) - vec3(1.0);\n            vec2 _1079 = _1074.xy * _828.y;\n            vec3 _1101 = (normalize(_856) * _1079.x) + (normalize(_863) * _1079.y);\n            vec3 _1104 = normalize(normal);\n            normal = normalize(mix(_1104, normalize((_1104 * max(_1074.z, 0.0500000007450580596923828125)) + (_1101 - (_1104 * dot(_1104, _1101)))), vec3(clamp(_931 * (_984 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _321 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _327 = fa_light_texel(param_1);\n    float _330 = _327.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _336 = _330 < 0.5;\n    vec3 l;\n    if (_336)\n    {\n        l = normalize(_321.xyz);\n    }\n    else\n    {\n        vec3 _348 = _321.xyz - world_pos;\n        float _350 = length(_348);\n        dist = _350;\n        l = _348 / vec3(max(_350, 9.9999997473787516355514526367188e-05));\n        float _365 = _350 / max(_321.w, 0.001000000047497451305389404296875);\n        float _371 = clamp(1.0 - (_365 * _365), 0.0, 1.0);\n        atten = _371 * _371;\n        if (_330 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _385 = fa_light_texel(param_2);\n            float _395 = _385.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _401 = fa_light_texel(param_3);\n            float _402 = _401.x;\n            float cos_inner = _402;\n            if (_402 > 1.5)\n            {\n                cos_inner = mix(_395, 1.0, 0.25);\n            }\n            atten *= smoothstep(_395, cos_inner, dot(-l, normalize(_385.xyz)));\n        }\n    }\n    int _432;\n    if (_336)\n    {\n        _432 = 0;\n    }\n    else\n    {\n        _432 = (_330 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _327.xyz * atten, atten, 1.0, dist, _432);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1176;\n    if (i == 0)\n    {\n        _1176 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1192;\n        if (i == 1)\n        {\n            _1192 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1200;\n            if (i == 2)\n            {\n                _1200 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1200 = fa_shadows[24].w;\n            }\n            _1192 = _1200;\n        }\n        _1176 = _1192;\n    }\n    return _1176;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1233 = fa_shadow_depth(param, param_1);\n    float _1237;\n    if (conv.x < 0.5)\n    {\n        _1237 = _1233;\n    }\n    else\n    {\n        _1237 = (conv.y * conv.z) / (conv.z - (_1233 * (conv.z - conv.y)));\n    }\n    return _1237;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1164 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1164), sin(_1164)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1283 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1297 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1283;\n            vec2 _1316 = fa_shadow_vogel(param_3, param_4, param_5) * _1297;\n            vec2 param_6 = uv + (_1316 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1328 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1328 < (zr - (length(_1316) * plane)))\n            {\n                sum += _1328;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1372 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1372; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1372;\n        float param_11 = _1283;\n        vec2 _1391 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1391 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1391) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1372);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1433 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1438 = clamp(dot(n, l), 0.0, 1.0);\n    float _1444 = sqrt(1.0 - (_1438 * _1438));\n    float _1451 = min(_1444 / max(_1438, 0.20000000298023223876953125), 4.0);\n    float _1456;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1456 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1456 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1481 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1456 * _1444)), 1.0);\n    float _1488 = _1481.x;\n    bool _1491 = _1488 < fa_shadows[ci * 1 + 16].x;\n    bool _1500;\n    if (!_1491)\n    {\n        _1500 = _1488 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1500 = _1491;\n    }\n    bool _1509;\n    if (!_1500)\n    {\n        _1509 = _1481.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1509 = _1500;\n    }\n    bool _1518;\n    if (!_1509)\n    {\n        _1518 = _1481.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1518 = _1509;\n    }\n    bool _1525;\n    if (!_1518)\n    {\n        _1525 = _1481.z > 1.0;\n    }\n    else\n    {\n        _1525 = _1518;\n    }\n    if (_1525)\n    {\n        return -1.0;\n    }\n    float _1534;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1534 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1534 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1481.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1481.z - ((_1534 * (1.0 + (0.5 * _1451))) / _1433);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1433;\n    float param_5 = _1433 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1451, 3.0)) * 0.5) / _1433;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1961 = int(fa_shadows[25].x + 0.5);\n    if (_1961 < 1)\n    {\n        return 1.0;\n    }\n    float _1976 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1961 - 1;\n    if (_1976 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1988 = _1961 > 1;\n    bool _1995;\n    if (_1988)\n    {\n        _1995 = _1976 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1995 = _1988;\n    }\n    if (_1995)\n    {\n        ci = 1;\n    }\n    bool _1999 = _1961 > 2;\n    bool _2006;\n    if (_1999)\n    {\n        _2006 = _1976 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2006 = _1999;\n    }\n    if (_2006)\n    {\n        ci = 2;\n    }\n    bool _2010 = _1961 > 3;\n    bool _2017;\n    if (_2010)\n    {\n        _2017 = _1976 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2017 = _2010;\n    }\n    if (_2017)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1961)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2043 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2043;\n        if (_2043 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2068;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2068 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2068 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2087 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2068, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2098 = clamp((_1976 - (fa_shadow_split_at(param_7) - _2087)) / _2087, 0.0, 1.0);\n        if (_2098 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1961)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2119 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2119;\n                if (_2119 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2098);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1592 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1600;\n    if (!_1592)\n    {\n        _1600 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1600 = _1592;\n    }\n    if (_1600)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1613 = fa_light_texel(param);\n    float _1614 = _1613.x;\n    if (_1614 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1623 = int(_1614 + 0.5);\n    int param_1 = _1623;\n    vec4 _1627 = fa_light_texel(param_1);\n    int param_2 = _1623 + 1;\n    vec4 _1632 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1635 = _1627.y;\n    if (_1635 > 0.0)\n    {\n        float _1652 = 1.0 - smoothstep(0.75 * _1635, _1635, length(world - fa_shadows[27].xyz));\n        fade = _1652;\n        if (_1652 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1627.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1671 = world - fa_light_texel(param_3).xyz;\n        vec3 _1674 = abs(_1671);\n        float _1676 = _1674.x;\n        float _1678 = _1674.y;\n        bool _1679 = _1676 >= _1678;\n        bool _1687;\n        if (_1679)\n        {\n            _1687 = _1676 >= _1674.z;\n        }\n        else\n        {\n            _1687 = _1679;\n        }\n        int _1688;\n        if (_1687)\n        {\n            _1688 = (_1671.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1701;\n            if (_1678 >= _1674.z)\n            {\n                _1701 = (_1671.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1701 = (_1671.z > 0.0) ? 4 : 5;\n            }\n            _1688 = _1701;\n        }\n        face = _1688;\n    }\n    int _1720 = (_1623 + 2) + (face * 6);\n    int param_4 = _1720;\n    int param_5 = _1720 + 1;\n    int param_6 = _1720 + 3;\n    vec4 _1734 = fa_light_texel(param_6);\n    int param_7 = _1720 + 4;\n    vec4 _1739 = fa_light_texel(param_7);\n    int param_8 = _1720 + 5;\n    vec4 _1744 = fa_light_texel(param_8);\n    float _1756 = _1744.x * max(dot(_1734, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1761 = clamp(dot(n, l), 0.0, 1.0);\n    float _1784 = clamp(dot(n, _1734.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1807 = min(sqrt(1.0 - (_1784 * _1784)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1734, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1810 = _1632.y;\n    float _1812;\n    if (_1810 > 0.0)\n    {\n        _1812 = _1810;\n    }\n    else\n    {\n        _1812 = 1.5 * _1756;\n    }\n    vec4 _1832 = vec4(world + (n * (_1812 * sqrt(1.0 - (_1761 * _1761)))), 1.0);\n    float _1836 = dot(_1734, _1832);\n    float _1839 = _1744.y;\n    if (_1836 < _1839)\n    {\n        return 1.0;\n    }\n    vec2 _1854 = vec2(dot(fa_light_texel(param_4), _1832), dot(fa_light_texel(param_5), _1832)) / vec2(_1836);\n    float _1856 = _1854.x;\n    bool _1859 = _1856 < _1739.x;\n    bool _1868;\n    if (!_1859)\n    {\n        _1868 = _1856 > _1739.z;\n    }\n    else\n    {\n        _1868 = _1859;\n    }\n    bool _1877;\n    if (!_1868)\n    {\n        _1877 = _1854.y < _1739.y;\n    }\n    else\n    {\n        _1877 = _1868;\n    }\n    bool _1886;\n    if (!_1877)\n    {\n        _1886 = _1854.y > _1739.w;\n    }\n    else\n    {\n        _1886 = _1877;\n    }\n    if (_1886)\n    {\n        return 1.0;\n    }\n    float _1892 = _1632.x;\n    float _1894;\n    if (_1892 > 0.0)\n    {\n        _1894 = _1892;\n    }\n    else\n    {\n        _1894 = 1.5 * _1756;\n    }\n    vec2 param_10 = _1854;\n    vec4 param_11 = _1739;\n    float param_12 = _1836 - (_1894 * (1.0 + (0.5 * _1807)));\n    float param_13 = _1756;\n    float param_14 = 1.0;\n    float param_15 = _1744.z * 0.25;\n    float param_16 = (_1756 * min(_1807, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1839, _1744.z);\n    int param_18 = int(_1627.z + 0.5);\n    float param_19 = _1627.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2287 = fa_lm.z > 0.5;\n    bool _2293;\n    if (_2287)\n    {\n        int param = li;\n        _2293 = fa_light_baked(param);\n    }\n    else\n    {\n        _2293 = _2287;\n    }\n    if (_2293)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2316 = fa_light_sample(param_2, param_3);\n    vec3 _3354 = _2316.direction;\n    vec3 _3349 = _2316.color;\n    float _3356 = _2316.attenuation;\n    float _3351 = _2316.shadow;\n    int _3359 = _2316.type;\n    if ((_3359 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3354;\n        float _2330 = fa_shadow_factor(param_4, param_5);\n        _3351 = _2330;\n        _3349 *= _2330;\n    }\n    else\n    {\n        bool _2341 = _3359 != 0;\n        bool _2347;\n        if (_2341)\n        {\n            _2347 = _3356 > 0.0;\n        }\n        else\n        {\n            _2347 = _2341;\n        }\n        if (_2347)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _3354;\n            float _2359 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _3351 = _2359;\n            _3349 *= _2359;\n        }\n    }\n    return LightSample(_3354, _3349, _3356, _3351, _2316._distance, _3359);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2143 = int(fa_shadows[25].x + 0.5);\n    float _2153 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2158 = _2143 > 0;\n    bool _2167;\n    if (_2158)\n    {\n        int param = _2143 - 1;\n        _2167 = _2153 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2167 = _2158;\n    }\n    if (_2167)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2174 = _2143 > 1;\n        bool _2181;\n        if (_2174)\n        {\n            _2181 = _2153 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2181 = _2174;\n        }\n        if (_2181)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2187 = _2143 > 2;\n        bool _2194;\n        if (_2187)\n        {\n            _2194 = _2153 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2194 = _2187;\n        }\n        if (_2194)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2200 = _2143 > 3;\n        bool _2207;\n        if (_2200)\n        {\n            _2207 = _2153 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2207 = _2200;\n        }\n        if (_2207)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3165 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3165 = -_3165;\n    }\n    vec3 _2749 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3165, fa_world_tangent, fa_uv, fa_vertex_color, _2749, gl_FrontFacing);\n    Surface _2757 = fa_standard_surface(param_1);\n    vec3 _3204 = _2757.albedo;\n    float _3205 = _2757.alpha;\n    vec3 _3206 = _2757.normal;\n    float _3207 = _2757.metallic;\n    float _3208 = _2757.roughness;\n    float _3209 = _2757.occlusion;\n    vec3 _3210 = _2757.emission;\n    float _3211 = _2757.clearcoat;\n    float _3212 = _2757.clearcoat_roughness;\n    vec3 _3213 = _2757.sheen_color;\n    float _3214 = _2757.sheen_roughness;\n    float _3215 = _2757.anisotropy;\n    float _3216 = _2757.anisotropy_rotation;\n    float _3217 = _2757.specular;\n    float _3218 = _2757.ior;\n    vec3 _3219 = _2757.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3165, fa_world_tangent, fa_uv, fa_vertex_color, _2749, gl_FrontFacing);\n    Surface param_3 = _2757;\n    surface(param_2, param_3);\n    _3204 = param_3.albedo;\n    _3205 = param_3.alpha;\n    _3206 = param_3.normal;\n    _3207 = param_3.metallic;\n    _3208 = param_3.roughness;\n    _3209 = param_3.occlusion;\n    _3210 = param_3.emission;\n    _3211 = param_3.clearcoat;\n    _3212 = param_3.clearcoat_roughness;\n    _3213 = param_3.sheen_color;\n    _3214 = param_3.sheen_roughness;\n    _3215 = param_3.anisotropy;\n    _3216 = param_3.anisotropy_rotation;\n    _3217 = param_3.specular;\n    _3218 = param_3.ior;\n    _3219 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _3165;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _3204 = param_6;\n    _3206 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3204;\n    }\n    else\n    {\n        vec3 _2795 = _3206;\n        vec3 _2796 = normalize(_2795);\n        _3206 = _2796;\n        vec3 param_8 = _2796;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _3165, fa_world_tangent, fa_uv, fa_vertex_color, _2749, gl_FrontFacing);\n        Surface param_10 = Surface(_3204, _3205, _3206, _3207, _3208, _3209, _3210, _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _2815 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2815; ln++)\n        {\n            int param_12 = ln;\n            int _2828 = fa_cl_light(param_12);\n            bool _2831 = fa_lm.z > 0.5;\n            bool _2837;\n            if (_2831)\n            {\n                int param_13 = _2828;\n                _2837 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _2837 = _2831;\n            }\n            if (_2837)\n            {\n                continue;\n            }\n            int param_14 = _2828;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3165;\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _3165, fa_world_tangent, fa_uv, fa_vertex_color, _2749, gl_FrontFacing);\n            Surface param_18 = Surface(_3204, _3205, _3206, _3207, _3208, _3209, _3210, _3211, _3212, _3213, _3214, _3215, _3216, _3217, _3218, _3219);\n            LightSample param_19 = fa_light_shadowed(param_14, param_15, param_16);\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _2864 = result;\n    vec3 _2865 = _2864 + _3210;\n    result = _2865;\n    vec3 param_20 = _2865;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _2874 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2881;\n    if (!_2874)\n    {\n        _2881 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2881 = _2874;\n    }\n    if (_2881)\n    {\n        vec3 _2890 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2896 = dot(_2890, fa_mesh_fs_params[9].xyz);\n        bool _2900 = fa_mesh_fs_params[9].w > 0.5;\n        float _2901;\n        if (_2900)\n        {\n            _2901 = _2896;\n        }\n        else\n        {\n            _2901 = length(_2890);\n        }\n        float _2913 = _2901 - fa_mesh_fs_params[8].x;\n        if (_2913 > 0.0)\n        {\n            float _2922 = fa_mesh_fs_params[7].w * _2913;\n            float tau = _2922 * _2922;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2938;\n                if (_2900)\n                {\n                    _2938 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2896);\n                }\n                else\n                {\n                    _2938 = fa_mesh_fs_params[0].y;\n                }\n                float _2959 = mix(_2938, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2901, 0.0, 1.0));\n                float _2963 = fa_world_pos.y - _2959;\n                float _2968 = _2959 - fa_mesh_fs_params[8].z;\n                float _2973 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2976 = _2968 <= 0.0;\n                bool _2977 = !_2976;\n                bool _2983;\n                if (_2977)\n                {\n                    _2983 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2983 = _2976;\n                }\n                float _2984;\n                if (_2983)\n                {\n                    _2984 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2984 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2968, 80.0));\n                }\n                bool _3011;\n                if (_2977)\n                {\n                    _3011 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3011 = _2976;\n                }\n                float _3012;\n                if (_3011)\n                {\n                    _3012 = fa_mesh_fs_params[8].y * _2968;\n                }\n                else\n                {\n                    _3012 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2968, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3037 = _2973 <= 0.0;\n                bool _3044;\n                if (!_3037)\n                {\n                    _3044 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3044 = _3037;\n                }\n                float _3045;\n                if (_3044)\n                {\n                    _3045 = fa_mesh_fs_params[8].y * _2973;\n                }\n                else\n                {\n                    _3045 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2973, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3072;\n                if (abs(_2963) < 0.001000000047497451305389404296875)\n                {\n                    _3072 = _2984;\n                }\n                else\n                {\n                    _3072 = (_3045 - _3012) / _2963;\n                }\n                tau += (_2913 * max(_3072, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3205);\n}\n\n",
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
            "inst_name": "_446",
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
            "inst_name": "_1186",
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
