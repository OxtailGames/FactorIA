{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "extra",
      "binding": 0,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    },
    {
      "name": "points",
      "binding": 1,
      "stride": 32,
      "access": "read",
      "fields": [
        {
          "name": "pos",
          "type": "vec4",
          "offset": 0
        },
        {
          "name": "tint",
          "type": "vec4",
          "offset": 16
        }
      ]
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _77;\n    if (!_62)\n    {\n        _77 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _415 = fa_mesh_fs_params[19].x < 0.0;\n    bool _422;\n    if (!_415)\n    {\n        _422 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    bool _430;\n    if (!_422)\n    {\n        _430 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _430 = _422;\n    }\n    bool _437;\n    if (!_430)\n    {\n        _437 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _437 = _430;\n    }\n    bool _444;\n    if (!_437)\n    {\n        _444 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _444 = _437;\n    }\n    if (_444)\n    {\n        return vec4(0.0);\n    }\n    vec4 _454 = vec4(world_pos, 1.0);\n    float _461 = dot(fa_mesh_fs_params[16], _454);\n    if (!(_461 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _483 = vec2(dot(fa_mesh_fs_params[14], _454), dot(fa_mesh_fs_params[15], _454)) / vec2(_461);\n    int _487 = int(fa_mesh_fs_params[18].x);\n    int _491 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _491) + clamp(int(floor(((_483.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _491 - 1)) * _487)) + clamp(int(floor(((_483.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _487 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _567 = fa_cluster_texel(param);\n    return ivec2(int(_567.x), int(_567.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1965 = fa_cluster_lookup(param);\n    fa_cl_slot = _1965.x;\n    fa_cl_local = _1965.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2069 = fa_linear_to_srgb(param);\n        c = _2069;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2077 = fa_srgb_to_linear(param_1);\n            c = _2077;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _182;\n    if (i.front_facing)\n    {\n        _182 = i.world_normal;\n    }\n    else\n    {\n        _182 = -i.world_normal;\n    }\n    vec3 _206 = normalize(i.world_tangent.xyz - (_182 * dot(_182, i.world_tangent.xyz)));\n    vec3 _234 = normalize(((_206 * m.x) + ((cross(_182, _206) * i.world_tangent.w) * m.y)) + (_182 * m.z));\n    vec3 _237;\n    if (i.front_facing)\n    {\n        _237 = _234;\n    }\n    else\n    {\n        _237 = -_234;\n    }\n    return _237;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2108 = fa_tex_fix(param_2, param_3);\n    vec4 _2958 = base_t;\n    _2958.x = _2108.x;\n    _2958.y = _2108.y;\n    _2958.z = _2108.z;\n    base_t = _2958;\n    vec4 _2122 = (_2958 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2882 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2154 = fa_tex_fix(param_6, param_7);\n        vec3 _2157 = (_2154 * 2.0) - vec3(1.0);\n        vec2 _2162 = _2157.xy * fa_mesh_fs_params[6].x;\n        vec3 _2966 = _2157;\n        _2966.x = _2162.x;\n        _2966.y = _2162.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2966;\n        _2882 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2191 = fa_tex_fix(param_12, param_13);\n    vec4 _2969 = mrt;\n    _2969.x = _2191.x;\n    _2969.y = _2191.y;\n    _2969.z = _2191.z;\n    mrt = _2969;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2230 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2257 = fa_tex_fix(param_20, param_21);\n    return Surface(_2122.xyz, _2122.w, _2882, clamp(fa_mesh_fs_params[5].x * _2191.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2191.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2230.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2257));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _648 = rect.zw - rect.xy;\n    vec2 _652 = _648 * atlas;\n    vec2 _656 = ddx * _652;\n    vec2 _660 = ddy * _652;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _648), clamp(0.5 * log2(max(max(dot(_656, _656), dot(_660, _660)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _695 = dFdx(world_pos);\n    vec3 _698 = dFdy(world_pos);\n    bool _701 = fa_mesh_fs_params[10].y < 0.5;\n    bool _708;\n    if (!_701)\n    {\n        _708 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _708 = _701;\n    }\n    if (_708)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _715 = fa_cluster_texel(param);\n    int _719 = int(_715.w);\n    if (_719 < 1)\n    {\n        return;\n    }\n    int _729 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _729;\n    vec4 _733 = fa_light_texel(param_1);\n    vec2 _736 = _733.yz;\n    int _740 = int(_733.w);\n    int param_2 = _729 + 1;\n    vec4 _745 = fa_light_texel(param_2);\n    float _746 = _745.x;\n    int _752 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _756 = int(_715.z);\n    vec3 _1022;\n    for (int k = 0; k < _719; k++)\n    {\n        int _769 = _756 + k;\n        int param_3 = _740 + (_769 >> 2);\n        int _787 = (_729 + 2) + (int(fa_light_texel(param_3)[_769 & 3]) * 7);\n        int param_4 = _787 + 6;\n        vec4 _792 = fa_light_texel(param_4);\n        if (((int(_792.w + 0.5) >> _752) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _787;\n        vec4 _807 = fa_light_texel(param_5);\n        int param_6 = _787 + 1;\n        vec4 _812 = fa_light_texel(param_6);\n        int param_7 = _787 + 2;\n        vec4 _817 = fa_light_texel(param_7);\n        vec3 _820 = _807.xyz;\n        float _825 = dot(_820, world_pos) + _807.w;\n        vec3 _827 = _812.xyz;\n        float _832 = dot(_827, world_pos) + _812.w;\n        vec3 _834 = _817.xyz;\n        float _839 = dot(_834, world_pos) + _817.w;\n        bool _844 = abs(_825) > 0.5;\n        bool _852;\n        if (!_844)\n        {\n            _852 = abs(_832) > 0.5;\n        }\n        else\n        {\n            _852 = _844;\n        }\n        bool _860;\n        if (!_852)\n        {\n            _860 = abs(_839) > 0.5;\n        }\n        else\n        {\n            _860 = _852;\n        }\n        if (_860)\n        {\n            continue;\n        }\n        float _875 = clamp(dot(geo_normal, normalize(_834)) * _792.z, 0.0, 1.0);\n        if (_875 <= 0.0)\n        {\n            continue;\n        }\n        float _895 = (clamp((0.5 - abs(_839)) * 10.0, 0.0, 1.0) * _875) * _792.x;\n        vec2 _903 = vec2(_825 + 0.5, 0.5 - _832);\n        vec2 _913 = vec2(dot(_820, _695), dot(_827, _695));\n        vec2 _923 = vec2(dot(_820, _698), dot(_827, _698));\n        int param_8 = _787 + 5;\n        vec4 _928 = fa_light_texel(param_8);\n        int param_9 = _787 + 3;\n        vec4 _933 = fa_light_texel(param_9);\n        int param_10 = _787 + 4;\n        vec4 _938 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _928.xyz;\n        bool _948 = _933.z > _933.x;\n        if (_948)\n        {\n            vec4 param_11 = _933;\n            vec2 param_12 = _903;\n            vec2 param_13 = _736;\n            vec2 param_14 = _913;\n            vec2 param_15 = _923;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_746 > 0.5) && (_746 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _974 = fa_dc_to_linear(param_16);\n                vec4 _2920 = tx;\n                _2920.x = _974.x;\n                _2920.y = _974.y;\n                _2920.z = _974.z;\n                tx = _2920;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_895 * tex_a) * _928.w, 0.0, 1.0)));\n        if (_938.z > _938.x)\n        {\n            vec4 param_17 = _938;\n            vec2 param_18 = _903;\n            vec2 param_19 = _736;\n            vec2 param_20 = _913;\n            vec2 param_21 = _923;\n            vec4 _1018 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_746 > 1.5)\n            {\n                vec3 param_22 = _1018.xyz;\n                vec3 _1028 = fa_dc_to_srgb(param_22);\n                _1022 = _1028;\n            }\n            else\n            {\n                _1022 = _1018.xyz;\n            }\n            vec3 _1038 = (_1022 * 2.0) - vec3(1.0);\n            vec2 _1043 = _1038.xy * _792.y;\n            vec3 _1065 = (normalize(_820) * _1043.x) + (normalize(_827) * _1043.y);\n            vec3 _1068 = normalize(normal);\n            normal = normalize(mix(_1068, normalize((_1068 * max(_1038.z, 0.0500000007450580596923828125)) + (_1065 - (_1068 * dot(_1068, _1065)))), vec3(clamp(_895 * (_948 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _282 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _288 = fa_light_texel(param_1);\n    float _291 = _288.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _298 = _291 < 0.5;\n    vec3 l;\n    if (_298)\n    {\n        l = normalize(_282.xyz);\n    }\n    else\n    {\n        vec3 _310 = _282.xyz - world_pos;\n        float _312 = length(_310);\n        dist = _312;\n        l = _310 / vec3(max(_312, 9.9999997473787516355514526367188e-05));\n        float _327 = _312 / max(_282.w, 0.001000000047497451305389404296875);\n        float _333 = clamp(1.0 - (_327 * _327), 0.0, 1.0);\n        atten = _333 * _333;\n        if (_291 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _347 = fa_light_texel(param_2);\n            float _357 = _347.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _364 = fa_light_texel(param_3);\n            float _365 = _364.x;\n            float cos_inner = _365;\n            if (_365 > 1.5)\n            {\n                cos_inner = mix(_357, 1.0, 0.25);\n            }\n            atten *= smoothstep(_357, cos_inner, dot(-l, normalize(_347.xyz)));\n        }\n    }\n    int _396;\n    if (_298)\n    {\n        _396 = 0;\n    }\n    else\n    {\n        _396 = (_291 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _288.xyz * atten, atten, 1.0, dist, _396);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1140;\n    if (i == 0)\n    {\n        _1140 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1156;\n        if (i == 1)\n        {\n            _1156 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1164;\n            if (i == 2)\n            {\n                _1164 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1164 = fa_shadows[24].w;\n            }\n            _1156 = _1164;\n        }\n        _1140 = _1156;\n    }\n    return _1140;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1128 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1128), sin(_1128)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1202 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1207 = clamp(dot(n, l), 0.0, 1.0);\n    float _1213 = sqrt(1.0 - (_1207 * _1207));\n    float _1220 = min(_1213 / max(_1207, 0.20000000298023223876953125), 4.0);\n    float _1225;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1225 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1225 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1250 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1225 * _1213)), 1.0);\n    float _1257 = _1250.x;\n    bool _1260 = _1257 < fa_shadows[ci * 1 + 16].x;\n    bool _1269;\n    if (!_1260)\n    {\n        _1269 = _1257 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1269 = _1260;\n    }\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1250.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1250.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1294;\n    if (!_1287)\n    {\n        _1294 = _1250.z > 1.0;\n    }\n    else\n    {\n        _1294 = _1287;\n    }\n    if (_1294)\n    {\n        return -1.0;\n    }\n    float _1303;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1303 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1303 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1322 = _1250.z - ((_1303 * (1.0 + (0.5 * _1220))) / _1202);\n    float _1331 = ((fa_shadows[ci * 1 + 20].x * min(_1220, 3.0)) * 0.5) / _1202;\n    int _1340 = int(fa_shadows[25].z + 0.5);\n    if (_1340 == 1)\n    {\n        vec2 param = _1250.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1351 = fa_shadow_depth(param, param_1);\n        return float(_1322 <= _1351);\n    }\n    float _1358 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1361 = _1340 == 2;\n    if (_1361)\n    {\n        float _1375 = clamp(((fa_shadows[25].w * _1202) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1358;\n            vec2 _1394 = fa_shadow_vogel(param_2, param_3, param_4) * _1375;\n            vec2 param_5 = _1250.xy + (_1394 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1405 = fa_shadow_depth(param_5, param_6);\n            if (_1405 < (_1322 - (length(_1394) * _1331)))\n            {\n                sum += _1405;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1322 - (sum / cnt), 0.0) * _1202) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1449 = _1361 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1449; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1449;\n        float param_9 = _1358;\n        vec2 _1468 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1250.xy + (_1468 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1479 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1322 - (length(_1468) * _1331)) <= _1479);\n    }\n    return lit / float(_1449);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1509 = int(fa_shadows[25].x + 0.5);\n    if (_1509 < 1)\n    {\n        return 1.0;\n    }\n    float _1524 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1509 - 1;\n    if (_1524 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1536 = _1509 > 1;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1524 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 1;\n    }\n    bool _1547 = _1509 > 2;\n    bool _1554;\n    if (_1547)\n    {\n        _1554 = _1524 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1554 = _1547;\n    }\n    if (_1554)\n    {\n        ci = 2;\n    }\n    bool _1558 = _1509 > 3;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1524 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1509)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1591 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1591;\n        if (_1591 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1616;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1616 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1616 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1635 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1616, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1646 = clamp((_1524 - (fa_shadow_split_at(param_7) - _1635)) / _1635, 0.0, 1.0);\n        if (_1646 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1509)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1667 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1667;\n                if (_1667 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1646);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1993 = fa_light_sample(param, param_1);\n    vec3 _2867 = _1993.direction;\n    vec3 _2862 = _1993.color;\n    float _2864 = _1993.shadow;\n    int _2872 = _1993.type;\n    if ((_2872 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2867;\n        float _2007 = fa_shadow_factor(param_2, param_3);\n        _2864 = _2007;\n        _2862 *= _2007;\n    }\n    return LightSample(_2867, _2862, _1993.attenuation, _2864, _1993._distance, _2872);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1897 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1900 = _1897.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1900 * _1900, exp2((-9.27999973297119140625) * ndv)) * _1900) + _1897.y)) + _1897.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1803 = rough * rough;\n    float _1833 = 0.60000002384185791015625 * _1803;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1803)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1833, 0.0500000007450580596923828125 + _1833, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1803 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1939 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1939.x) + vec3(_1939.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1691 = int(fa_shadows[25].x + 0.5);\n    float _1701 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1706 = _1691 > 0;\n    bool _1715;\n    if (_1706)\n    {\n        int param = _1691 - 1;\n        _1715 = _1701 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1715 = _1706;\n    }\n    if (_1715)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1722 = _1691 > 1;\n        bool _1729;\n        if (_1722)\n        {\n            _1729 = _1701 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1729 = _1722;\n        }\n        if (_1729)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1735 = _1691 > 2;\n        bool _1742;\n        if (_1735)\n        {\n            _1742 = _1701 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1742 = _1735;\n        }\n        if (_1742)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1748 = _1691 > 3;\n        bool _1755;\n        if (_1748)\n        {\n            _1755 = _1701 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1755 = _1748;\n        }\n        if (_1755)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2787 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2787 = -_2787;\n    }\n    vec3 _2300 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2787, fa_world_tangent, fa_uv, fa_vertex_color, _2300, gl_FrontFacing);\n    Surface _2308 = fa_standard_surface(param_1);\n    vec3 _2810 = _2308.albedo;\n    float _2811 = _2308.alpha;\n    vec3 _2812 = _2308.normal;\n    float _2813 = _2308.metallic;\n    float _2814 = _2308.roughness;\n    float _2815 = _2308.occlusion;\n    vec3 _2816 = _2308.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2787, fa_world_tangent, fa_uv, fa_vertex_color, _2300, gl_FrontFacing);\n    Surface param_3 = _2308;\n    surface(param_2, param_3);\n    _2810 = param_3.albedo;\n    _2811 = param_3.alpha;\n    _2812 = param_3.normal;\n    _2813 = param_3.metallic;\n    _2814 = param_3.roughness;\n    _2815 = param_3.occlusion;\n    _2816 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2787;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2810 = param_6;\n    _2812 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2810;\n    }\n    else\n    {\n        vec3 _2347 = normalize(_2812);\n        float _2354 = clamp(_2813, 0.0, 1.0);\n        float _2358 = clamp(_2814, 0.0500000007450580596923828125, 1.0);\n        float _2362 = _2358 * _2358;\n        float _2366 = _2362 * _2362;\n        float _2371 = max(dot(_2347, _2300), 9.9999997473787516355514526367188e-05);\n        vec3 _2377 = _2810 * (1.0 - _2354);\n        vec3 _2385 = mix(vec3(0.039999999105930328369140625), _2810, vec3(_2354));\n        vec3 param_8 = _2347;\n        vec3 lit = (fa_ambient_light(param_8) * _2377) * _2815;\n        int _2398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2398; ln++)\n        {\n            int param_9 = ln;\n            int _2411 = fa_cl_light(param_9);\n            int param_10 = _2411;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2787;\n            LightSample _2420 = fa_light_shadowed(param_10, param_11, param_12);\n            vec3 _2845 = _2420.direction;\n            float _2428 = max(dot(_2347, _2845), 0.0);\n            vec3 _2439 = normalize(_2845 + _2300);\n            float _2444 = max(dot(_2347, _2439), 0.0);\n            float _2457 = ((_2444 * _2444) * (_2366 - 1.0)) + 1.0;\n            int param_13 = _2411;\n            lit += (((_2377 + (((_2385 + ((vec3(1.0) - _2385) * pow(1.0 - max(dot(_2300, _2439), 0.0), 5.0))) * (((_2366 / ((3.1415927410125732421875 * _2457) * _2457)) * (0.5 / max(mix((2.0 * _2428) * _2371, _2428 + _2371, _2362), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2428))) * fa_light_rgb(param_13)) * (_2428 * (_2420.attenuation * _2420.shadow)));\n        }\n        vec3 param_14 = _2347;\n        vec3 param_15 = _2300;\n        vec3 param_16 = _2385;\n        float param_17 = _2358;\n        vec3 _2526 = lit;\n        vec3 _2527 = _2526 + (fa_sky_reflection(param_14, param_15, param_16, param_17) * _2815);\n        lit = _2527;\n        result = _2527;\n    }\n    vec3 _2531 = result;\n    vec3 _2532 = _2531 + _2816;\n    result = _2532;\n    vec3 param_18 = _2532;\n    vec3 param_19 = fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19);\n    bool _2541 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2549;\n    if (!_2541)\n    {\n        _2549 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2549 = _2541;\n    }\n    if (_2549)\n    {\n        vec3 _2558 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2565 = dot(_2558, fa_mesh_fs_params[9].xyz);\n        bool _2569 = fa_mesh_fs_params[9].w > 0.5;\n        float _2570;\n        if (_2569)\n        {\n            _2570 = _2565;\n        }\n        else\n        {\n            _2570 = length(_2558);\n        }\n        float _2582 = _2570 - fa_mesh_fs_params[8].x;\n        if (_2582 > 0.0)\n        {\n            float _2591 = fa_mesh_fs_params[7].w * _2582;\n            float tau = _2591 * _2591;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2607;\n                if (_2569)\n                {\n                    _2607 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2565);\n                }\n                else\n                {\n                    _2607 = fa_mesh_fs_params[0].y;\n                }\n                float _2628 = mix(_2607, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2570, 0.0, 1.0));\n                float _2632 = fa_world_pos.y - _2628;\n                float _2637 = _2628 - fa_mesh_fs_params[8].z;\n                float _2642 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2645 = _2637 <= 0.0;\n                bool _2646 = !_2645;\n                bool _2652;\n                if (_2646)\n                {\n                    _2652 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2652 = _2645;\n                }\n                float _2653;\n                if (_2652)\n                {\n                    _2653 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2653 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2637, 80.0));\n                }\n                bool _2680;\n                if (_2646)\n                {\n                    _2680 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2680 = _2645;\n                }\n                float _2681;\n                if (_2680)\n                {\n                    _2681 = fa_mesh_fs_params[8].y * _2637;\n                }\n                else\n                {\n                    _2681 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2637, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2706 = _2642 <= 0.0;\n                bool _2713;\n                if (!_2706)\n                {\n                    _2713 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2713 = _2706;\n                }\n                float _2714;\n                if (_2713)\n                {\n                    _2714 = fa_mesh_fs_params[8].y * _2642;\n                }\n                else\n                {\n                    _2714 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2642, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2741;\n                if (abs(_2632) < 0.001000000047497451305389404296875)\n                {\n                    _2741 = _2653;\n                }\n                else\n                {\n                    _2741 = (_2714 - _2681) / _2632;\n                }\n                tau += (_2582 * max(_2741, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2811);\n}\n\n",
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
            "inst_name": "_182",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_252",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_410",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1150",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _415 = fa_mesh_fs_params[19].x < 0.0;\n    bool _422;\n    if (!_415)\n    {\n        _422 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _422 = _415;\n    }\n    bool _430;\n    if (!_422)\n    {\n        _430 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _430 = _422;\n    }\n    bool _437;\n    if (!_430)\n    {\n        _437 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _437 = _430;\n    }\n    bool _444;\n    if (!_437)\n    {\n        _444 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _444 = _437;\n    }\n    if (_444)\n    {\n        return vec4(0.0);\n    }\n    vec4 _454 = vec4(world_pos, 1.0);\n    float _461 = dot(fa_mesh_fs_params[16], _454);\n    if (!(_461 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _483 = vec2(dot(fa_mesh_fs_params[14], _454), dot(fa_mesh_fs_params[15], _454)) / vec2(_461);\n    int _487 = int(fa_mesh_fs_params[18].x);\n    int _491 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _491) + clamp(int(floor(((_483.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _491 - 1)) * _487)) + clamp(int(floor(((_483.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _487 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _567 = fa_cluster_texel(param);\n    return ivec2(int(_567.x), int(_567.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1965 = fa_cluster_lookup(param);\n    fa_cl_slot = _1965.x;\n    fa_cl_local = _1965.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2069 = fa_linear_to_srgb(param);\n        c = _2069;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2077 = fa_srgb_to_linear(param_1);\n            c = _2077;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _182;\n    if (i.front_facing)\n    {\n        _182 = i.world_normal;\n    }\n    else\n    {\n        _182 = -i.world_normal;\n    }\n    vec3 _206 = normalize(i.world_tangent.xyz - (_182 * dot(_182, i.world_tangent.xyz)));\n    vec3 _234 = normalize(((_206 * m.x) + ((cross(_182, _206) * i.world_tangent.w) * m.y)) + (_182 * m.z));\n    vec3 _237;\n    if (i.front_facing)\n    {\n        _237 = _234;\n    }\n    else\n    {\n        _237 = -_234;\n    }\n    return _237;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2108 = fa_tex_fix(param_2, param_3);\n    vec4 _2958 = base_t;\n    _2958.x = _2108.x;\n    _2958.y = _2108.y;\n    _2958.z = _2108.z;\n    base_t = _2958;\n    vec4 _2122 = (_2958 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2882 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2154 = fa_tex_fix(param_6, param_7);\n        vec3 _2157 = (_2154 * 2.0) - vec3(1.0);\n        vec2 _2162 = _2157.xy * fa_mesh_fs_params[6].x;\n        vec3 _2966 = _2157;\n        _2966.x = _2162.x;\n        _2966.y = _2162.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2966;\n        _2882 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2191 = fa_tex_fix(param_12, param_13);\n    vec4 _2969 = mrt;\n    _2969.x = _2191.x;\n    _2969.y = _2191.y;\n    _2969.z = _2191.z;\n    mrt = _2969;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2230 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2257 = fa_tex_fix(param_20, param_21);\n    return Surface(_2122.xyz, _2122.w, _2882, clamp(fa_mesh_fs_params[5].x * _2191.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2191.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2230.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2257));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _648 = rect.zw - rect.xy;\n    vec2 _652 = _648 * atlas;\n    vec2 _656 = ddx * _652;\n    vec2 _660 = ddy * _652;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _648), clamp(0.5 * log2(max(max(dot(_656, _656), dot(_660, _660)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _695 = dFdx(world_pos);\n    vec3 _698 = dFdy(world_pos);\n    bool _701 = fa_mesh_fs_params[10].y < 0.5;\n    bool _708;\n    if (!_701)\n    {\n        _708 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _708 = _701;\n    }\n    if (_708)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _715 = fa_cluster_texel(param);\n    int _719 = int(_715.w);\n    if (_719 < 1)\n    {\n        return;\n    }\n    int _729 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _729;\n    vec4 _733 = fa_light_texel(param_1);\n    vec2 _736 = _733.yz;\n    int _740 = int(_733.w);\n    int param_2 = _729 + 1;\n    vec4 _745 = fa_light_texel(param_2);\n    float _746 = _745.x;\n    int _752 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _756 = int(_715.z);\n    vec3 _1022;\n    for (int k = 0; k < _719; k++)\n    {\n        int _769 = _756 + k;\n        int param_3 = _740 + (_769 >> 2);\n        int _787 = (_729 + 2) + (int(fa_light_texel(param_3)[_769 & 3]) * 7);\n        int param_4 = _787 + 6;\n        vec4 _792 = fa_light_texel(param_4);\n        if (((int(_792.w + 0.5) >> _752) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _787;\n        vec4 _807 = fa_light_texel(param_5);\n        int param_6 = _787 + 1;\n        vec4 _812 = fa_light_texel(param_6);\n        int param_7 = _787 + 2;\n        vec4 _817 = fa_light_texel(param_7);\n        vec3 _820 = _807.xyz;\n        float _825 = dot(_820, world_pos) + _807.w;\n        vec3 _827 = _812.xyz;\n        float _832 = dot(_827, world_pos) + _812.w;\n        vec3 _834 = _817.xyz;\n        float _839 = dot(_834, world_pos) + _817.w;\n        bool _844 = abs(_825) > 0.5;\n        bool _852;\n        if (!_844)\n        {\n            _852 = abs(_832) > 0.5;\n        }\n        else\n        {\n            _852 = _844;\n        }\n        bool _860;\n        if (!_852)\n        {\n            _860 = abs(_839) > 0.5;\n        }\n        else\n        {\n            _860 = _852;\n        }\n        if (_860)\n        {\n            continue;\n        }\n        float _875 = clamp(dot(geo_normal, normalize(_834)) * _792.z, 0.0, 1.0);\n        if (_875 <= 0.0)\n        {\n            continue;\n        }\n        float _895 = (clamp((0.5 - abs(_839)) * 10.0, 0.0, 1.0) * _875) * _792.x;\n        vec2 _903 = vec2(_825 + 0.5, 0.5 - _832);\n        vec2 _913 = vec2(dot(_820, _695), dot(_827, _695));\n        vec2 _923 = vec2(dot(_820, _698), dot(_827, _698));\n        int param_8 = _787 + 5;\n        vec4 _928 = fa_light_texel(param_8);\n        int param_9 = _787 + 3;\n        vec4 _933 = fa_light_texel(param_9);\n        int param_10 = _787 + 4;\n        vec4 _938 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _928.xyz;\n        bool _948 = _933.z > _933.x;\n        if (_948)\n        {\n            vec4 param_11 = _933;\n            vec2 param_12 = _903;\n            vec2 param_13 = _736;\n            vec2 param_14 = _913;\n            vec2 param_15 = _923;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_746 > 0.5) && (_746 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _974 = fa_dc_to_linear(param_16);\n                vec4 _2920 = tx;\n                _2920.x = _974.x;\n                _2920.y = _974.y;\n                _2920.z = _974.z;\n                tx = _2920;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_895 * tex_a) * _928.w, 0.0, 1.0)));\n        if (_938.z > _938.x)\n        {\n            vec4 param_17 = _938;\n            vec2 param_18 = _903;\n            vec2 param_19 = _736;\n            vec2 param_20 = _913;\n            vec2 param_21 = _923;\n            vec4 _1018 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_746 > 1.5)\n            {\n                vec3 param_22 = _1018.xyz;\n                vec3 _1028 = fa_dc_to_srgb(param_22);\n                _1022 = _1028;\n            }\n            else\n            {\n                _1022 = _1018.xyz;\n            }\n            vec3 _1038 = (_1022 * 2.0) - vec3(1.0);\n            vec2 _1043 = _1038.xy * _792.y;\n            vec3 _1065 = (normalize(_820) * _1043.x) + (normalize(_827) * _1043.y);\n            vec3 _1068 = normalize(normal);\n            normal = normalize(mix(_1068, normalize((_1068 * max(_1038.z, 0.0500000007450580596923828125)) + (_1065 - (_1068 * dot(_1068, _1065)))), vec3(clamp(_895 * (_948 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _282 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _288 = fa_light_texel(param_1);\n    float _291 = _288.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _298 = _291 < 0.5;\n    vec3 l;\n    if (_298)\n    {\n        l = normalize(_282.xyz);\n    }\n    else\n    {\n        vec3 _310 = _282.xyz - world_pos;\n        float _312 = length(_310);\n        dist = _312;\n        l = _310 / vec3(max(_312, 9.9999997473787516355514526367188e-05));\n        float _327 = _312 / max(_282.w, 0.001000000047497451305389404296875);\n        float _333 = clamp(1.0 - (_327 * _327), 0.0, 1.0);\n        atten = _333 * _333;\n        if (_291 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _347 = fa_light_texel(param_2);\n            float _357 = _347.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _364 = fa_light_texel(param_3);\n            float _365 = _364.x;\n            float cos_inner = _365;\n            if (_365 > 1.5)\n            {\n                cos_inner = mix(_357, 1.0, 0.25);\n            }\n            atten *= smoothstep(_357, cos_inner, dot(-l, normalize(_347.xyz)));\n        }\n    }\n    int _396;\n    if (_298)\n    {\n        _396 = 0;\n    }\n    else\n    {\n        _396 = (_291 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _288.xyz * atten, atten, 1.0, dist, _396);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1140;\n    if (i == 0)\n    {\n        _1140 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1156;\n        if (i == 1)\n        {\n            _1156 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1164;\n            if (i == 2)\n            {\n                _1164 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1164 = fa_shadows[24].w;\n            }\n            _1156 = _1164;\n        }\n        _1140 = _1156;\n    }\n    return _1140;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1128 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1128), sin(_1128)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1202 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1207 = clamp(dot(n, l), 0.0, 1.0);\n    float _1213 = sqrt(1.0 - (_1207 * _1207));\n    float _1220 = min(_1213 / max(_1207, 0.20000000298023223876953125), 4.0);\n    float _1225;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1225 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1225 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1250 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1225 * _1213)), 1.0);\n    float _1257 = _1250.x;\n    bool _1260 = _1257 < fa_shadows[ci * 1 + 16].x;\n    bool _1269;\n    if (!_1260)\n    {\n        _1269 = _1257 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1269 = _1260;\n    }\n    bool _1278;\n    if (!_1269)\n    {\n        _1278 = _1250.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1278 = _1269;\n    }\n    bool _1287;\n    if (!_1278)\n    {\n        _1287 = _1250.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1287 = _1278;\n    }\n    bool _1294;\n    if (!_1287)\n    {\n        _1294 = _1250.z > 1.0;\n    }\n    else\n    {\n        _1294 = _1287;\n    }\n    if (_1294)\n    {\n        return -1.0;\n    }\n    float _1303;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1303 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1303 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1322 = _1250.z - ((_1303 * (1.0 + (0.5 * _1220))) / _1202);\n    float _1331 = ((fa_shadows[ci * 1 + 20].x * min(_1220, 3.0)) * 0.5) / _1202;\n    int _1340 = int(fa_shadows[25].z + 0.5);\n    if (_1340 == 1)\n    {\n        vec2 param = _1250.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1351 = fa_shadow_depth(param, param_1);\n        return float(_1322 <= _1351);\n    }\n    float _1358 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1361 = _1340 == 2;\n    if (_1361)\n    {\n        float _1375 = clamp(((fa_shadows[25].w * _1202) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1358;\n            vec2 _1394 = fa_shadow_vogel(param_2, param_3, param_4) * _1375;\n            vec2 param_5 = _1250.xy + (_1394 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1405 = fa_shadow_depth(param_5, param_6);\n            if (_1405 < (_1322 - (length(_1394) * _1331)))\n            {\n                sum += _1405;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1322 - (sum / cnt), 0.0) * _1202) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1449 = _1361 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1449; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1449;\n        float param_9 = _1358;\n        vec2 _1468 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1250.xy + (_1468 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1479 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1322 - (length(_1468) * _1331)) <= _1479);\n    }\n    return lit / float(_1449);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1509 = int(fa_shadows[25].x + 0.5);\n    if (_1509 < 1)\n    {\n        return 1.0;\n    }\n    float _1524 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1509 - 1;\n    if (_1524 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1536 = _1509 > 1;\n    bool _1543;\n    if (_1536)\n    {\n        _1543 = _1524 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1543 = _1536;\n    }\n    if (_1543)\n    {\n        ci = 1;\n    }\n    bool _1547 = _1509 > 2;\n    bool _1554;\n    if (_1547)\n    {\n        _1554 = _1524 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1554 = _1547;\n    }\n    if (_1554)\n    {\n        ci = 2;\n    }\n    bool _1558 = _1509 > 3;\n    bool _1565;\n    if (_1558)\n    {\n        _1565 = _1524 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1565 = _1558;\n    }\n    if (_1565)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1509)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1591 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1591;\n        if (_1591 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1616;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1616 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1616 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1635 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1616, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1646 = clamp((_1524 - (fa_shadow_split_at(param_7) - _1635)) / _1635, 0.0, 1.0);\n        if (_1646 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1509)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1667 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1667;\n                if (_1667 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1646);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1993 = fa_light_sample(param, param_1);\n    vec3 _2867 = _1993.direction;\n    vec3 _2862 = _1993.color;\n    float _2864 = _1993.shadow;\n    int _2872 = _1993.type;\n    if ((_2872 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2867;\n        float _2007 = fa_shadow_factor(param_2, param_3);\n        _2864 = _2007;\n        _2862 *= _2007;\n    }\n    return LightSample(_2867, _2862, _1993.attenuation, _2864, _1993._distance, _2872);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1897 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1900 = _1897.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1900 * _1900, exp2((-9.27999973297119140625) * ndv)) * _1900) + _1897.y)) + _1897.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1803 = rough * rough;\n    float _1833 = 0.60000002384185791015625 * _1803;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1803)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1833, 0.0500000007450580596923828125 + _1833, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1803 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1939 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1939.x) + vec3(_1939.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1691 = int(fa_shadows[25].x + 0.5);\n    float _1701 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1706 = _1691 > 0;\n    bool _1715;\n    if (_1706)\n    {\n        int param = _1691 - 1;\n        _1715 = _1701 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1715 = _1706;\n    }\n    if (_1715)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1722 = _1691 > 1;\n        bool _1729;\n        if (_1722)\n        {\n            _1729 = _1701 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1729 = _1722;\n        }\n        if (_1729)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1735 = _1691 > 2;\n        bool _1742;\n        if (_1735)\n        {\n            _1742 = _1701 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1742 = _1735;\n        }\n        if (_1742)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1748 = _1691 > 3;\n        bool _1755;\n        if (_1748)\n        {\n            _1755 = _1701 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1755 = _1748;\n        }\n        if (_1755)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2787 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2787 = -_2787;\n    }\n    vec3 _2300 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2787, fa_world_tangent, fa_uv, fa_vertex_color, _2300, gl_FrontFacing);\n    Surface _2308 = fa_standard_surface(param_1);\n    vec3 _2810 = _2308.albedo;\n    float _2811 = _2308.alpha;\n    vec3 _2812 = _2308.normal;\n    float _2813 = _2308.metallic;\n    float _2814 = _2308.roughness;\n    float _2815 = _2308.occlusion;\n    vec3 _2816 = _2308.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2787, fa_world_tangent, fa_uv, fa_vertex_color, _2300, gl_FrontFacing);\n    Surface param_3 = _2308;\n    surface(param_2, param_3);\n    _2810 = param_3.albedo;\n    _2811 = param_3.alpha;\n    _2812 = param_3.normal;\n    _2813 = param_3.metallic;\n    _2814 = param_3.roughness;\n    _2815 = param_3.occlusion;\n    _2816 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2787;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2810 = param_6;\n    _2812 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2810;\n    }\n    else\n    {\n        vec3 _2347 = normalize(_2812);\n        float _2354 = clamp(_2813, 0.0, 1.0);\n        float _2358 = clamp(_2814, 0.0500000007450580596923828125, 1.0);\n        float _2362 = _2358 * _2358;\n        float _2366 = _2362 * _2362;\n        float _2371 = max(dot(_2347, _2300), 9.9999997473787516355514526367188e-05);\n        vec3 _2377 = _2810 * (1.0 - _2354);\n        vec3 _2385 = mix(vec3(0.039999999105930328369140625), _2810, vec3(_2354));\n        vec3 param_8 = _2347;\n        vec3 lit = (fa_ambient_light(param_8) * _2377) * _2815;\n        int _2398 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2398; ln++)\n        {\n            int param_9 = ln;\n            int _2411 = fa_cl_light(param_9);\n            int param_10 = _2411;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2787;\n            LightSample _2420 = fa_light_shadowed(param_10, param_11, param_12);\n            vec3 _2845 = _2420.direction;\n            float _2428 = max(dot(_2347, _2845), 0.0);\n            vec3 _2439 = normalize(_2845 + _2300);\n            float _2444 = max(dot(_2347, _2439), 0.0);\n            float _2457 = ((_2444 * _2444) * (_2366 - 1.0)) + 1.0;\n            int param_13 = _2411;\n            lit += (((_2377 + (((_2385 + ((vec3(1.0) - _2385) * pow(1.0 - max(dot(_2300, _2439), 0.0), 5.0))) * (((_2366 / ((3.1415927410125732421875 * _2457) * _2457)) * (0.5 / max(mix((2.0 * _2428) * _2371, _2428 + _2371, _2362), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2428))) * fa_light_rgb(param_13)) * (_2428 * (_2420.attenuation * _2420.shadow)));\n        }\n        vec3 param_14 = _2347;\n        vec3 param_15 = _2300;\n        vec3 param_16 = _2385;\n        float param_17 = _2358;\n        vec3 _2526 = lit;\n        vec3 _2527 = _2526 + (fa_sky_reflection(param_14, param_15, param_16, param_17) * _2815);\n        lit = _2527;\n        result = _2527;\n    }\n    vec3 _2531 = result;\n    vec3 _2532 = _2531 + _2816;\n    result = _2532;\n    vec3 param_18 = _2532;\n    vec3 param_19 = fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19);\n    bool _2541 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2549;\n    if (!_2541)\n    {\n        _2549 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2549 = _2541;\n    }\n    if (_2549)\n    {\n        vec3 _2558 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2565 = dot(_2558, fa_mesh_fs_params[9].xyz);\n        bool _2569 = fa_mesh_fs_params[9].w > 0.5;\n        float _2570;\n        if (_2569)\n        {\n            _2570 = _2565;\n        }\n        else\n        {\n            _2570 = length(_2558);\n        }\n        float _2582 = _2570 - fa_mesh_fs_params[8].x;\n        if (_2582 > 0.0)\n        {\n            float _2591 = fa_mesh_fs_params[7].w * _2582;\n            float tau = _2591 * _2591;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2607;\n                if (_2569)\n                {\n                    _2607 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2565);\n                }\n                else\n                {\n                    _2607 = fa_mesh_fs_params[0].y;\n                }\n                float _2628 = mix(_2607, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2570, 0.0, 1.0));\n                float _2632 = fa_world_pos.y - _2628;\n                float _2637 = _2628 - fa_mesh_fs_params[8].z;\n                float _2642 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2645 = _2637 <= 0.0;\n                bool _2646 = !_2645;\n                bool _2652;\n                if (_2646)\n                {\n                    _2652 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2652 = _2645;\n                }\n                float _2653;\n                if (_2652)\n                {\n                    _2653 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2653 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2637, 80.0));\n                }\n                bool _2680;\n                if (_2646)\n                {\n                    _2680 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2680 = _2645;\n                }\n                float _2681;\n                if (_2680)\n                {\n                    _2681 = fa_mesh_fs_params[8].y * _2637;\n                }\n                else\n                {\n                    _2681 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2637, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2706 = _2642 <= 0.0;\n                bool _2713;\n                if (!_2706)\n                {\n                    _2713 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2713 = _2706;\n                }\n                float _2714;\n                if (_2713)\n                {\n                    _2714 = fa_mesh_fs_params[8].y * _2642;\n                }\n                else\n                {\n                    _2714 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2642, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2741;\n                if (abs(_2632) < 0.001000000047497451305389404296875)\n                {\n                    _2741 = _2653;\n                }\n                else\n                {\n                    _2741 = (_2714 - _2681) / _2632;\n                }\n                tau += (_2582 * max(_2741, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2811);\n}\n\n",
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
            "inst_name": "_187",
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
            "inst_name": "_231",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_364",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_410",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_1150",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
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
              "slot": 15,
              "stage": "fragment",
              "name": "fa_irr_tex",
              "multisampled": false,
              "type": "cube",
              "sample_type": "float"
            }
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _124 = cross(model[1].xyz, model[2].xyz);\n    float _128 = (dot(model[0].xyz, _124) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_124 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _128, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _128), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _62 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _77;\n    if (!_62)\n    {\n        _77 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _77 = _62;\n    }\n    if (_77)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _217 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _224 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_217 * _224).z;\n    fa_pre_r0 = vec3(_217[0].x, _217[1].x, _217[2].x);\n    fa_pre_r1 = vec3(_217[0].y, _217[1].y, _217[2].y);\n    fa_pre_r2 = vec3(_217[0].z, _217[1].z, _217[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _224;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _608 = base_t;\n    _608.x = _242.x;\n    _608.y = _242.y;\n    _608.z = _242.z;\n    base_t = _608;\n    vec4 _257 = (_608 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _589 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _616 = _294;\n        _616.x = _299.x;\n        _616.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _616;\n        _589 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _619 = mrt;\n    _619.x = _328.x;\n    _619.y = _328.y;\n    _619.z = _328.z;\n    mrt = _619;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _396 = fa_tex_fix(param_20, param_21);\n    return Surface(_257.xyz, _257.w, _589, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_369.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _396));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _536 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _536 = -_536;\n    }\n    vec3 _442 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _536, fa_world_tangent, fa_uv, fa_vertex_color, _442, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _536, fa_world_tangent, fa_uv, fa_vertex_color, _442, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _457 = normalize(param_2.normal);\n    vec3 _472 = normalize(vec3(dot(fa_pre_r0, _457), dot(fa_pre_r1, _457), dot(fa_pre_r2, _457)));\n    float _484 = _472.z;\n    vec2 e = _472.xy / vec2((abs(_472.x) + abs(_472.y)) + abs(_484));\n    if (_484 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_182",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_286",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _222 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_222 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_222 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_222 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _129 = cross(model[1].xyz, model[2].xyz);\n    float _133 = (dot(model[0].xyz, _129) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_129 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _133, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _133), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _67 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _82;\n    if (!_67)\n    {\n        _82 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _82 = _67;\n    }\n    if (_82)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _329 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _336 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_329 * _336).z;\n    fa_pre_r0 = vec3(_329[0].x, _329[1].x, _329[2].x);\n    fa_pre_r1 = vec3(_329[0].y, _329[1].y, _329[2].y);\n    fa_pre_r2 = vec3(_329[0].z, _329[1].z, _329[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _336;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 3, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _608 = base_t;\n    _608.x = _242.x;\n    _608.y = _242.y;\n    _608.z = _242.z;\n    base_t = _608;\n    vec4 _257 = (_608 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _589 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _616 = _294;\n        _616.x = _299.x;\n        _616.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _616;\n        _589 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _619 = mrt;\n    _619.x = _328.x;\n    _619.y = _328.y;\n    _619.z = _328.z;\n    mrt = _619;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _396 = fa_tex_fix(param_20, param_21);\n    return Surface(_257.xyz, _257.w, _589, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_369.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _396));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _536 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _536 = -_536;\n    }\n    vec3 _442 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _536, fa_world_tangent, fa_uv, fa_vertex_color, _442, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _536, fa_world_tangent, fa_uv, fa_vertex_color, _442, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _457 = normalize(param_2.normal);\n    vec3 _472 = normalize(vec3(dot(fa_pre_r0, _457), dot(fa_pre_r1, _457), dot(fa_pre_r2, _457)));\n    float _484 = _472.z;\n    vec2 e = _472.xy / vec2((abs(_472.x) + abs(_472.y)) + abs(_484));\n    if (_484 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_187",
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
            "inst_name": "_231",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_398",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
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
          },
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          },
          {
            "storage_buffer": {
              "slot": 19,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 3
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
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _115 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _115) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_115 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _53 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _68;\n    if (!_53)\n    {\n        _68 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _68 = _53;\n    }\n    if (_68)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_173",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_190",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nstruct extra_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nlayout(binding = 0, std430) readonly buffer fa_vs_extra_buf\n{\n    extra_item data[];\n} fa_vs_extra;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _213 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_213 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_213 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_213 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _120 = cross(model[1].xyz, model[2].xyz);\n    float _124 = (dot(model[0].xyz, _120) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_120 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _124, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _124), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    bool _58 = fa_vs_points.data[gl_InstanceID].pos.w < 0.5;\n    bool _73;\n    if (!_58)\n    {\n        _73 = fa_vs_extra.data[gl_InstanceID].pos.w < (-1.0);\n    }\n    else\n    {\n        _73 = _58;\n    }\n    if (_73)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 7,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 8,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_178",
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
            "inst_name": "_222",
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
            "slot": 6,
            "stage": "vertex",
            "size": 64,
            "struct_name": "fa_inst_base",
            "inst_name": "_302",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 4,
                "offset": 0,
                "glsl_name": "fa_inst_base"
              }
            ]
          }
        ],
        "views": [
          {
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_extra_buf",
              "inst_name": "fa_vs_extra",
              "inner_struct_name": "extra_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
            }
          }
        ]
      }
    }
  }
}
