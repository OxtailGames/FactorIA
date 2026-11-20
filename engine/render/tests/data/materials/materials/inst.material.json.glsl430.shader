{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "5c278b25d8ce4341984c8bf2a53e1ca7890b6a924713889b53c089df056597d0",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2745[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _558 = fa_mesh_fs_params[19].x < 0.0;\n    bool _565;\n    if (!_558)\n    {\n        _565 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _565 = _558;\n    }\n    bool _573;\n    if (!_565)\n    {\n        _573 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _573 = _565;\n    }\n    bool _580;\n    if (!_573)\n    {\n        _580 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _580 = _573;\n    }\n    bool _587;\n    if (!_580)\n    {\n        _587 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _587 = _580;\n    }\n    if (_587)\n    {\n        return vec4(0.0);\n    }\n    vec4 _597 = vec4(world_pos, 1.0);\n    float _604 = dot(fa_mesh_fs_params[16], _597);\n    if (!(_604 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _626 = vec2(dot(fa_mesh_fs_params[14], _597), dot(fa_mesh_fs_params[15], _597)) / vec2(_604);\n    int _630 = int(fa_mesh_fs_params[18].x);\n    int _634 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _634) + clamp(int(floor(((_626.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _634 - 1)) * _630)) + clamp(int(floor(((_626.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _630 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _710 = fa_cluster_texel(param);\n    return ivec2(int(_710.x), int(_710.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3558 = fa_cluster_lookup(param);\n    fa_cl_slot = _3558.x;\n    fa_cl_local = _3558.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3733 = fa_linear_to_srgb(param);\n        c = _3733;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3741 = fa_srgb_to_linear(param_1);\n            c = _3741;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _309;\n    if (i.front_facing)\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    vec3 _333 = normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    vec3 _360 = normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    vec3 _363;\n    if (i.front_facing)\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3772 = fa_tex_fix(param_2, param_3);\n    vec4 _5071 = base_t;\n    _5071.x = _3772.x;\n    _5071.y = _3772.y;\n    _5071.z = _3772.z;\n    base_t = _5071;\n    vec4 _3786 = (_5071 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4938 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3818 = fa_tex_fix(param_6, param_7);\n        vec3 _3821 = (_3818 * 2.0) - vec3(1.0);\n        vec2 _3826 = _3821.xy * fa_mesh_fs_params[6].x;\n        vec3 _5079 = _3821;\n        _5079.x = _3826.x;\n        _5079.y = _3826.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5079;\n        _4938 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3855 = fa_tex_fix(param_12, param_13);\n    vec4 _5082 = mrt;\n    _5082.x = _3855.x;\n    _5082.y = _3855.y;\n    _5082.z = _3855.z;\n    mrt = _5082;\n    vec4 _3883 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3883.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3895 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3925 = fa_tex_fix(param_20, param_21);\n    float _4943 = fa_mesh_fs_params[20].x;\n    float _4944 = fa_mesh_fs_params[20].y;\n    float _4947 = fa_mesh_fs_params[20].z;\n    float _4946 = fa_mesh_fs_params[21].w;\n    float _4949 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4943 *= _3895.y;\n            _4944 *= _3895.z;\n            _4946 *= _3883.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4947 *= mrt.x;\n            _4949 *= mrt.w;\n        }\n    }\n    return Surface(_3786.xyz, _3786.w, _4938, clamp(fa_mesh_fs_params[5].x * _3855.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3855.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3895.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3925), _4943, _4944, fa_mesh_fs_params[21].xyz, _4946, _4947, fa_mesh_fs_params[20].w, _4949, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _791 = rect.zw - rect.xy;\n    vec2 _795 = _791 * atlas;\n    vec2 _799 = ddx * _795;\n    vec2 _803 = ddy * _795;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _791), clamp(0.5 * log2(max(max(dot(_799, _799), dot(_803, _803)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _838 = fa_mesh_fs_params[10].y < 0.5;\n    bool _845;\n    if (!_838)\n    {\n        _845 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _845 = _838;\n    }\n    if (_845)\n    {\n        return;\n    }\n    vec3 _851 = dFdx(world_pos);\n    vec3 _854 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _858 = fa_cluster_texel(param);\n    int _862 = int(_858.w);\n    if (_862 < 1)\n    {\n        return;\n    }\n    int _872 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _872;\n    vec4 _876 = fa_light_texel(param_1);\n    vec2 _879 = _876.yz;\n    int _883 = int(_876.w);\n    int param_2 = _872 + 1;\n    vec4 _888 = fa_light_texel(param_2);\n    float _889 = _888.x;\n    int _895 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _899 = int(_858.z);\n    vec3 _1165;\n    for (int k = 0; k < _862; k++)\n    {\n        int _912 = _899 + k;\n        int param_3 = _883 + (_912 >> 2);\n        int _930 = (_872 + 2) + (int(fa_light_texel(param_3)[_912 & 3]) * 7);\n        int param_4 = _930 + 6;\n        vec4 _935 = fa_light_texel(param_4);\n        if (((int(_935.w + 0.5) >> _895) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _930;\n        vec4 _950 = fa_light_texel(param_5);\n        int param_6 = _930 + 1;\n        vec4 _955 = fa_light_texel(param_6);\n        int param_7 = _930 + 2;\n        vec4 _960 = fa_light_texel(param_7);\n        vec3 _963 = _950.xyz;\n        float _968 = dot(_963, world_pos) + _950.w;\n        vec3 _970 = _955.xyz;\n        float _975 = dot(_970, world_pos) + _955.w;\n        vec3 _977 = _960.xyz;\n        float _982 = dot(_977, world_pos) + _960.w;\n        bool _987 = abs(_968) > 0.5;\n        bool _995;\n        if (!_987)\n        {\n            _995 = abs(_975) > 0.5;\n        }\n        else\n        {\n            _995 = _987;\n        }\n        bool _1003;\n        if (!_995)\n        {\n            _1003 = abs(_982) > 0.5;\n        }\n        else\n        {\n            _1003 = _995;\n        }\n        if (_1003)\n        {\n            continue;\n        }\n        float _1018 = clamp(dot(geo_normal, normalize(_977)) * _935.z, 0.0, 1.0);\n        if (_1018 <= 0.0)\n        {\n            continue;\n        }\n        float _1038 = (clamp((0.5 - abs(_982)) * 10.0, 0.0, 1.0) * _1018) * _935.x;\n        vec2 _1046 = vec2(_968 + 0.5, 0.5 - _975);\n        vec2 _1056 = vec2(dot(_963, _851), dot(_970, _851));\n        vec2 _1066 = vec2(dot(_963, _854), dot(_970, _854));\n        int param_8 = _930 + 5;\n        vec4 _1071 = fa_light_texel(param_8);\n        int param_9 = _930 + 3;\n        vec4 _1076 = fa_light_texel(param_9);\n        int param_10 = _930 + 4;\n        vec4 _1081 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1071.xyz;\n        bool _1091 = _1076.z > _1076.x;\n        if (_1091)\n        {\n            vec4 param_11 = _1076;\n            vec2 param_12 = _1046;\n            vec2 param_13 = _879;\n            vec2 param_14 = _1056;\n            vec2 param_15 = _1066;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_889 > 0.5) && (_889 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1117 = fa_dc_to_linear(param_16);\n                vec4 _4994 = tx;\n                _4994.x = _1117.x;\n                _4994.y = _1117.y;\n                _4994.z = _1117.z;\n                tx = _4994;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1038 * tex_a) * _1071.w, 0.0, 1.0)));\n        if (_1081.z > _1081.x)\n        {\n            vec4 param_17 = _1081;\n            vec2 param_18 = _1046;\n            vec2 param_19 = _879;\n            vec2 param_20 = _1056;\n            vec2 param_21 = _1066;\n            vec4 _1161 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_889 > 1.5)\n            {\n                vec3 param_22 = _1161.xyz;\n                vec3 _1171 = fa_dc_to_srgb(param_22);\n                _1165 = _1171;\n            }\n            else\n            {\n                _1165 = _1161.xyz;\n            }\n            vec3 _1181 = (_1165 * 2.0) - vec3(1.0);\n            vec2 _1186 = _1181.xy * _935.y;\n            vec3 _1208 = (normalize(_963) * _1186.x) + (normalize(_970) * _1186.y);\n            vec3 _1211 = normalize(normal);\n            normal = normalize(mix(_1211, normalize((_1211 * max(_1181.z, 0.0500000007450580596923828125)) + (_1208 - (_1211 * dot(_1211, _1208)))), vec3(clamp(_1038 * (_1091 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2671 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2678 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2681 = int(_2671);\n    int _2684 = int(_2678);\n    float _2694 = _2678 - float(_2684);\n    int _2749 = (_2681 * 9) + _2684;\n    int _2769 = ((_2681 + 1) * 9) + _2684;\n    return mix(mix(_2745[_2749], _2745[_2749 + 1], _2694), mix(_2745[_2769], _2745[_2769 + 1], _2694), _2671 - float(_2681));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4861 = false;\n    float _4862 = 1.0;\n    float _4863 = 1.0;\n    float _4864 = 1.0;\n    float _4865 = 0.0;\n    float _4866 = 0.0;\n    float _4867 = 0.0;\n    float _4868 = 0.0;\n    float _4870 = 1.0;\n    bool _4871 = false;\n    vec3 _4872 = vec3(0.0);\n    float _4873 = 1.0;\n    float _4874 = 1.0;\n    float _4875 = 1.0;\n    float _4876 = 0.0;\n    float _4877 = 0.0;\n    vec3 _4878 = vec3(1.0, 0.0, 0.0);\n    vec3 _4879 = vec3(0.0, 0.0, 1.0);\n    float _4880 = 1.0;\n    float _4881 = 1.0;\n    float _2822 = clamp(s.specular, 0.0, 1.0);\n    float _2826 = clamp(s.ior, 1.0, 3.0);\n    bool _2831 = (_2822 != 1.0) || (_2826 != 1.5);\n    bool _2841;\n    if (!_2831)\n    {\n        _2841 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2841 = _2831;\n    }\n    if (_2841)\n    {\n        float _2849 = (_2826 - 1.0) / (_2826 + 1.0);\n        f0 = mix(min(vec3(_2849 * _2849) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2822, s.albedo, vec3(metallic));\n        _4862 = mix(_2822, 1.0, metallic);\n        _4861 = true;\n    }\n    float _2877 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2877 > 0.0)\n    {\n        float _2885 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4865 = _2877;\n        _4866 = _2885;\n        float _2892 = _2885 * _2885;\n        _4867 = _2892;\n        _4868 = _2892 * _2892;\n        float _2904 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4870 = _2904;\n        _4863 = 1.0 - (_2877 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2904, 0.0, 1.0), 5.0))));\n        _4861 = true;\n    }\n    vec3 _2923 = max(s.sheen_color, vec3(0.0));\n    float _2932 = max(_2923.x, max(_2923.y, _2923.z));\n    if (_2932 > 0.0)\n    {\n        float _2940 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4871 = true;\n        _4872 = _2923;\n        _4873 = _2940;\n        _4874 = _2940 * _2940;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2940;\n        float _2957 = fa_sheen_albedo(param, param_1);\n        _4876 = _2957;\n        _4875 = 1.0 - min(_2932 * _2957, 1.0);\n        _4861 = true;\n    }\n    _4864 = _4863 * _4875;\n    float _2976 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2976 != 0.0)\n    {\n        vec3 _2991 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2991;\n        if (dot(_2991, _2991) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3004 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3004.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3004.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3004.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3008 = t;\n        vec3 _3009 = normalize(_3008);\n        t = _3009;\n        vec3 _3034 = normalize((_3009 * cos(s.anisotropy_rotation)) + ((cross(n, _3009) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4878 = _3034;\n        _4879 = cross(n, _3034);\n        float _3044 = roughness * roughness;\n        float _3050 = mix(_3044, 1.0, _2976 * _2976);\n        bool _3052 = _2976 > 0.0;\n        _4880 = _3052 ? _3050 : _3044;\n        _4881 = _3052 ? _3044 : _3050;\n        _4877 = _2976;\n        _4861 = true;\n    }\n    return FaLayers(_4861, _4862, _4863, _4864, _4865, _4866, _4867, _4868, i.world_normal, _4870, _4871, _4872, _4873, _4874, _4875, _4876, _4877, _4878, _4879, _4880, _4881);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2428 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2428;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _427 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _433 = fa_light_texel(param_1);\n    float _436 = _433.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _442 = _436 < 0.5;\n    vec3 l;\n    if (_442)\n    {\n        l = normalize(_427.xyz);\n    }\n    else\n    {\n        vec3 _454 = _427.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / vec3(max(_456, 9.9999997473787516355514526367188e-05));\n        float _471 = _456 / max(_427.w, 0.001000000047497451305389404296875);\n        float _477 = clamp(1.0 - (_471 * _471), 0.0, 1.0);\n        atten = _477 * _477;\n        if (_436 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _491 = fa_light_texel(param_2);\n            float _501 = _491.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _507 = fa_light_texel(param_3);\n            float _508 = _507.x;\n            float cos_inner = _508;\n            if (_508 > 1.5)\n            {\n                cos_inner = mix(_501, 1.0, 0.25);\n            }\n            atten *= smoothstep(_501, cos_inner, dot(-l, normalize(_491.xyz)));\n        }\n    }\n    int _539;\n    if (_442)\n    {\n        _539 = 0;\n    }\n    else\n    {\n        _539 = (_436 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _433.xyz * atten, atten, 1.0, dist, _539);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1283;\n    if (i == 0)\n    {\n        _1283 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1299;\n        if (i == 1)\n        {\n            _1299 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1307;\n            if (i == 2)\n            {\n                _1307 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1307 = fa_shadows[24].w;\n            }\n            _1299 = _1307;\n        }\n        _1283 = _1299;\n    }\n    return _1283;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1340 = fa_shadow_depth(param, param_1);\n    float _1344;\n    if (conv.x < 0.5)\n    {\n        _1344 = _1340;\n    }\n    else\n    {\n        _1344 = (conv.y * conv.z) / (conv.z - (_1340 * (conv.z - conv.y)));\n    }\n    return _1344;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1271 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1271), sin(_1271)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1390 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1404 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1390;\n            vec2 _1423 = fa_shadow_vogel(param_3, param_4, param_5) * _1404;\n            vec2 param_6 = uv + (_1423 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1435 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1435 < (zr - (length(_1423) * plane)))\n            {\n                sum += _1435;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1479 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1479; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1479;\n        float param_11 = _1390;\n        vec2 _1498 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1498 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1498) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1479);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1540 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1545 = clamp(dot(n, l), 0.0, 1.0);\n    float _1551 = sqrt(1.0 - (_1545 * _1545));\n    float _1558 = min(_1551 / max(_1545, 0.20000000298023223876953125), 4.0);\n    float _1563;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1563 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1563 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1588 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1563 * _1551)), 1.0);\n    float _1595 = _1588.x;\n    bool _1598 = _1595 < fa_shadows[ci * 1 + 16].x;\n    bool _1607;\n    if (!_1598)\n    {\n        _1607 = _1595 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1607 = _1598;\n    }\n    bool _1616;\n    if (!_1607)\n    {\n        _1616 = _1588.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1616 = _1607;\n    }\n    bool _1625;\n    if (!_1616)\n    {\n        _1625 = _1588.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = _1588.z > 1.0;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return -1.0;\n    }\n    float _1641;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1641 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1641 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1588.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1588.z - ((_1641 * (1.0 + (0.5 * _1558))) / _1540);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1540;\n    float param_5 = _1540 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1558, 3.0)) * 0.5) / _1540;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2068 = int(fa_shadows[25].x + 0.5);\n    if (_2068 < 1)\n    {\n        return 1.0;\n    }\n    float _2083 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2068 - 1;\n    if (_2083 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2095 = _2068 > 1;\n    bool _2102;\n    if (_2095)\n    {\n        _2102 = _2083 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2102 = _2095;\n    }\n    if (_2102)\n    {\n        ci = 1;\n    }\n    bool _2106 = _2068 > 2;\n    bool _2113;\n    if (_2106)\n    {\n        _2113 = _2083 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2113 = _2106;\n    }\n    if (_2113)\n    {\n        ci = 2;\n    }\n    bool _2117 = _2068 > 3;\n    bool _2124;\n    if (_2117)\n    {\n        _2124 = _2083 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2124 = _2117;\n    }\n    if (_2124)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2068)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2150 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2150;\n        if (_2150 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2175;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2175 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2175 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2194 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2175, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2205 = clamp((_2083 - (fa_shadow_split_at(param_7) - _2194)) / _2194, 0.0, 1.0);\n        if (_2205 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2068)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2226 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2226;\n                if (_2226 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2205);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1699 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1707;\n    if (!_1699)\n    {\n        _1707 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1707 = _1699;\n    }\n    if (_1707)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1720 = fa_light_texel(param);\n    float _1721 = _1720.x;\n    if (_1721 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1730 = int(_1721 + 0.5);\n    int param_1 = _1730;\n    vec4 _1734 = fa_light_texel(param_1);\n    int param_2 = _1730 + 1;\n    vec4 _1739 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1742 = _1734.y;\n    if (_1742 > 0.0)\n    {\n        float _1759 = 1.0 - smoothstep(0.75 * _1742, _1742, length(world - fa_shadows[27].xyz));\n        fade = _1759;\n        if (_1759 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1734.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1778 = world - fa_light_texel(param_3).xyz;\n        vec3 _1781 = abs(_1778);\n        float _1783 = _1781.x;\n        float _1785 = _1781.y;\n        bool _1786 = _1783 >= _1785;\n        bool _1794;\n        if (_1786)\n        {\n            _1794 = _1783 >= _1781.z;\n        }\n        else\n        {\n            _1794 = _1786;\n        }\n        int _1795;\n        if (_1794)\n        {\n            _1795 = (_1778.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1808;\n            if (_1785 >= _1781.z)\n            {\n                _1808 = (_1778.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1808 = (_1778.z > 0.0) ? 4 : 5;\n            }\n            _1795 = _1808;\n        }\n        face = _1795;\n    }\n    int _1827 = (_1730 + 2) + (face * 6);\n    int param_4 = _1827;\n    int param_5 = _1827 + 1;\n    int param_6 = _1827 + 3;\n    vec4 _1841 = fa_light_texel(param_6);\n    int param_7 = _1827 + 4;\n    vec4 _1846 = fa_light_texel(param_7);\n    int param_8 = _1827 + 5;\n    vec4 _1851 = fa_light_texel(param_8);\n    float _1863 = _1851.x * max(dot(_1841, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1868 = clamp(dot(n, l), 0.0, 1.0);\n    float _1891 = clamp(dot(n, _1841.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1914 = min(sqrt(1.0 - (_1891 * _1891)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1841, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1917 = _1739.y;\n    float _1919;\n    if (_1917 > 0.0)\n    {\n        _1919 = _1917;\n    }\n    else\n    {\n        _1919 = 1.5 * _1863;\n    }\n    vec4 _1939 = vec4(world + (n * (_1919 * sqrt(1.0 - (_1868 * _1868)))), 1.0);\n    float _1943 = dot(_1841, _1939);\n    float _1946 = _1851.y;\n    if (_1943 < _1946)\n    {\n        return 1.0;\n    }\n    vec2 _1961 = vec2(dot(fa_light_texel(param_4), _1939), dot(fa_light_texel(param_5), _1939)) / vec2(_1943);\n    float _1963 = _1961.x;\n    bool _1966 = _1963 < _1846.x;\n    bool _1975;\n    if (!_1966)\n    {\n        _1975 = _1963 > _1846.z;\n    }\n    else\n    {\n        _1975 = _1966;\n    }\n    bool _1984;\n    if (!_1975)\n    {\n        _1984 = _1961.y < _1846.y;\n    }\n    else\n    {\n        _1984 = _1975;\n    }\n    bool _1993;\n    if (!_1984)\n    {\n        _1993 = _1961.y > _1846.w;\n    }\n    else\n    {\n        _1993 = _1984;\n    }\n    if (_1993)\n    {\n        return 1.0;\n    }\n    float _1999 = _1739.x;\n    float _2001;\n    if (_1999 > 0.0)\n    {\n        _2001 = _1999;\n    }\n    else\n    {\n        _2001 = 1.5 * _1863;\n    }\n    vec2 param_10 = _1961;\n    vec4 param_11 = _1846;\n    float param_12 = _1943 - (_2001 * (1.0 + (0.5 * _1914)));\n    float param_13 = _1863;\n    float param_14 = 1.0;\n    float param_15 = _1851.z * 0.25;\n    float param_16 = (_1863 * min(_1914, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1946, _1851.z);\n    int param_18 = int(_1734.z + 0.5);\n    float param_19 = _1734.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3585 = fa_lm.z > 0.5;\n    bool _3591;\n    if (_3585)\n    {\n        int param = li;\n        _3591 = fa_light_baked(param);\n    }\n    else\n    {\n        _3591 = _3585;\n    }\n    if (_3591)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3613 = fa_light_sample(param_2, param_3);\n    vec3 _4923 = _3613.direction;\n    vec3 _4918 = _3613.color;\n    float _4925 = _3613.attenuation;\n    float _4920 = _3613.shadow;\n    int _4928 = _3613.type;\n    if ((_4928 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4923;\n        float _3627 = fa_shadow_factor(param_4, param_5);\n        _4920 = _3627;\n        _4918 *= _3627;\n    }\n    else\n    {\n        bool _3638 = _4928 != 0;\n        bool _3644;\n        if (_3638)\n        {\n            _3644 = _4925 > 0.0;\n        }\n        else\n        {\n            _3644 = _3638;\n        }\n        if (_3644)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4923;\n            float _3656 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4920 = _3656;\n            _4918 *= _3656;\n        }\n    }\n    return LightSample(_4923, _4918, _4925, _4920, _3613._distance, _4928);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3202 = tdh / at;\n    float _3206 = bdh / ab;\n    float _3218 = ((_3202 * _3202) + (_3206 * _3206)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3218) * _3218);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3299 = 1.0 / alpha;\n    return ((2.0 + _3299) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3299)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3331 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3410 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3410) * _3410);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3331);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3331));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3483 = max(dot(L.nc, l), 0.0);\n        float _3489 = max(dot(L.nc, h), 0.0);\n        float _3498 = ((_3489 * _3489) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3498) * _3498)) * (0.5 / max(mix((2.0 * _3483) * L.coat_ndv, _3483 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3483)) * _3483);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2603 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2606 = _2603.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2606 * _2606, exp2((-9.27999973297119140625) * ndv)) * _2606) + _2603.y)) + _2603.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2457 = rough * rough;\n    float _2487 = 0.60000002384185791015625 * _2457;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2457)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2487, 0.0500000007450580596923828125 + _2487, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2457 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3085;\n        if (L.aniso >= 0.0)\n        {\n            _3085 = L.b;\n        }\n        else\n        {\n            _3085 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3085, v), _3085), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3118 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3118.x) + (vec3(L.f90) * _3118.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3173 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3173.x) + _3173.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2645 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2645.x) + vec3(_2645.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2250 = int(fa_shadows[25].x + 0.5);\n    float _2260 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _2265 = _2250 > 0;\n    bool _2274;\n    if (_2265)\n    {\n        int param = _2250 - 1;\n        _2274 = _2260 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2274 = _2265;\n    }\n    if (_2274)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2281 = _2250 > 1;\n        bool _2288;\n        if (_2281)\n        {\n            _2288 = _2260 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2288 = _2281;\n        }\n        if (_2288)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2294 = _2250 > 2;\n        bool _2301;\n        if (_2294)\n        {\n            _2301 = _2260 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2301 = _2294;\n        }\n        if (_2301)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2307 = _2250 > 3;\n        bool _2314;\n        if (_2307)\n        {\n            _2314 = _2260 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2314 = _2307;\n        }\n        if (_2314)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4640 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4640 = -_4640;\n    }\n    vec3 _4065 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n    Surface _4073 = fa_standard_surface(param_1);\n    vec3 _4671 = _4073.albedo;\n    float _4672 = _4073.alpha;\n    vec3 _4673 = _4073.normal;\n    float _4674 = _4073.metallic;\n    float _4675 = _4073.roughness;\n    float _4676 = _4073.occlusion;\n    vec3 _4677 = _4073.emission;\n    float _4678 = _4073.clearcoat;\n    float _4679 = _4073.clearcoat_roughness;\n    vec3 _4680 = _4073.sheen_color;\n    float _4681 = _4073.sheen_roughness;\n    float _4682 = _4073.anisotropy;\n    float _4683 = _4073.anisotropy_rotation;\n    float _4684 = _4073.specular;\n    float _4685 = _4073.ior;\n    vec3 _4686 = _4073.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n    Surface param_3 = _4073;\n    surface(param_2, param_3);\n    _4671 = param_3.albedo;\n    _4672 = param_3.alpha;\n    _4673 = param_3.normal;\n    _4674 = param_3.metallic;\n    _4675 = param_3.roughness;\n    _4676 = param_3.occlusion;\n    _4677 = param_3.emission;\n    _4678 = param_3.clearcoat;\n    _4679 = param_3.clearcoat_roughness;\n    _4680 = param_3.sheen_color;\n    _4681 = param_3.sheen_roughness;\n    _4682 = param_3.anisotropy;\n    _4683 = param_3.anisotropy_rotation;\n    _4684 = param_3.specular;\n    _4685 = param_3.ior;\n    _4686 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4640;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4671 = param_6;\n    _4673 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4671;\n    }\n    else\n    {\n        vec3 _4112 = normalize(_4673);\n        float _4119 = clamp(_4674, 0.0, 1.0);\n        float _4123 = clamp(_4675, 0.0500000007450580596923828125, 1.0);\n        float _4127 = _4123 * _4123;\n        float _4131 = _4127 * _4127;\n        float _4136 = max(dot(_4112, _4065), 9.9999997473787516355514526367188e-05);\n        vec3 _4142 = _4671 * (1.0 - _4119);\n        vec3 _4149 = mix(vec3(0.039999999105930328369140625), _4671, vec3(_4119));\n        vec3 f0 = _4149;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n        Surface param_9 = Surface(_4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686);\n        vec3 param_10 = _4112;\n        vec3 param_11 = _4065;\n        float param_12 = _4119;\n        float param_13 = _4123;\n        vec3 param_14 = _4149;\n        FaLayers _4165 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _4112;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _4142) * _4676;\n        if (_4165.on)\n        {\n            lit *= _4165.base_scale;\n        }\n        int _4187 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4187; ln++)\n        {\n            int param_16 = ln;\n            int _4200 = fa_cl_light(param_16);\n            bool _4203 = fa_lm.z > 0.5;\n            bool _4209;\n            if (_4203)\n            {\n                int param_17 = _4200;\n                _4209 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4209 = _4203;\n            }\n            if (_4209)\n            {\n                continue;\n            }\n            int param_18 = _4200;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4640;\n            LightSample _4221 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _4845 = _4221.direction;\n            float _4229 = max(dot(_4112, _4845), 0.0);\n            float _4235 = _4221.attenuation * _4221.shadow;\n            vec3 _4240 = normalize(_4845 + _4065);\n            float _4245 = max(dot(_4112, _4240), 0.0);\n            float _4250 = max(dot(_4065, _4240), 0.0);\n            if (_4165.on)\n            {\n                FaLayers param_21 = _4165;\n                vec3 param_22 = _4142;\n                vec3 param_23 = f0;\n                vec3 param_24 = _4112;\n                vec3 param_25 = _4065;\n                vec3 param_26 = _4845;\n                vec3 param_27 = _4240;\n                float param_28 = _4229;\n                float param_29 = _4136;\n                float param_30 = _4245;\n                float param_31 = _4250;\n                float param_32 = _4127;\n                float param_33 = _4131;\n                int param_34 = _4200;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4235));\n            }\n            else\n            {\n                float _4298 = ((_4245 * _4245) * (_4131 - 1.0)) + 1.0;\n                int param_35 = _4200;\n                lit += (((_4142 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4250, 5.0))) * (((_4131 / ((3.1415927410125732421875 * _4298) * _4298)) * (0.5 / max(mix((2.0 * _4229) * _4136, _4229 + _4136, _4127), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4229))) * fa_light_rgb(param_35)) * (_4229 * _4235));\n            }\n        }\n        if (_4165.on)\n        {\n            FaLayers param_36 = _4165;\n            vec3 param_37 = _4112;\n            vec3 param_38 = _4065;\n            vec3 param_39 = f0;\n            float param_40 = _4123;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4676);\n        }\n        else\n        {\n            vec3 param_41 = _4112;\n            vec3 param_42 = _4065;\n            vec3 param_43 = f0;\n            float param_44 = _4123;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4676);\n        }\n        result = lit;\n    }\n    vec3 _4391 = result;\n    vec3 _4392 = _4391 + _4677;\n    result = _4392;\n    vec3 param_45 = _4392;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4401 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4408;\n    if (!_4401)\n    {\n        _4408 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4408 = _4401;\n    }\n    if (_4408)\n    {\n        vec3 _4417 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4423 = dot(_4417, fa_mesh_fs_params[9].xyz);\n        bool _4427 = fa_mesh_fs_params[9].w > 0.5;\n        float _4428;\n        if (_4427)\n        {\n            _4428 = _4423;\n        }\n        else\n        {\n            _4428 = length(_4417);\n        }\n        float _4440 = _4428 - fa_mesh_fs_params[8].x;\n        if (_4440 > 0.0)\n        {\n            float _4449 = fa_mesh_fs_params[7].w * _4440;\n            float tau = _4449 * _4449;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4465;\n                if (_4427)\n                {\n                    _4465 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4423);\n                }\n                else\n                {\n                    _4465 = fa_mesh_fs_params[0].y;\n                }\n                float _4486 = mix(_4465, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4428, 0.0, 1.0));\n                float _4490 = fa_world_pos.y - _4486;\n                float _4495 = _4486 - fa_mesh_fs_params[8].z;\n                float _4500 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4503 = _4495 <= 0.0;\n                bool _4504 = !_4503;\n                bool _4510;\n                if (_4504)\n                {\n                    _4510 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4510 = _4503;\n                }\n                float _4511;\n                if (_4510)\n                {\n                    _4511 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4511 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4495, 80.0));\n                }\n                bool _4538;\n                if (_4504)\n                {\n                    _4538 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4538 = _4503;\n                }\n                float _4539;\n                if (_4538)\n                {\n                    _4539 = fa_mesh_fs_params[8].y * _4495;\n                }\n                else\n                {\n                    _4539 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4495, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4564 = _4500 <= 0.0;\n                bool _4571;\n                if (!_4564)\n                {\n                    _4571 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4571 = _4564;\n                }\n                float _4572;\n                if (_4571)\n                {\n                    _4572 = fa_mesh_fs_params[8].y * _4500;\n                }\n                else\n                {\n                    _4572 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4500, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4599;\n                if (abs(_4490) < 0.001000000047497451305389404296875)\n                {\n                    _4599 = _4511;\n                }\n                else\n                {\n                    _4599 = (_4572 - _4539) / _4490;\n                }\n                tau += (_4440 * max(_4599, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4672);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
            "inst_name": "_553",
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
            "inst_name": "_1293",
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
            "inst_name": "_3681",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _2745[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _558 = fa_mesh_fs_params[19].x < 0.0;\n    bool _565;\n    if (!_558)\n    {\n        _565 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _565 = _558;\n    }\n    bool _573;\n    if (!_565)\n    {\n        _573 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _573 = _565;\n    }\n    bool _580;\n    if (!_573)\n    {\n        _580 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _580 = _573;\n    }\n    bool _587;\n    if (!_580)\n    {\n        _587 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _587 = _580;\n    }\n    if (_587)\n    {\n        return vec4(0.0);\n    }\n    vec4 _597 = vec4(world_pos, 1.0);\n    float _604 = dot(fa_mesh_fs_params[16], _597);\n    if (!(_604 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _626 = vec2(dot(fa_mesh_fs_params[14], _597), dot(fa_mesh_fs_params[15], _597)) / vec2(_604);\n    int _630 = int(fa_mesh_fs_params[18].x);\n    int _634 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _634) + clamp(int(floor(((_626.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _634 - 1)) * _630)) + clamp(int(floor(((_626.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _630 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _710 = fa_cluster_texel(param);\n    return ivec2(int(_710.x), int(_710.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3558 = fa_cluster_lookup(param);\n    fa_cl_slot = _3558.x;\n    fa_cl_local = _3558.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3733 = fa_linear_to_srgb(param);\n        c = _3733;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3741 = fa_srgb_to_linear(param_1);\n            c = _3741;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _309;\n    if (i.front_facing)\n    {\n        _309 = i.world_normal;\n    }\n    else\n    {\n        _309 = -i.world_normal;\n    }\n    vec3 _333 = normalize(i.world_tangent.xyz - (_309 * dot(_309, i.world_tangent.xyz)));\n    vec3 _360 = normalize(((_333 * m.x) + ((cross(_309, _333) * i.world_tangent.w) * m.y)) + (_309 * m.z));\n    vec3 _363;\n    if (i.front_facing)\n    {\n        _363 = _360;\n    }\n    else\n    {\n        _363 = -_360;\n    }\n    return _363;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3772 = fa_tex_fix(param_2, param_3);\n    vec4 _5071 = base_t;\n    _5071.x = _3772.x;\n    _5071.y = _3772.y;\n    _5071.z = _3772.z;\n    base_t = _5071;\n    vec4 _3786 = (_5071 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4938 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3818 = fa_tex_fix(param_6, param_7);\n        vec3 _3821 = (_3818 * 2.0) - vec3(1.0);\n        vec2 _3826 = _3821.xy * fa_mesh_fs_params[6].x;\n        vec3 _5079 = _3821;\n        _5079.x = _3826.x;\n        _5079.y = _3826.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5079;\n        _4938 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3855 = fa_tex_fix(param_12, param_13);\n    vec4 _5082 = mrt;\n    _5082.x = _3855.x;\n    _5082.y = _3855.y;\n    _5082.z = _3855.z;\n    mrt = _5082;\n    vec4 _3883 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3883.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3895 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3925 = fa_tex_fix(param_20, param_21);\n    float _4943 = fa_mesh_fs_params[20].x;\n    float _4944 = fa_mesh_fs_params[20].y;\n    float _4947 = fa_mesh_fs_params[20].z;\n    float _4946 = fa_mesh_fs_params[21].w;\n    float _4949 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4943 *= _3895.y;\n            _4944 *= _3895.z;\n            _4946 *= _3883.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4947 *= mrt.x;\n            _4949 *= mrt.w;\n        }\n    }\n    return Surface(_3786.xyz, _3786.w, _4938, clamp(fa_mesh_fs_params[5].x * _3855.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3855.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3895.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3925), _4943, _4944, fa_mesh_fs_params[21].xyz, _4946, _4947, fa_mesh_fs_params[20].w, _4949, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _791 = rect.zw - rect.xy;\n    vec2 _795 = _791 * atlas;\n    vec2 _799 = ddx * _795;\n    vec2 _803 = ddy * _795;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _791), clamp(0.5 * log2(max(max(dot(_799, _799), dot(_803, _803)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _838 = fa_mesh_fs_params[10].y < 0.5;\n    bool _845;\n    if (!_838)\n    {\n        _845 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _845 = _838;\n    }\n    if (_845)\n    {\n        return;\n    }\n    vec3 _851 = dFdx(world_pos);\n    vec3 _854 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _858 = fa_cluster_texel(param);\n    int _862 = int(_858.w);\n    if (_862 < 1)\n    {\n        return;\n    }\n    int _872 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _872;\n    vec4 _876 = fa_light_texel(param_1);\n    vec2 _879 = _876.yz;\n    int _883 = int(_876.w);\n    int param_2 = _872 + 1;\n    vec4 _888 = fa_light_texel(param_2);\n    float _889 = _888.x;\n    int _895 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _899 = int(_858.z);\n    vec3 _1165;\n    for (int k = 0; k < _862; k++)\n    {\n        int _912 = _899 + k;\n        int param_3 = _883 + (_912 >> 2);\n        int _930 = (_872 + 2) + (int(fa_light_texel(param_3)[_912 & 3]) * 7);\n        int param_4 = _930 + 6;\n        vec4 _935 = fa_light_texel(param_4);\n        if (((int(_935.w + 0.5) >> _895) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _930;\n        vec4 _950 = fa_light_texel(param_5);\n        int param_6 = _930 + 1;\n        vec4 _955 = fa_light_texel(param_6);\n        int param_7 = _930 + 2;\n        vec4 _960 = fa_light_texel(param_7);\n        vec3 _963 = _950.xyz;\n        float _968 = dot(_963, world_pos) + _950.w;\n        vec3 _970 = _955.xyz;\n        float _975 = dot(_970, world_pos) + _955.w;\n        vec3 _977 = _960.xyz;\n        float _982 = dot(_977, world_pos) + _960.w;\n        bool _987 = abs(_968) > 0.5;\n        bool _995;\n        if (!_987)\n        {\n            _995 = abs(_975) > 0.5;\n        }\n        else\n        {\n            _995 = _987;\n        }\n        bool _1003;\n        if (!_995)\n        {\n            _1003 = abs(_982) > 0.5;\n        }\n        else\n        {\n            _1003 = _995;\n        }\n        if (_1003)\n        {\n            continue;\n        }\n        float _1018 = clamp(dot(geo_normal, normalize(_977)) * _935.z, 0.0, 1.0);\n        if (_1018 <= 0.0)\n        {\n            continue;\n        }\n        float _1038 = (clamp((0.5 - abs(_982)) * 10.0, 0.0, 1.0) * _1018) * _935.x;\n        vec2 _1046 = vec2(_968 + 0.5, 0.5 - _975);\n        vec2 _1056 = vec2(dot(_963, _851), dot(_970, _851));\n        vec2 _1066 = vec2(dot(_963, _854), dot(_970, _854));\n        int param_8 = _930 + 5;\n        vec4 _1071 = fa_light_texel(param_8);\n        int param_9 = _930 + 3;\n        vec4 _1076 = fa_light_texel(param_9);\n        int param_10 = _930 + 4;\n        vec4 _1081 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1071.xyz;\n        bool _1091 = _1076.z > _1076.x;\n        if (_1091)\n        {\n            vec4 param_11 = _1076;\n            vec2 param_12 = _1046;\n            vec2 param_13 = _879;\n            vec2 param_14 = _1056;\n            vec2 param_15 = _1066;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_889 > 0.5) && (_889 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1117 = fa_dc_to_linear(param_16);\n                vec4 _4994 = tx;\n                _4994.x = _1117.x;\n                _4994.y = _1117.y;\n                _4994.z = _1117.z;\n                tx = _4994;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1038 * tex_a) * _1071.w, 0.0, 1.0)));\n        if (_1081.z > _1081.x)\n        {\n            vec4 param_17 = _1081;\n            vec2 param_18 = _1046;\n            vec2 param_19 = _879;\n            vec2 param_20 = _1056;\n            vec2 param_21 = _1066;\n            vec4 _1161 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_889 > 1.5)\n            {\n                vec3 param_22 = _1161.xyz;\n                vec3 _1171 = fa_dc_to_srgb(param_22);\n                _1165 = _1171;\n            }\n            else\n            {\n                _1165 = _1161.xyz;\n            }\n            vec3 _1181 = (_1165 * 2.0) - vec3(1.0);\n            vec2 _1186 = _1181.xy * _935.y;\n            vec3 _1208 = (normalize(_963) * _1186.x) + (normalize(_970) * _1186.y);\n            vec3 _1211 = normalize(normal);\n            normal = normalize(mix(_1211, normalize((_1211 * max(_1181.z, 0.0500000007450580596923828125)) + (_1208 - (_1211 * dot(_1211, _1208)))), vec3(clamp(_1038 * (_1091 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _2671 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _2678 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _2681 = int(_2671);\n    int _2684 = int(_2678);\n    float _2694 = _2678 - float(_2684);\n    int _2749 = (_2681 * 9) + _2684;\n    int _2769 = ((_2681 + 1) * 9) + _2684;\n    return mix(mix(_2745[_2749], _2745[_2749 + 1], _2694), mix(_2745[_2769], _2745[_2769 + 1], _2694), _2671 - float(_2681));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _4861 = false;\n    float _4862 = 1.0;\n    float _4863 = 1.0;\n    float _4864 = 1.0;\n    float _4865 = 0.0;\n    float _4866 = 0.0;\n    float _4867 = 0.0;\n    float _4868 = 0.0;\n    float _4870 = 1.0;\n    bool _4871 = false;\n    vec3 _4872 = vec3(0.0);\n    float _4873 = 1.0;\n    float _4874 = 1.0;\n    float _4875 = 1.0;\n    float _4876 = 0.0;\n    float _4877 = 0.0;\n    vec3 _4878 = vec3(1.0, 0.0, 0.0);\n    vec3 _4879 = vec3(0.0, 0.0, 1.0);\n    float _4880 = 1.0;\n    float _4881 = 1.0;\n    float _2822 = clamp(s.specular, 0.0, 1.0);\n    float _2826 = clamp(s.ior, 1.0, 3.0);\n    bool _2831 = (_2822 != 1.0) || (_2826 != 1.5);\n    bool _2841;\n    if (!_2831)\n    {\n        _2841 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2841 = _2831;\n    }\n    if (_2841)\n    {\n        float _2849 = (_2826 - 1.0) / (_2826 + 1.0);\n        f0 = mix(min(vec3(_2849 * _2849) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2822, s.albedo, vec3(metallic));\n        _4862 = mix(_2822, 1.0, metallic);\n        _4861 = true;\n    }\n    float _2877 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2877 > 0.0)\n    {\n        float _2885 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _4865 = _2877;\n        _4866 = _2885;\n        float _2892 = _2885 * _2885;\n        _4867 = _2892;\n        _4868 = _2892 * _2892;\n        float _2904 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _4870 = _2904;\n        _4863 = 1.0 - (_2877 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2904, 0.0, 1.0), 5.0))));\n        _4861 = true;\n    }\n    vec3 _2923 = max(s.sheen_color, vec3(0.0));\n    float _2932 = max(_2923.x, max(_2923.y, _2923.z));\n    if (_2932 > 0.0)\n    {\n        float _2940 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _4871 = true;\n        _4872 = _2923;\n        _4873 = _2940;\n        _4874 = _2940 * _2940;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2940;\n        float _2957 = fa_sheen_albedo(param, param_1);\n        _4876 = _2957;\n        _4875 = 1.0 - min(_2932 * _2957, 1.0);\n        _4861 = true;\n    }\n    _4864 = _4863 * _4875;\n    float _2976 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2976 != 0.0)\n    {\n        vec3 _2991 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2991;\n        if (dot(_2991, _2991) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3004 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3004.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3004.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3004.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3008 = t;\n        vec3 _3009 = normalize(_3008);\n        t = _3009;\n        vec3 _3034 = normalize((_3009 * cos(s.anisotropy_rotation)) + ((cross(n, _3009) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _4878 = _3034;\n        _4879 = cross(n, _3034);\n        float _3044 = roughness * roughness;\n        float _3050 = mix(_3044, 1.0, _2976 * _2976);\n        bool _3052 = _2976 > 0.0;\n        _4880 = _3052 ? _3050 : _3044;\n        _4881 = _3052 ? _3044 : _3050;\n        _4877 = _2976;\n        _4861 = true;\n    }\n    return FaLayers(_4861, _4862, _4863, _4864, _4865, _4866, _4867, _4868, i.world_normal, _4870, _4871, _4872, _4873, _4874, _4875, _4876, _4877, _4878, _4879, _4880, _4881);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _2428 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _2428;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _427 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _433 = fa_light_texel(param_1);\n    float _436 = _433.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _442 = _436 < 0.5;\n    vec3 l;\n    if (_442)\n    {\n        l = normalize(_427.xyz);\n    }\n    else\n    {\n        vec3 _454 = _427.xyz - world_pos;\n        float _456 = length(_454);\n        dist = _456;\n        l = _454 / vec3(max(_456, 9.9999997473787516355514526367188e-05));\n        float _471 = _456 / max(_427.w, 0.001000000047497451305389404296875);\n        float _477 = clamp(1.0 - (_471 * _471), 0.0, 1.0);\n        atten = _477 * _477;\n        if (_436 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _491 = fa_light_texel(param_2);\n            float _501 = _491.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _507 = fa_light_texel(param_3);\n            float _508 = _507.x;\n            float cos_inner = _508;\n            if (_508 > 1.5)\n            {\n                cos_inner = mix(_501, 1.0, 0.25);\n            }\n            atten *= smoothstep(_501, cos_inner, dot(-l, normalize(_491.xyz)));\n        }\n    }\n    int _539;\n    if (_442)\n    {\n        _539 = 0;\n    }\n    else\n    {\n        _539 = (_436 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _433.xyz * atten, atten, 1.0, dist, _539);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1283;\n    if (i == 0)\n    {\n        _1283 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1299;\n        if (i == 1)\n        {\n            _1299 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1307;\n            if (i == 2)\n            {\n                _1307 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1307 = fa_shadows[24].w;\n            }\n            _1299 = _1307;\n        }\n        _1283 = _1299;\n    }\n    return _1283;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _1340 = fa_shadow_depth(param, param_1);\n    float _1344;\n    if (conv.x < 0.5)\n    {\n        _1344 = _1340;\n    }\n    else\n    {\n        _1344 = (conv.y * conv.z) / (conv.z - (_1340 * (conv.z - conv.y)));\n    }\n    return _1344;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1271 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1271), sin(_1271)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _1390 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _1404 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _1390;\n            vec2 _1423 = fa_shadow_vogel(param_3, param_4, param_5) * _1404;\n            vec2 param_6 = uv + (_1423 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _1435 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_1435 < (zr - (length(_1423) * plane)))\n            {\n                sum += _1435;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1479 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1479; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _1479;\n        float param_11 = _1390;\n        vec2 _1498 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_1498 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_1498) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_1479);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1540 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1545 = clamp(dot(n, l), 0.0, 1.0);\n    float _1551 = sqrt(1.0 - (_1545 * _1545));\n    float _1558 = min(_1551 / max(_1545, 0.20000000298023223876953125), 4.0);\n    float _1563;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1563 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1563 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1588 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1563 * _1551)), 1.0);\n    float _1595 = _1588.x;\n    bool _1598 = _1595 < fa_shadows[ci * 1 + 16].x;\n    bool _1607;\n    if (!_1598)\n    {\n        _1607 = _1595 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1607 = _1598;\n    }\n    bool _1616;\n    if (!_1607)\n    {\n        _1616 = _1588.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1616 = _1607;\n    }\n    bool _1625;\n    if (!_1616)\n    {\n        _1625 = _1588.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1625 = _1616;\n    }\n    bool _1632;\n    if (!_1625)\n    {\n        _1632 = _1588.z > 1.0;\n    }\n    else\n    {\n        _1632 = _1625;\n    }\n    if (_1632)\n    {\n        return -1.0;\n    }\n    float _1641;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1641 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1641 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _1588.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _1588.z - ((_1641 * (1.0 + (0.5 * _1558))) / _1540);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _1540;\n    float param_5 = _1540 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_1558, 3.0)) * 0.5) / _1540;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2068 = int(fa_shadows[25].x + 0.5);\n    if (_2068 < 1)\n    {\n        return 1.0;\n    }\n    float _2083 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2068 - 1;\n    if (_2083 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2095 = _2068 > 1;\n    bool _2102;\n    if (_2095)\n    {\n        _2102 = _2083 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2102 = _2095;\n    }\n    if (_2102)\n    {\n        ci = 1;\n    }\n    bool _2106 = _2068 > 2;\n    bool _2113;\n    if (_2106)\n    {\n        _2113 = _2083 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2113 = _2106;\n    }\n    if (_2113)\n    {\n        ci = 2;\n    }\n    bool _2117 = _2068 > 3;\n    bool _2124;\n    if (_2117)\n    {\n        _2124 = _2083 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2124 = _2117;\n    }\n    if (_2124)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2068)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2150 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2150;\n        if (_2150 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2175;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2175 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2175 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2194 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2175, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2205 = clamp((_2083 - (fa_shadow_split_at(param_7) - _2194)) / _2194, 0.0, 1.0);\n        if (_2205 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2068)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2226 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2226;\n                if (_2226 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2205);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1699 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1707;\n    if (!_1699)\n    {\n        _1707 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1707 = _1699;\n    }\n    if (_1707)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1720 = fa_light_texel(param);\n    float _1721 = _1720.x;\n    if (_1721 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1730 = int(_1721 + 0.5);\n    int param_1 = _1730;\n    vec4 _1734 = fa_light_texel(param_1);\n    int param_2 = _1730 + 1;\n    vec4 _1739 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1742 = _1734.y;\n    if (_1742 > 0.0)\n    {\n        float _1759 = 1.0 - smoothstep(0.75 * _1742, _1742, length(world - fa_shadows[27].xyz));\n        fade = _1759;\n        if (_1759 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1734.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1778 = world - fa_light_texel(param_3).xyz;\n        vec3 _1781 = abs(_1778);\n        float _1783 = _1781.x;\n        float _1785 = _1781.y;\n        bool _1786 = _1783 >= _1785;\n        bool _1794;\n        if (_1786)\n        {\n            _1794 = _1783 >= _1781.z;\n        }\n        else\n        {\n            _1794 = _1786;\n        }\n        int _1795;\n        if (_1794)\n        {\n            _1795 = (_1778.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1808;\n            if (_1785 >= _1781.z)\n            {\n                _1808 = (_1778.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1808 = (_1778.z > 0.0) ? 4 : 5;\n            }\n            _1795 = _1808;\n        }\n        face = _1795;\n    }\n    int _1827 = (_1730 + 2) + (face * 6);\n    int param_4 = _1827;\n    int param_5 = _1827 + 1;\n    int param_6 = _1827 + 3;\n    vec4 _1841 = fa_light_texel(param_6);\n    int param_7 = _1827 + 4;\n    vec4 _1846 = fa_light_texel(param_7);\n    int param_8 = _1827 + 5;\n    vec4 _1851 = fa_light_texel(param_8);\n    float _1863 = _1851.x * max(dot(_1841, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1868 = clamp(dot(n, l), 0.0, 1.0);\n    float _1891 = clamp(dot(n, _1841.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1914 = min(sqrt(1.0 - (_1891 * _1891)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1841, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1917 = _1739.y;\n    float _1919;\n    if (_1917 > 0.0)\n    {\n        _1919 = _1917;\n    }\n    else\n    {\n        _1919 = 1.5 * _1863;\n    }\n    vec4 _1939 = vec4(world + (n * (_1919 * sqrt(1.0 - (_1868 * _1868)))), 1.0);\n    float _1943 = dot(_1841, _1939);\n    float _1946 = _1851.y;\n    if (_1943 < _1946)\n    {\n        return 1.0;\n    }\n    vec2 _1961 = vec2(dot(fa_light_texel(param_4), _1939), dot(fa_light_texel(param_5), _1939)) / vec2(_1943);\n    float _1963 = _1961.x;\n    bool _1966 = _1963 < _1846.x;\n    bool _1975;\n    if (!_1966)\n    {\n        _1975 = _1963 > _1846.z;\n    }\n    else\n    {\n        _1975 = _1966;\n    }\n    bool _1984;\n    if (!_1975)\n    {\n        _1984 = _1961.y < _1846.y;\n    }\n    else\n    {\n        _1984 = _1975;\n    }\n    bool _1993;\n    if (!_1984)\n    {\n        _1993 = _1961.y > _1846.w;\n    }\n    else\n    {\n        _1993 = _1984;\n    }\n    if (_1993)\n    {\n        return 1.0;\n    }\n    float _1999 = _1739.x;\n    float _2001;\n    if (_1999 > 0.0)\n    {\n        _2001 = _1999;\n    }\n    else\n    {\n        _2001 = 1.5 * _1863;\n    }\n    vec2 param_10 = _1961;\n    vec4 param_11 = _1846;\n    float param_12 = _1943 - (_2001 * (1.0 + (0.5 * _1914)));\n    float param_13 = _1863;\n    float param_14 = 1.0;\n    float param_15 = _1851.z * 0.25;\n    float param_16 = (_1863 * min(_1914, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1946, _1851.z);\n    int param_18 = int(_1734.z + 0.5);\n    float param_19 = _1734.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _3585 = fa_lm.z > 0.5;\n    bool _3591;\n    if (_3585)\n    {\n        int param = li;\n        _3591 = fa_light_baked(param);\n    }\n    else\n    {\n        _3591 = _3585;\n    }\n    if (_3591)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _3613 = fa_light_sample(param_2, param_3);\n    vec3 _4923 = _3613.direction;\n    vec3 _4918 = _3613.color;\n    float _4925 = _3613.attenuation;\n    float _4920 = _3613.shadow;\n    int _4928 = _3613.type;\n    if ((_4928 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _4923;\n        float _3627 = fa_shadow_factor(param_4, param_5);\n        _4920 = _3627;\n        _4918 *= _3627;\n    }\n    else\n    {\n        bool _3638 = _4928 != 0;\n        bool _3644;\n        if (_3638)\n        {\n            _3644 = _4925 > 0.0;\n        }\n        else\n        {\n            _3644 = _3638;\n        }\n        if (_3644)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _4923;\n            float _3656 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _4920 = _3656;\n            _4918 *= _3656;\n        }\n    }\n    return LightSample(_4923, _4918, _4925, _4920, _3613._distance, _4928);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _3202 = tdh / at;\n    float _3206 = bdh / ab;\n    float _3218 = ((_3202 * _3202) + (_3206 * _3206)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _3218) * _3218);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _3299 = 1.0 / alpha;\n    return ((2.0 + _3299) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _3299)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _3331 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _3410 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _3410) * _3410);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _3331);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _3331));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _3483 = max(dot(L.nc, l), 0.0);\n        float _3489 = max(dot(L.nc, h), 0.0);\n        float _3498 = ((_3489 * _3489) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _3498) * _3498)) * (0.5 / max(mix((2.0 * _3483) * L.coat_ndv, _3483 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3483)) * _3483);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _2603 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _2606 = _2603.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_2606 * _2606, exp2((-9.27999973297119140625) * ndv)) * _2606) + _2603.y)) + _2603.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _2457 = rough * rough;\n    float _2487 = 0.60000002384185791015625 * _2457;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _2457)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _2487, 0.0500000007450580596923828125 + _2487, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_2457 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3085;\n        if (L.aniso >= 0.0)\n        {\n            _3085 = L.b;\n        }\n        else\n        {\n            _3085 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3085, v), _3085), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3118 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3118.x) + (vec3(L.f90) * _3118.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3173 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3173.x) + _3173.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2645 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _2645.x) + vec3(_2645.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2250 = int(fa_shadows[25].x + 0.5);\n    float _2260 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _2265 = _2250 > 0;\n    bool _2274;\n    if (_2265)\n    {\n        int param = _2250 - 1;\n        _2274 = _2260 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _2274 = _2265;\n    }\n    if (_2274)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _2281 = _2250 > 1;\n        bool _2288;\n        if (_2281)\n        {\n            _2288 = _2260 > fa_shadows[24].x;\n        }\n        else\n        {\n            _2288 = _2281;\n        }\n        if (_2288)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _2294 = _2250 > 2;\n        bool _2301;\n        if (_2294)\n        {\n            _2301 = _2260 > fa_shadows[24].y;\n        }\n        else\n        {\n            _2301 = _2294;\n        }\n        if (_2301)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _2307 = _2250 > 3;\n        bool _2314;\n        if (_2307)\n        {\n            _2314 = _2260 > fa_shadows[24].z;\n        }\n        else\n        {\n            _2314 = _2307;\n        }\n        if (_2314)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4640 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4640 = -_4640;\n    }\n    vec3 _4065 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n    Surface _4073 = fa_standard_surface(param_1);\n    vec3 _4671 = _4073.albedo;\n    float _4672 = _4073.alpha;\n    vec3 _4673 = _4073.normal;\n    float _4674 = _4073.metallic;\n    float _4675 = _4073.roughness;\n    float _4676 = _4073.occlusion;\n    vec3 _4677 = _4073.emission;\n    float _4678 = _4073.clearcoat;\n    float _4679 = _4073.clearcoat_roughness;\n    vec3 _4680 = _4073.sheen_color;\n    float _4681 = _4073.sheen_roughness;\n    float _4682 = _4073.anisotropy;\n    float _4683 = _4073.anisotropy_rotation;\n    float _4684 = _4073.specular;\n    float _4685 = _4073.ior;\n    vec3 _4686 = _4073.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n    Surface param_3 = _4073;\n    surface(param_2, param_3);\n    _4671 = param_3.albedo;\n    _4672 = param_3.alpha;\n    _4673 = param_3.normal;\n    _4674 = param_3.metallic;\n    _4675 = param_3.roughness;\n    _4676 = param_3.occlusion;\n    _4677 = param_3.emission;\n    _4678 = param_3.clearcoat;\n    _4679 = param_3.clearcoat_roughness;\n    _4680 = param_3.sheen_color;\n    _4681 = param_3.sheen_roughness;\n    _4682 = param_3.anisotropy;\n    _4683 = param_3.anisotropy_rotation;\n    _4684 = param_3.specular;\n    _4685 = param_3.ior;\n    _4686 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4640;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4671 = param_6;\n    _4673 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4671;\n    }\n    else\n    {\n        vec3 _4112 = normalize(_4673);\n        float _4119 = clamp(_4674, 0.0, 1.0);\n        float _4123 = clamp(_4675, 0.0500000007450580596923828125, 1.0);\n        float _4127 = _4123 * _4123;\n        float _4131 = _4127 * _4127;\n        float _4136 = max(dot(_4112, _4065), 9.9999997473787516355514526367188e-05);\n        vec3 _4142 = _4671 * (1.0 - _4119);\n        vec3 _4149 = mix(vec3(0.039999999105930328369140625), _4671, vec3(_4119));\n        vec3 f0 = _4149;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _4640, fa_world_tangent, fa_uv, fa_vertex_color, _4065, gl_FrontFacing);\n        Surface param_9 = Surface(_4671, _4672, _4673, _4674, _4675, _4676, _4677, _4678, _4679, _4680, _4681, _4682, _4683, _4684, _4685, _4686);\n        vec3 param_10 = _4112;\n        vec3 param_11 = _4065;\n        float param_12 = _4119;\n        float param_13 = _4123;\n        vec3 param_14 = _4149;\n        FaLayers _4165 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _4112;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _4142) * _4676;\n        if (_4165.on)\n        {\n            lit *= _4165.base_scale;\n        }\n        int _4187 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4187; ln++)\n        {\n            int param_16 = ln;\n            int _4200 = fa_cl_light(param_16);\n            bool _4203 = fa_lm.z > 0.5;\n            bool _4209;\n            if (_4203)\n            {\n                int param_17 = _4200;\n                _4209 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _4209 = _4203;\n            }\n            if (_4209)\n            {\n                continue;\n            }\n            int param_18 = _4200;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _4640;\n            LightSample _4221 = fa_light_shadowed(param_18, param_19, param_20);\n            vec3 _4845 = _4221.direction;\n            float _4229 = max(dot(_4112, _4845), 0.0);\n            float _4235 = _4221.attenuation * _4221.shadow;\n            vec3 _4240 = normalize(_4845 + _4065);\n            float _4245 = max(dot(_4112, _4240), 0.0);\n            float _4250 = max(dot(_4065, _4240), 0.0);\n            if (_4165.on)\n            {\n                FaLayers param_21 = _4165;\n                vec3 param_22 = _4142;\n                vec3 param_23 = f0;\n                vec3 param_24 = _4112;\n                vec3 param_25 = _4065;\n                vec3 param_26 = _4845;\n                vec3 param_27 = _4240;\n                float param_28 = _4229;\n                float param_29 = _4136;\n                float param_30 = _4245;\n                float param_31 = _4250;\n                float param_32 = _4127;\n                float param_33 = _4131;\n                int param_34 = _4200;\n                lit += (fa_layers_light(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30, param_31, param_32, param_33) * (fa_light_rgb(param_34) * _4235));\n            }\n            else\n            {\n                float _4298 = ((_4245 * _4245) * (_4131 - 1.0)) + 1.0;\n                int param_35 = _4200;\n                lit += (((_4142 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _4250, 5.0))) * (((_4131 / ((3.1415927410125732421875 * _4298) * _4298)) * (0.5 / max(mix((2.0 * _4229) * _4136, _4229 + _4136, _4127), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4229))) * fa_light_rgb(param_35)) * (_4229 * _4235));\n            }\n        }\n        if (_4165.on)\n        {\n            FaLayers param_36 = _4165;\n            vec3 param_37 = _4112;\n            vec3 param_38 = _4065;\n            vec3 param_39 = f0;\n            float param_40 = _4123;\n            lit += (fa_layers_ibl(param_36, param_37, param_38, param_39, param_40) * _4676);\n        }\n        else\n        {\n            vec3 param_41 = _4112;\n            vec3 param_42 = _4065;\n            vec3 param_43 = f0;\n            float param_44 = _4123;\n            lit += (fa_sky_reflection(param_41, param_42, param_43, param_44) * _4676);\n        }\n        result = lit;\n    }\n    vec3 _4391 = result;\n    vec3 _4392 = _4391 + _4677;\n    result = _4392;\n    vec3 param_45 = _4392;\n    vec3 param_46 = fa_world_pos;\n    result = fa_shadow_debug(param_45, param_46);\n    bool _4401 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4408;\n    if (!_4401)\n    {\n        _4408 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4408 = _4401;\n    }\n    if (_4408)\n    {\n        vec3 _4417 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4423 = dot(_4417, fa_mesh_fs_params[9].xyz);\n        bool _4427 = fa_mesh_fs_params[9].w > 0.5;\n        float _4428;\n        if (_4427)\n        {\n            _4428 = _4423;\n        }\n        else\n        {\n            _4428 = length(_4417);\n        }\n        float _4440 = _4428 - fa_mesh_fs_params[8].x;\n        if (_4440 > 0.0)\n        {\n            float _4449 = fa_mesh_fs_params[7].w * _4440;\n            float tau = _4449 * _4449;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4465;\n                if (_4427)\n                {\n                    _4465 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4423);\n                }\n                else\n                {\n                    _4465 = fa_mesh_fs_params[0].y;\n                }\n                float _4486 = mix(_4465, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4428, 0.0, 1.0));\n                float _4490 = fa_world_pos.y - _4486;\n                float _4495 = _4486 - fa_mesh_fs_params[8].z;\n                float _4500 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4503 = _4495 <= 0.0;\n                bool _4504 = !_4503;\n                bool _4510;\n                if (_4504)\n                {\n                    _4510 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4510 = _4503;\n                }\n                float _4511;\n                if (_4510)\n                {\n                    _4511 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4511 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4495, 80.0));\n                }\n                bool _4538;\n                if (_4504)\n                {\n                    _4538 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4538 = _4503;\n                }\n                float _4539;\n                if (_4538)\n                {\n                    _4539 = fa_mesh_fs_params[8].y * _4495;\n                }\n                else\n                {\n                    _4539 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4495, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4564 = _4500 <= 0.0;\n                bool _4571;\n                if (!_4564)\n                {\n                    _4571 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4571 = _4564;\n                }\n                float _4572;\n                if (_4571)\n                {\n                    _4572 = fa_mesh_fs_params[8].y * _4500;\n                }\n                else\n                {\n                    _4572 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4500, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4599;\n                if (abs(_4490) < 0.001000000047497451305389404296875)\n                {\n                    _4599 = _4511;\n                }\n                else\n                {\n                    _4599 = (_4572 - _4539) / _4490;\n                }\n                tau += (_4440 * max(_4599, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4672);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_553",
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
            "inst_name": "_1293",
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
            "inst_name": "_3681",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    vec4 _280 = (_770 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _733 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = fa_mesh_fs_params[20].x;\n    float _739 = fa_mesh_fs_params[20].y;\n    float _742 = fa_mesh_fs_params[20].z;\n    float _741 = fa_mesh_fs_params[21].w;\n    float _744 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _733, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _738, _739, fa_mesh_fs_params[21].xyz, _741, _742, fa_mesh_fs_params[20].w, _744, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _644 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _303 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _310 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_303 * _310).z;\n    fa_pre_r0 = vec3(_303[0].x, _303[1].x, _303[2].x);\n    fa_pre_r1 = vec3(_303[0].y, _303[1].y, _303[2].y);\n    fa_pre_r2 = vec3(_303[0].z, _303[1].z, _303[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _310;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _770 = base_t;\n    _770.x = _264.x;\n    _770.y = _264.y;\n    _770.z = _264.z;\n    base_t = _770;\n    vec4 _280 = (_770 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _733 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _778 = _317;\n        _778.x = _322.x;\n        _778.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _778;\n        _733 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _781 = mrt;\n    _781.x = _351.x;\n    _781.y = _351.y;\n    _781.z = _351.z;\n    mrt = _781;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _738 = fa_mesh_fs_params[20].x;\n    float _739 = fa_mesh_fs_params[20].y;\n    float _742 = fa_mesh_fs_params[20].z;\n    float _741 = fa_mesh_fs_params[21].w;\n    float _744 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _738 *= _393.y;\n            _739 *= _393.z;\n            _741 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _742 *= mrt.x;\n            _744 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _733, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _738, _739, fa_mesh_fs_params[21].xyz, _741, _742, fa_mesh_fs_params[20].w, _744, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _644 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _644 = -_644;\n    }\n    vec3 _556 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _644, fa_world_tangent, fa_uv, fa_vertex_color, _556, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _571 = normalize(param_2.normal);\n    vec3 _586 = normalize(vec3(dot(fa_pre_r0, _571), dot(fa_pre_r1, _571), dot(fa_pre_r2, _571)));\n    float _598 = _586.z;\n    vec2 e = _586.xy / vec2((abs(_586.x) + abs(_586.y)) + abs(_598));\n    if (_598 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_187 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_187 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_187 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
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
