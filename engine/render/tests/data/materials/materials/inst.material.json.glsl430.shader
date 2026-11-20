{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "glsl430",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _421 = fa_mesh_fs_params[19].x < 0.0;\n    bool _428;\n    if (!_421)\n    {\n        _428 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    bool _436;\n    if (!_428)\n    {\n        _436 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _436 = _428;\n    }\n    bool _443;\n    if (!_436)\n    {\n        _443 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _443 = _436;\n    }\n    bool _450;\n    if (!_443)\n    {\n        _450 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _450 = _443;\n    }\n    if (_450)\n    {\n        return vec4(0.0);\n    }\n    vec4 _460 = vec4(world_pos, 1.0);\n    float _467 = dot(fa_mesh_fs_params[16], _460);\n    if (!(_467 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _489 = vec2(dot(fa_mesh_fs_params[14], _460), dot(fa_mesh_fs_params[15], _460)) / vec2(_467);\n    int _493 = int(fa_mesh_fs_params[18].x);\n    int _497 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _497) + clamp(int(floor(((_489.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _497 - 1)) * _493)) + clamp(int(floor(((_489.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _493 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _573 = fa_cluster_texel(param);\n    return ivec2(int(_573.x), int(_573.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1971 = fa_cluster_lookup(param);\n    fa_cl_slot = _1971.x;\n    fa_cl_local = _1971.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2090 = fa_linear_to_srgb(param);\n        c = _2090;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2098 = fa_srgb_to_linear(param_1);\n            c = _2098;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _188;\n    if (i.front_facing)\n    {\n        _188 = i.world_normal;\n    }\n    else\n    {\n        _188 = -i.world_normal;\n    }\n    vec3 _212 = normalize(i.world_tangent.xyz - (_188 * dot(_188, i.world_tangent.xyz)));\n    vec3 _240 = normalize(((_212 * m.x) + ((cross(_188, _212) * i.world_tangent.w) * m.y)) + (_188 * m.z));\n    vec3 _243;\n    if (i.front_facing)\n    {\n        _243 = _240;\n    }\n    else\n    {\n        _243 = -_240;\n    }\n    return _243;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2129 = fa_tex_fix(param_2, param_3);\n    vec4 _2974 = base_t;\n    _2974.x = _2129.x;\n    _2974.y = _2129.y;\n    _2974.z = _2129.z;\n    base_t = _2974;\n    vec4 _2143 = (_2974 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2898 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2175 = fa_tex_fix(param_6, param_7);\n        vec3 _2178 = (_2175 * 2.0) - vec3(1.0);\n        vec2 _2183 = _2178.xy * fa_mesh_fs_params[6].x;\n        vec3 _2982 = _2178;\n        _2982.x = _2183.x;\n        _2982.y = _2183.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2982;\n        _2898 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2212 = fa_tex_fix(param_12, param_13);\n    vec4 _2985 = mrt;\n    _2985.x = _2212.x;\n    _2985.y = _2212.y;\n    _2985.z = _2212.z;\n    mrt = _2985;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2251 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2278 = fa_tex_fix(param_20, param_21);\n    return Surface(_2143.xyz, _2143.w, _2898, clamp(fa_mesh_fs_params[5].x * _2212.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2212.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2251.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2278));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _654 = rect.zw - rect.xy;\n    vec2 _658 = _654 * atlas;\n    vec2 _662 = ddx * _658;\n    vec2 _666 = ddy * _658;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _654), clamp(0.5 * log2(max(max(dot(_662, _662), dot(_666, _666)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _701 = dFdx(world_pos);\n    vec3 _704 = dFdy(world_pos);\n    bool _707 = fa_mesh_fs_params[10].y < 0.5;\n    bool _714;\n    if (!_707)\n    {\n        _714 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _714 = _707;\n    }\n    if (_714)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _721 = fa_cluster_texel(param);\n    int _725 = int(_721.w);\n    if (_725 < 1)\n    {\n        return;\n    }\n    int _735 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _735;\n    vec4 _739 = fa_light_texel(param_1);\n    vec2 _742 = _739.yz;\n    int _746 = int(_739.w);\n    int param_2 = _735 + 1;\n    vec4 _751 = fa_light_texel(param_2);\n    float _752 = _751.x;\n    int _758 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _762 = int(_721.z);\n    vec3 _1028;\n    for (int k = 0; k < _725; k++)\n    {\n        int _775 = _762 + k;\n        int param_3 = _746 + (_775 >> 2);\n        int _793 = (_735 + 2) + (int(fa_light_texel(param_3)[_775 & 3]) * 7);\n        int param_4 = _793 + 6;\n        vec4 _798 = fa_light_texel(param_4);\n        if (((int(_798.w + 0.5) >> _758) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _793;\n        vec4 _813 = fa_light_texel(param_5);\n        int param_6 = _793 + 1;\n        vec4 _818 = fa_light_texel(param_6);\n        int param_7 = _793 + 2;\n        vec4 _823 = fa_light_texel(param_7);\n        vec3 _826 = _813.xyz;\n        float _831 = dot(_826, world_pos) + _813.w;\n        vec3 _833 = _818.xyz;\n        float _838 = dot(_833, world_pos) + _818.w;\n        vec3 _840 = _823.xyz;\n        float _845 = dot(_840, world_pos) + _823.w;\n        bool _850 = abs(_831) > 0.5;\n        bool _858;\n        if (!_850)\n        {\n            _858 = abs(_838) > 0.5;\n        }\n        else\n        {\n            _858 = _850;\n        }\n        bool _866;\n        if (!_858)\n        {\n            _866 = abs(_845) > 0.5;\n        }\n        else\n        {\n            _866 = _858;\n        }\n        if (_866)\n        {\n            continue;\n        }\n        float _881 = clamp(dot(geo_normal, normalize(_840)) * _798.z, 0.0, 1.0);\n        if (_881 <= 0.0)\n        {\n            continue;\n        }\n        float _901 = (clamp((0.5 - abs(_845)) * 10.0, 0.0, 1.0) * _881) * _798.x;\n        vec2 _909 = vec2(_831 + 0.5, 0.5 - _838);\n        vec2 _919 = vec2(dot(_826, _701), dot(_833, _701));\n        vec2 _929 = vec2(dot(_826, _704), dot(_833, _704));\n        int param_8 = _793 + 5;\n        vec4 _934 = fa_light_texel(param_8);\n        int param_9 = _793 + 3;\n        vec4 _939 = fa_light_texel(param_9);\n        int param_10 = _793 + 4;\n        vec4 _944 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _934.xyz;\n        bool _954 = _939.z > _939.x;\n        if (_954)\n        {\n            vec4 param_11 = _939;\n            vec2 param_12 = _909;\n            vec2 param_13 = _742;\n            vec2 param_14 = _919;\n            vec2 param_15 = _929;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_752 > 0.5) && (_752 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _980 = fa_dc_to_linear(param_16);\n                vec4 _2936 = tx;\n                _2936.x = _980.x;\n                _2936.y = _980.y;\n                _2936.z = _980.z;\n                tx = _2936;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_901 * tex_a) * _934.w, 0.0, 1.0)));\n        if (_944.z > _944.x)\n        {\n            vec4 param_17 = _944;\n            vec2 param_18 = _909;\n            vec2 param_19 = _742;\n            vec2 param_20 = _919;\n            vec2 param_21 = _929;\n            vec4 _1024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_752 > 1.5)\n            {\n                vec3 param_22 = _1024.xyz;\n                vec3 _1034 = fa_dc_to_srgb(param_22);\n                _1028 = _1034;\n            }\n            else\n            {\n                _1028 = _1024.xyz;\n            }\n            vec3 _1044 = (_1028 * 2.0) - vec3(1.0);\n            vec2 _1049 = _1044.xy * _798.y;\n            vec3 _1071 = (normalize(_826) * _1049.x) + (normalize(_833) * _1049.y);\n            vec3 _1074 = normalize(normal);\n            normal = normalize(mix(_1074, normalize((_1074 * max(_1044.z, 0.0500000007450580596923828125)) + (_1071 - (_1074 * dot(_1074, _1071)))), vec3(clamp(_901 * (_954 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _288 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _294 = fa_light_texel(param_1);\n    float _297 = _294.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _304 = _297 < 0.5;\n    vec3 l;\n    if (_304)\n    {\n        l = normalize(_288.xyz);\n    }\n    else\n    {\n        vec3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / vec3(max(_318, 9.9999997473787516355514526367188e-05));\n        float _333 = _318 / max(_288.w, 0.001000000047497451305389404296875);\n        float _339 = clamp(1.0 - (_333 * _333), 0.0, 1.0);\n        atten = _339 * _339;\n        if (_297 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _353 = fa_light_texel(param_2);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_363, 1.0, 0.25);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, normalize(_353.xyz)));\n        }\n    }\n    int _402;\n    if (_304)\n    {\n        _402 = 0;\n    }\n    else\n    {\n        _402 = (_297 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _294.xyz * atten, atten, 1.0, dist, _402);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1146;\n    if (i == 0)\n    {\n        _1146 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1162;\n        if (i == 1)\n        {\n            _1162 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1170;\n            if (i == 2)\n            {\n                _1170 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1170 = fa_shadows[24].w;\n            }\n            _1162 = _1170;\n        }\n        _1146 = _1162;\n    }\n    return _1146;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1134 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1134), sin(_1134)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1208 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1213 = clamp(dot(n, l), 0.0, 1.0);\n    float _1219 = sqrt(1.0 - (_1213 * _1213));\n    float _1226 = min(_1219 / max(_1213, 0.20000000298023223876953125), 4.0);\n    float _1231;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1231 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1231 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1256 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1231 * _1219)), 1.0);\n    float _1263 = _1256.x;\n    bool _1266 = _1263 < fa_shadows[ci * 1 + 16].x;\n    bool _1275;\n    if (!_1266)\n    {\n        _1275 = _1263 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1275 = _1266;\n    }\n    bool _1284;\n    if (!_1275)\n    {\n        _1284 = _1256.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1284 = _1275;\n    }\n    bool _1293;\n    if (!_1284)\n    {\n        _1293 = _1256.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1293 = _1284;\n    }\n    bool _1300;\n    if (!_1293)\n    {\n        _1300 = _1256.z > 1.0;\n    }\n    else\n    {\n        _1300 = _1293;\n    }\n    if (_1300)\n    {\n        return -1.0;\n    }\n    float _1309;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1309 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1309 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1328 = _1256.z - ((_1309 * (1.0 + (0.5 * _1226))) / _1208);\n    float _1337 = ((fa_shadows[ci * 1 + 20].x * min(_1226, 3.0)) * 0.5) / _1208;\n    int _1346 = int(fa_shadows[25].z + 0.5);\n    if (_1346 == 1)\n    {\n        vec2 param = _1256.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1357 = fa_shadow_depth(param, param_1);\n        return float(_1328 <= _1357);\n    }\n    float _1364 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1367 = _1346 == 2;\n    if (_1367)\n    {\n        float _1381 = clamp(((fa_shadows[25].w * _1208) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1364;\n            vec2 _1400 = fa_shadow_vogel(param_2, param_3, param_4) * _1381;\n            vec2 param_5 = _1256.xy + (_1400 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1411 = fa_shadow_depth(param_5, param_6);\n            if (_1411 < (_1328 - (length(_1400) * _1337)))\n            {\n                sum += _1411;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1328 - (sum / cnt), 0.0) * _1208) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1455 = _1367 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1455; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1455;\n        float param_9 = _1364;\n        vec2 _1474 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1256.xy + (_1474 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1485 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1328 - (length(_1474) * _1337)) <= _1485);\n    }\n    return lit / float(_1455);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1515 = int(fa_shadows[25].x + 0.5);\n    if (_1515 < 1)\n    {\n        return 1.0;\n    }\n    float _1530 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1515 - 1;\n    if (_1530 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1542 = _1515 > 1;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1530 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 1;\n    }\n    bool _1553 = _1515 > 2;\n    bool _1560;\n    if (_1553)\n    {\n        _1560 = _1530 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1560 = _1553;\n    }\n    if (_1560)\n    {\n        ci = 2;\n    }\n    bool _1564 = _1515 > 3;\n    bool _1571;\n    if (_1564)\n    {\n        _1571 = _1530 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1515)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1597 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1597;\n        if (_1597 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1622;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1622 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1622 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1641 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1622, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1652 = clamp((_1530 - (fa_shadow_split_at(param_7) - _1641)) / _1641, 0.0, 1.0);\n        if (_1652 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1515)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1673 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1673;\n                if (_1673 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1652);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1999 = fa_light_sample(param, param_1);\n    vec3 _2883 = _1999.direction;\n    vec3 _2878 = _1999.color;\n    float _2880 = _1999.shadow;\n    int _2888 = _1999.type;\n    if ((_2888 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2883;\n        float _2013 = fa_shadow_factor(param_2, param_3);\n        _2880 = _2013;\n        _2878 *= _2013;\n    }\n    return LightSample(_2883, _2878, _1999.attenuation, _2880, _1999._distance, _2888);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1903 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1906 = _1903.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1906 * _1906, exp2((-9.27999973297119140625) * ndv)) * _1906) + _1903.y)) + _1903.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1809 = rough * rough;\n    float _1839 = 0.60000002384185791015625 * _1809;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1809)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1839, 0.0500000007450580596923828125 + _1839, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1809 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1945 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1945.x) + vec3(_1945.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1697 = int(fa_shadows[25].x + 0.5);\n    float _1707 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1712 = _1697 > 0;\n    bool _1721;\n    if (_1712)\n    {\n        int param = _1697 - 1;\n        _1721 = _1707 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1721 = _1712;\n    }\n    if (_1721)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1728 = _1697 > 1;\n        bool _1735;\n        if (_1728)\n        {\n            _1735 = _1707 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1735 = _1728;\n        }\n        if (_1735)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1741 = _1697 > 2;\n        bool _1748;\n        if (_1741)\n        {\n            _1748 = _1707 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1748 = _1741;\n        }\n        if (_1748)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1754 = _1697 > 3;\n        bool _1761;\n        if (_1754)\n        {\n            _1761 = _1707 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1761 = _1754;\n        }\n        if (_1761)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2803 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2803 = -_2803;\n    }\n    vec3 _2321 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2803, fa_world_tangent, fa_uv, fa_vertex_color, _2321, gl_FrontFacing);\n    Surface _2329 = fa_standard_surface(param_1);\n    vec3 _2826 = _2329.albedo;\n    float _2827 = _2329.alpha;\n    vec3 _2828 = _2329.normal;\n    float _2829 = _2329.metallic;\n    float _2830 = _2329.roughness;\n    float _2831 = _2329.occlusion;\n    vec3 _2832 = _2329.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2803, fa_world_tangent, fa_uv, fa_vertex_color, _2321, gl_FrontFacing);\n    Surface param_3 = _2329;\n    surface(param_2, param_3);\n    _2826 = param_3.albedo;\n    _2827 = param_3.alpha;\n    _2828 = param_3.normal;\n    _2829 = param_3.metallic;\n    _2830 = param_3.roughness;\n    _2831 = param_3.occlusion;\n    _2832 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2803;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2826 = param_6;\n    _2828 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2826;\n    }\n    else\n    {\n        vec3 _2368 = normalize(_2828);\n        float _2375 = clamp(_2829, 0.0, 1.0);\n        float _2379 = clamp(_2830, 0.0500000007450580596923828125, 1.0);\n        float _2383 = _2379 * _2379;\n        float _2387 = _2383 * _2383;\n        float _2392 = max(dot(_2368, _2321), 9.9999997473787516355514526367188e-05);\n        vec3 _2398 = _2826 * (1.0 - _2375);\n        vec3 _2406 = mix(vec3(0.039999999105930328369140625), _2826, vec3(_2375));\n        vec3 param_8 = _2368;\n        vec3 lit = (fa_ambient_light(param_8) * _2398) * _2831;\n        int _2419 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2419; ln++)\n        {\n            int param_9 = ln;\n            int _2432 = fa_cl_light(param_9);\n            int param_10 = _2432;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2803;\n            LightSample _2441 = fa_light_shadowed(param_10, param_11, param_12);\n            vec3 _2861 = _2441.direction;\n            float _2449 = max(dot(_2368, _2861), 0.0);\n            vec3 _2460 = normalize(_2861 + _2321);\n            float _2465 = max(dot(_2368, _2460), 0.0);\n            float _2478 = ((_2465 * _2465) * (_2387 - 1.0)) + 1.0;\n            int param_13 = _2432;\n            lit += (((_2398 + (((_2406 + ((vec3(1.0) - _2406) * pow(1.0 - max(dot(_2321, _2460), 0.0), 5.0))) * (((_2387 / ((3.1415927410125732421875 * _2478) * _2478)) * (0.5 / max(mix((2.0 * _2449) * _2392, _2449 + _2392, _2383), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2449))) * fa_light_rgb(param_13)) * (_2449 * (_2441.attenuation * _2441.shadow)));\n        }\n        vec3 param_14 = _2368;\n        vec3 param_15 = _2321;\n        vec3 param_16 = _2406;\n        float param_17 = _2379;\n        vec3 _2547 = lit;\n        vec3 _2548 = _2547 + (fa_sky_reflection(param_14, param_15, param_16, param_17) * _2831);\n        lit = _2548;\n        result = _2548;\n    }\n    vec3 _2552 = result;\n    vec3 _2553 = _2552 + _2832;\n    result = _2553;\n    vec3 param_18 = _2553;\n    vec3 param_19 = fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19);\n    bool _2562 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2570;\n    if (!_2562)\n    {\n        _2570 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2570 = _2562;\n    }\n    if (_2570)\n    {\n        vec3 _2579 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2586 = dot(_2579, fa_mesh_fs_params[9].xyz);\n        bool _2590 = fa_mesh_fs_params[9].w > 0.5;\n        float _2591;\n        if (_2590)\n        {\n            _2591 = _2586;\n        }\n        else\n        {\n            _2591 = length(_2579);\n        }\n        float _2603 = _2591 - fa_mesh_fs_params[8].x;\n        if (_2603 > 0.0)\n        {\n            float _2612 = fa_mesh_fs_params[7].w * _2603;\n            float tau = _2612 * _2612;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2628;\n                if (_2590)\n                {\n                    _2628 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2586);\n                }\n                else\n                {\n                    _2628 = fa_mesh_fs_params[0].y;\n                }\n                float _2649 = mix(_2628, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2591, 0.0, 1.0));\n                float _2653 = fa_world_pos.y - _2649;\n                float _2658 = _2649 - fa_mesh_fs_params[8].z;\n                float _2663 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2666 = _2658 <= 0.0;\n                bool _2667 = !_2666;\n                bool _2673;\n                if (_2667)\n                {\n                    _2673 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2673 = _2666;\n                }\n                float _2674;\n                if (_2673)\n                {\n                    _2674 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2674 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2658, 80.0));\n                }\n                bool _2701;\n                if (_2667)\n                {\n                    _2701 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2701 = _2666;\n                }\n                float _2702;\n                if (_2701)\n                {\n                    _2702 = fa_mesh_fs_params[8].y * _2658;\n                }\n                else\n                {\n                    _2702 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2658, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2727 = _2663 <= 0.0;\n                bool _2734;\n                if (!_2727)\n                {\n                    _2734 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2734 = _2727;\n                }\n                float _2735;\n                if (_2734)\n                {\n                    _2735 = fa_mesh_fs_params[8].y * _2663;\n                }\n                else\n                {\n                    _2735 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2663, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2762;\n                if (abs(_2653) < 0.001000000047497451305389404296875)\n                {\n                    _2762 = _2674;\n                }\n                else\n                {\n                    _2762 = (_2735 - _2702) / _2653;\n                }\n                tau += (_2603 * max(_2762, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2827);\n}\n\n",
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
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_416",
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
            "inst_name": "_1156",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2038",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _421 = fa_mesh_fs_params[19].x < 0.0;\n    bool _428;\n    if (!_421)\n    {\n        _428 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    bool _436;\n    if (!_428)\n    {\n        _436 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _436 = _428;\n    }\n    bool _443;\n    if (!_436)\n    {\n        _443 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _443 = _436;\n    }\n    bool _450;\n    if (!_443)\n    {\n        _450 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _450 = _443;\n    }\n    if (_450)\n    {\n        return vec4(0.0);\n    }\n    vec4 _460 = vec4(world_pos, 1.0);\n    float _467 = dot(fa_mesh_fs_params[16], _460);\n    if (!(_467 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _489 = vec2(dot(fa_mesh_fs_params[14], _460), dot(fa_mesh_fs_params[15], _460)) / vec2(_467);\n    int _493 = int(fa_mesh_fs_params[18].x);\n    int _497 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _497) + clamp(int(floor(((_489.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _497 - 1)) * _493)) + clamp(int(floor(((_489.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _493 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _573 = fa_cluster_texel(param);\n    return ivec2(int(_573.x), int(_573.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1971 = fa_cluster_lookup(param);\n    fa_cl_slot = _1971.x;\n    fa_cl_local = _1971.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2090 = fa_linear_to_srgb(param);\n        c = _2090;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2098 = fa_srgb_to_linear(param_1);\n            c = _2098;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _188;\n    if (i.front_facing)\n    {\n        _188 = i.world_normal;\n    }\n    else\n    {\n        _188 = -i.world_normal;\n    }\n    vec3 _212 = normalize(i.world_tangent.xyz - (_188 * dot(_188, i.world_tangent.xyz)));\n    vec3 _240 = normalize(((_212 * m.x) + ((cross(_188, _212) * i.world_tangent.w) * m.y)) + (_188 * m.z));\n    vec3 _243;\n    if (i.front_facing)\n    {\n        _243 = _240;\n    }\n    else\n    {\n        _243 = -_240;\n    }\n    return _243;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2129 = fa_tex_fix(param_2, param_3);\n    vec4 _2974 = base_t;\n    _2974.x = _2129.x;\n    _2974.y = _2129.y;\n    _2974.z = _2129.z;\n    base_t = _2974;\n    vec4 _2143 = (_2974 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2898 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2175 = fa_tex_fix(param_6, param_7);\n        vec3 _2178 = (_2175 * 2.0) - vec3(1.0);\n        vec2 _2183 = _2178.xy * fa_mesh_fs_params[6].x;\n        vec3 _2982 = _2178;\n        _2982.x = _2183.x;\n        _2982.y = _2183.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2982;\n        _2898 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2212 = fa_tex_fix(param_12, param_13);\n    vec4 _2985 = mrt;\n    _2985.x = _2212.x;\n    _2985.y = _2212.y;\n    _2985.z = _2212.z;\n    mrt = _2985;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2251 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2278 = fa_tex_fix(param_20, param_21);\n    return Surface(_2143.xyz, _2143.w, _2898, clamp(fa_mesh_fs_params[5].x * _2212.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2212.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2251.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2278));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _654 = rect.zw - rect.xy;\n    vec2 _658 = _654 * atlas;\n    vec2 _662 = ddx * _658;\n    vec2 _666 = ddy * _658;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _654), clamp(0.5 * log2(max(max(dot(_662, _662), dot(_666, _666)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _701 = dFdx(world_pos);\n    vec3 _704 = dFdy(world_pos);\n    bool _707 = fa_mesh_fs_params[10].y < 0.5;\n    bool _714;\n    if (!_707)\n    {\n        _714 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _714 = _707;\n    }\n    if (_714)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _721 = fa_cluster_texel(param);\n    int _725 = int(_721.w);\n    if (_725 < 1)\n    {\n        return;\n    }\n    int _735 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _735;\n    vec4 _739 = fa_light_texel(param_1);\n    vec2 _742 = _739.yz;\n    int _746 = int(_739.w);\n    int param_2 = _735 + 1;\n    vec4 _751 = fa_light_texel(param_2);\n    float _752 = _751.x;\n    int _758 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _762 = int(_721.z);\n    vec3 _1028;\n    for (int k = 0; k < _725; k++)\n    {\n        int _775 = _762 + k;\n        int param_3 = _746 + (_775 >> 2);\n        int _793 = (_735 + 2) + (int(fa_light_texel(param_3)[_775 & 3]) * 7);\n        int param_4 = _793 + 6;\n        vec4 _798 = fa_light_texel(param_4);\n        if (((int(_798.w + 0.5) >> _758) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _793;\n        vec4 _813 = fa_light_texel(param_5);\n        int param_6 = _793 + 1;\n        vec4 _818 = fa_light_texel(param_6);\n        int param_7 = _793 + 2;\n        vec4 _823 = fa_light_texel(param_7);\n        vec3 _826 = _813.xyz;\n        float _831 = dot(_826, world_pos) + _813.w;\n        vec3 _833 = _818.xyz;\n        float _838 = dot(_833, world_pos) + _818.w;\n        vec3 _840 = _823.xyz;\n        float _845 = dot(_840, world_pos) + _823.w;\n        bool _850 = abs(_831) > 0.5;\n        bool _858;\n        if (!_850)\n        {\n            _858 = abs(_838) > 0.5;\n        }\n        else\n        {\n            _858 = _850;\n        }\n        bool _866;\n        if (!_858)\n        {\n            _866 = abs(_845) > 0.5;\n        }\n        else\n        {\n            _866 = _858;\n        }\n        if (_866)\n        {\n            continue;\n        }\n        float _881 = clamp(dot(geo_normal, normalize(_840)) * _798.z, 0.0, 1.0);\n        if (_881 <= 0.0)\n        {\n            continue;\n        }\n        float _901 = (clamp((0.5 - abs(_845)) * 10.0, 0.0, 1.0) * _881) * _798.x;\n        vec2 _909 = vec2(_831 + 0.5, 0.5 - _838);\n        vec2 _919 = vec2(dot(_826, _701), dot(_833, _701));\n        vec2 _929 = vec2(dot(_826, _704), dot(_833, _704));\n        int param_8 = _793 + 5;\n        vec4 _934 = fa_light_texel(param_8);\n        int param_9 = _793 + 3;\n        vec4 _939 = fa_light_texel(param_9);\n        int param_10 = _793 + 4;\n        vec4 _944 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _934.xyz;\n        bool _954 = _939.z > _939.x;\n        if (_954)\n        {\n            vec4 param_11 = _939;\n            vec2 param_12 = _909;\n            vec2 param_13 = _742;\n            vec2 param_14 = _919;\n            vec2 param_15 = _929;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_752 > 0.5) && (_752 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _980 = fa_dc_to_linear(param_16);\n                vec4 _2936 = tx;\n                _2936.x = _980.x;\n                _2936.y = _980.y;\n                _2936.z = _980.z;\n                tx = _2936;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_901 * tex_a) * _934.w, 0.0, 1.0)));\n        if (_944.z > _944.x)\n        {\n            vec4 param_17 = _944;\n            vec2 param_18 = _909;\n            vec2 param_19 = _742;\n            vec2 param_20 = _919;\n            vec2 param_21 = _929;\n            vec4 _1024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_752 > 1.5)\n            {\n                vec3 param_22 = _1024.xyz;\n                vec3 _1034 = fa_dc_to_srgb(param_22);\n                _1028 = _1034;\n            }\n            else\n            {\n                _1028 = _1024.xyz;\n            }\n            vec3 _1044 = (_1028 * 2.0) - vec3(1.0);\n            vec2 _1049 = _1044.xy * _798.y;\n            vec3 _1071 = (normalize(_826) * _1049.x) + (normalize(_833) * _1049.y);\n            vec3 _1074 = normalize(normal);\n            normal = normalize(mix(_1074, normalize((_1074 * max(_1044.z, 0.0500000007450580596923828125)) + (_1071 - (_1074 * dot(_1074, _1071)))), vec3(clamp(_901 * (_954 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _288 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _294 = fa_light_texel(param_1);\n    float _297 = _294.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _304 = _297 < 0.5;\n    vec3 l;\n    if (_304)\n    {\n        l = normalize(_288.xyz);\n    }\n    else\n    {\n        vec3 _316 = _288.xyz - world_pos;\n        float _318 = length(_316);\n        dist = _318;\n        l = _316 / vec3(max(_318, 9.9999997473787516355514526367188e-05));\n        float _333 = _318 / max(_288.w, 0.001000000047497451305389404296875);\n        float _339 = clamp(1.0 - (_333 * _333), 0.0, 1.0);\n        atten = _339 * _339;\n        if (_297 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _353 = fa_light_texel(param_2);\n            float _363 = _353.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_363, 1.0, 0.25);\n            }\n            atten *= smoothstep(_363, cos_inner, dot(-l, normalize(_353.xyz)));\n        }\n    }\n    int _402;\n    if (_304)\n    {\n        _402 = 0;\n    }\n    else\n    {\n        _402 = (_297 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _294.xyz * atten, atten, 1.0, dist, _402);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1146;\n    if (i == 0)\n    {\n        _1146 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1162;\n        if (i == 1)\n        {\n            _1162 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1170;\n            if (i == 2)\n            {\n                _1170 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1170 = fa_shadows[24].w;\n            }\n            _1162 = _1170;\n        }\n        _1146 = _1162;\n    }\n    return _1146;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1134 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1134), sin(_1134)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1208 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1213 = clamp(dot(n, l), 0.0, 1.0);\n    float _1219 = sqrt(1.0 - (_1213 * _1213));\n    float _1226 = min(_1219 / max(_1213, 0.20000000298023223876953125), 4.0);\n    float _1231;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1231 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1231 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1256 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1231 * _1219)), 1.0);\n    float _1263 = _1256.x;\n    bool _1266 = _1263 < fa_shadows[ci * 1 + 16].x;\n    bool _1275;\n    if (!_1266)\n    {\n        _1275 = _1263 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1275 = _1266;\n    }\n    bool _1284;\n    if (!_1275)\n    {\n        _1284 = _1256.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1284 = _1275;\n    }\n    bool _1293;\n    if (!_1284)\n    {\n        _1293 = _1256.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1293 = _1284;\n    }\n    bool _1300;\n    if (!_1293)\n    {\n        _1300 = _1256.z > 1.0;\n    }\n    else\n    {\n        _1300 = _1293;\n    }\n    if (_1300)\n    {\n        return -1.0;\n    }\n    float _1309;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1309 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1309 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1328 = _1256.z - ((_1309 * (1.0 + (0.5 * _1226))) / _1208);\n    float _1337 = ((fa_shadows[ci * 1 + 20].x * min(_1226, 3.0)) * 0.5) / _1208;\n    int _1346 = int(fa_shadows[25].z + 0.5);\n    if (_1346 == 1)\n    {\n        vec2 param = _1256.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1357 = fa_shadow_depth(param, param_1);\n        return float(_1328 <= _1357);\n    }\n    float _1364 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1367 = _1346 == 2;\n    if (_1367)\n    {\n        float _1381 = clamp(((fa_shadows[25].w * _1208) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1364;\n            vec2 _1400 = fa_shadow_vogel(param_2, param_3, param_4) * _1381;\n            vec2 param_5 = _1256.xy + (_1400 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1411 = fa_shadow_depth(param_5, param_6);\n            if (_1411 < (_1328 - (length(_1400) * _1337)))\n            {\n                sum += _1411;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1328 - (sum / cnt), 0.0) * _1208) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1455 = _1367 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1455; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1455;\n        float param_9 = _1364;\n        vec2 _1474 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1256.xy + (_1474 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1485 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1328 - (length(_1474) * _1337)) <= _1485);\n    }\n    return lit / float(_1455);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1515 = int(fa_shadows[25].x + 0.5);\n    if (_1515 < 1)\n    {\n        return 1.0;\n    }\n    float _1530 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1515 - 1;\n    if (_1530 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1542 = _1515 > 1;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1530 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 1;\n    }\n    bool _1553 = _1515 > 2;\n    bool _1560;\n    if (_1553)\n    {\n        _1560 = _1530 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1560 = _1553;\n    }\n    if (_1560)\n    {\n        ci = 2;\n    }\n    bool _1564 = _1515 > 3;\n    bool _1571;\n    if (_1564)\n    {\n        _1571 = _1530 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1571 = _1564;\n    }\n    if (_1571)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1515)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1597 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1597;\n        if (_1597 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1622;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1622 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1622 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1641 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1622, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1652 = clamp((_1530 - (fa_shadow_split_at(param_7) - _1641)) / _1641, 0.0, 1.0);\n        if (_1652 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1515)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1673 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1673;\n                if (_1673 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1652);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1999 = fa_light_sample(param, param_1);\n    vec3 _2883 = _1999.direction;\n    vec3 _2878 = _1999.color;\n    float _2880 = _1999.shadow;\n    int _2888 = _1999.type;\n    if ((_2888 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2883;\n        float _2013 = fa_shadow_factor(param_2, param_3);\n        _2880 = _2013;\n        _2878 *= _2013;\n    }\n    return LightSample(_2883, _2878, _1999.attenuation, _2880, _1999._distance, _2888);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1903 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1906 = _1903.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1906 * _1906, exp2((-9.27999973297119140625) * ndv)) * _1906) + _1903.y)) + _1903.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1809 = rough * rough;\n    float _1839 = 0.60000002384185791015625 * _1809;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1809)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1839, 0.0500000007450580596923828125 + _1839, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1809 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1945 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1945.x) + vec3(_1945.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1697 = int(fa_shadows[25].x + 0.5);\n    float _1707 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1712 = _1697 > 0;\n    bool _1721;\n    if (_1712)\n    {\n        int param = _1697 - 1;\n        _1721 = _1707 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1721 = _1712;\n    }\n    if (_1721)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1728 = _1697 > 1;\n        bool _1735;\n        if (_1728)\n        {\n            _1735 = _1707 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1735 = _1728;\n        }\n        if (_1735)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1741 = _1697 > 2;\n        bool _1748;\n        if (_1741)\n        {\n            _1748 = _1707 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1748 = _1741;\n        }\n        if (_1748)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1754 = _1697 > 3;\n        bool _1761;\n        if (_1754)\n        {\n            _1761 = _1707 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1761 = _1754;\n        }\n        if (_1761)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2803 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2803 = -_2803;\n    }\n    vec3 _2321 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2803, fa_world_tangent, fa_uv, fa_vertex_color, _2321, gl_FrontFacing);\n    Surface _2329 = fa_standard_surface(param_1);\n    vec3 _2826 = _2329.albedo;\n    float _2827 = _2329.alpha;\n    vec3 _2828 = _2329.normal;\n    float _2829 = _2329.metallic;\n    float _2830 = _2329.roughness;\n    float _2831 = _2329.occlusion;\n    vec3 _2832 = _2329.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2803, fa_world_tangent, fa_uv, fa_vertex_color, _2321, gl_FrontFacing);\n    Surface param_3 = _2329;\n    surface(param_2, param_3);\n    _2826 = param_3.albedo;\n    _2827 = param_3.alpha;\n    _2828 = param_3.normal;\n    _2829 = param_3.metallic;\n    _2830 = param_3.roughness;\n    _2831 = param_3.occlusion;\n    _2832 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2803;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2826 = param_6;\n    _2828 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2826;\n    }\n    else\n    {\n        vec3 _2368 = normalize(_2828);\n        float _2375 = clamp(_2829, 0.0, 1.0);\n        float _2379 = clamp(_2830, 0.0500000007450580596923828125, 1.0);\n        float _2383 = _2379 * _2379;\n        float _2387 = _2383 * _2383;\n        float _2392 = max(dot(_2368, _2321), 9.9999997473787516355514526367188e-05);\n        vec3 _2398 = _2826 * (1.0 - _2375);\n        vec3 _2406 = mix(vec3(0.039999999105930328369140625), _2826, vec3(_2375));\n        vec3 param_8 = _2368;\n        vec3 lit = (fa_ambient_light(param_8) * _2398) * _2831;\n        int _2419 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2419; ln++)\n        {\n            int param_9 = ln;\n            int _2432 = fa_cl_light(param_9);\n            int param_10 = _2432;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2803;\n            LightSample _2441 = fa_light_shadowed(param_10, param_11, param_12);\n            vec3 _2861 = _2441.direction;\n            float _2449 = max(dot(_2368, _2861), 0.0);\n            vec3 _2460 = normalize(_2861 + _2321);\n            float _2465 = max(dot(_2368, _2460), 0.0);\n            float _2478 = ((_2465 * _2465) * (_2387 - 1.0)) + 1.0;\n            int param_13 = _2432;\n            lit += (((_2398 + (((_2406 + ((vec3(1.0) - _2406) * pow(1.0 - max(dot(_2321, _2460), 0.0), 5.0))) * (((_2387 / ((3.1415927410125732421875 * _2478) * _2478)) * (0.5 / max(mix((2.0 * _2449) * _2392, _2449 + _2392, _2383), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2449))) * fa_light_rgb(param_13)) * (_2449 * (_2441.attenuation * _2441.shadow)));\n        }\n        vec3 param_14 = _2368;\n        vec3 param_15 = _2321;\n        vec3 param_16 = _2406;\n        float param_17 = _2379;\n        vec3 _2547 = lit;\n        vec3 _2548 = _2547 + (fa_sky_reflection(param_14, param_15, param_16, param_17) * _2831);\n        lit = _2548;\n        result = _2548;\n    }\n    vec3 _2552 = result;\n    vec3 _2553 = _2552 + _2832;\n    result = _2553;\n    vec3 param_18 = _2553;\n    vec3 param_19 = fa_world_pos;\n    result = fa_shadow_debug(param_18, param_19);\n    bool _2562 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2570;\n    if (!_2562)\n    {\n        _2570 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2570 = _2562;\n    }\n    if (_2570)\n    {\n        vec3 _2579 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2586 = dot(_2579, fa_mesh_fs_params[9].xyz);\n        bool _2590 = fa_mesh_fs_params[9].w > 0.5;\n        float _2591;\n        if (_2590)\n        {\n            _2591 = _2586;\n        }\n        else\n        {\n            _2591 = length(_2579);\n        }\n        float _2603 = _2591 - fa_mesh_fs_params[8].x;\n        if (_2603 > 0.0)\n        {\n            float _2612 = fa_mesh_fs_params[7].w * _2603;\n            float tau = _2612 * _2612;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2628;\n                if (_2590)\n                {\n                    _2628 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2586);\n                }\n                else\n                {\n                    _2628 = fa_mesh_fs_params[0].y;\n                }\n                float _2649 = mix(_2628, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2591, 0.0, 1.0));\n                float _2653 = fa_world_pos.y - _2649;\n                float _2658 = _2649 - fa_mesh_fs_params[8].z;\n                float _2663 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2666 = _2658 <= 0.0;\n                bool _2667 = !_2666;\n                bool _2673;\n                if (_2667)\n                {\n                    _2673 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2673 = _2666;\n                }\n                float _2674;\n                if (_2673)\n                {\n                    _2674 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2674 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2658, 80.0));\n                }\n                bool _2701;\n                if (_2667)\n                {\n                    _2701 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2701 = _2666;\n                }\n                float _2702;\n                if (_2701)\n                {\n                    _2702 = fa_mesh_fs_params[8].y * _2658;\n                }\n                else\n                {\n                    _2702 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2658, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2727 = _2663 <= 0.0;\n                bool _2734;\n                if (!_2727)\n                {\n                    _2734 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2734 = _2727;\n                }\n                float _2735;\n                if (_2734)\n                {\n                    _2735 = fa_mesh_fs_params[8].y * _2663;\n                }\n                else\n                {\n                    _2735 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2663, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2762;\n                if (abs(_2653) < 0.001000000047497451305389404296875)\n                {\n                    _2762 = _2674;\n                }\n                else\n                {\n                    _2762 = (_2735 - _2702) / _2653;\n                }\n                tau += (_2603 * max(_2762, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2827);\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
            "inst_name": "_205",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_416",
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
            "inst_name": "_1156",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_2038",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _625 = base_t;\n    _625.x = _264.x;\n    _625.y = _264.y;\n    _625.z = _264.z;\n    base_t = _625;\n    vec4 _280 = (_625 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _606 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _633 = _317;\n        _633.x = _322.x;\n        _633.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _633;\n        _606 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _636 = mrt;\n    _636.x = _351.x;\n    _636.y = _351.y;\n    _636.z = _351.z;\n    mrt = _636;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _419 = fa_tex_fix(param_20, param_21);\n    return Surface(_280.xyz, _280.w, _606, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_392.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _419));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _553 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _553 = -_553;\n    }\n    vec3 _464 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _553, fa_world_tangent, fa_uv, fa_vertex_color, _464, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _553, fa_world_tangent, fa_uv, fa_vertex_color, _464, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _479 = normalize(param_2.normal);\n    vec3 _494 = normalize(vec3(dot(fa_pre_r0, _479), dot(fa_pre_r1, _479), dot(fa_pre_r2, _479)));\n    float _506 = _494.z;\n    vec2 e = _494.xy / vec2((abs(_494.x) + abs(_494.y)) + abs(_506));\n    if (_506 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _303 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _310 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_303 * _310).z;\n    fa_pre_r0 = vec3(_303[0].x, _303[1].x, _303[2].x);\n    fa_pre_r1 = vec3(_303[0].y, _303[1].y, _303[2].y);\n    fa_pre_r2 = vec3(_303[0].z, _303[1].z, _303[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _310;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _625 = base_t;\n    _625.x = _264.x;\n    _625.y = _264.y;\n    _625.z = _264.z;\n    base_t = _625;\n    vec4 _280 = (_625 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _606 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _633 = _317;\n        _633.x = _322.x;\n        _633.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _633;\n        _606 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _636 = mrt;\n    _636.x = _351.x;\n    _636.y = _351.y;\n    _636.z = _351.z;\n    mrt = _636;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _392 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _419 = fa_tex_fix(param_20, param_21);\n    return Surface(_280.xyz, _280.w, _606, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_392.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _419));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _553 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _553 = -_553;\n    }\n    vec3 _464 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _553, fa_world_tangent, fa_uv, fa_vertex_color, _464, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _553, fa_world_tangent, fa_uv, fa_vertex_color, _464, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _479 = normalize(param_2.normal);\n    vec3 _494 = normalize(vec3(dot(fa_pre_r0, _479), dot(fa_pre_r1, _479), dot(fa_pre_r2, _479)));\n    float _506 = _494.z;\n    vec2 e = _494.xy / vec2((abs(_494.x) + abs(_494.y)) + abs(_506));\n    if (_506 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
            "inst_name": "_205",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_187 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_187 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_187 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
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
            "inst_name": "_196",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ]
      }
    }
  }
}
