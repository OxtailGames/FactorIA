{
  "format": "factoria.shader/1",
  "engine": "0.39.0",
  "template": "4694fb4be9bed2a7c5475af904870ae4995eb283e1c27e15e0192dfe0c2b2256",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4942[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1613 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    bool _1628;\n    if (!_1620)\n    {\n        _1628 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1628 = _1620;\n    }\n    bool _1635;\n    if (!_1628)\n    {\n        _1635 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1635 = _1628;\n    }\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    if (_1642)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1652 = vec4(world_pos, 1.0);\n    float _1658 = dot(fa_mesh_fs_params[16], _1652);\n    if (!(_1658 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1680 = vec2(dot(fa_mesh_fs_params[14], _1652), dot(fa_mesh_fs_params[15], _1652)) / vec2(_1658);\n    int _1684 = int(fa_mesh_fs_params[18].x);\n    int _1688 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1688) + clamp(int(floor(((_1680.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1688 - 1)) * _1684)) + clamp(int(floor(((_1680.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1684 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1764 = fa_cluster_texel(param);\n    return ivec2(int(_1764.x), int(_1764.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6576 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6579 = fwidth(_6576);\n    bool _6582 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6589;\n    if (!_6582)\n    {\n        _6589 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6589 = _6582;\n    }\n    if (_6589)\n    {\n        fa_rt_slope = min(1.5 * _6579, 0.100000001490116119384765625 * _6576);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6605 = fa_cluster_lookup(param);\n    fa_cl_slot = _6605.x;\n    fa_cl_local = _6605.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7793 = fa_linear_to_srgb(param);\n        c = _7793;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7801 = fa_srgb_to_linear(param_1);\n            c = _7801;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _558;\n    if (i.front_facing)\n    {\n        _558 = i.world_normal;\n    }\n    else\n    {\n        _558 = -i.world_normal;\n    }\n    vec3 _582 = normalize(i.world_tangent.xyz - (_558 * dot(_558, i.world_tangent.xyz)));\n    vec3 _609 = normalize(((_582 * m.x) + ((cross(_558, _582) * i.world_tangent.w) * m.y)) + (_558 * m.z));\n    vec3 _612;\n    if (i.front_facing)\n    {\n        _612 = _609;\n    }\n    else\n    {\n        _612 = -_609;\n    }\n    return _612;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7833 = fa_tex_fix(param_2, param_3);\n    vec4 _10207 = base_t;\n    _10207.x = _7833.x;\n    _10207.y = _7833.y;\n    _10207.z = _7833.z;\n    base_t = _10207;\n    vec4 _7847 = (_10207 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9954 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7881 = fa_tex_fix(param_6, param_7);\n        vec3 _7884 = (_7881 * 2.0) - vec3(1.0);\n        vec2 _7889 = _7884.xy * fa_mesh_fs_params[6].x;\n        vec3 _10215 = _7884;\n        _10215.x = _7889.x;\n        _10215.y = _7889.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10215;\n        _9954 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7919 = fa_tex_fix(param_12, param_13);\n    vec4 _10218 = mrt;\n    _10218.x = _7919.x;\n    _10218.y = _7919.y;\n    _10218.z = _7919.z;\n    mrt = _10218;\n    vec4 _7949 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7949.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7960 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7992 = fa_tex_fix(param_20, param_21);\n    float _9959 = fa_mesh_fs_params[20].x;\n    float _9960 = fa_mesh_fs_params[20].y;\n    float _9963 = fa_mesh_fs_params[20].z;\n    float _9962 = fa_mesh_fs_params[21].w;\n    float _9965 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9959 *= _7960.y;\n            _9960 *= _7960.z;\n            _9962 *= _7949.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9963 *= mrt.x;\n            _9965 *= mrt.w;\n        }\n    }\n    return Surface(_7847.xyz, _7847.w, _9954, clamp(fa_mesh_fs_params[5].x * _7919.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7919.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7960.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7992), _9959, _9960, fa_mesh_fs_params[21].xyz, _9962, _9963, fa_mesh_fs_params[20].w, _9965, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1844 = rect.zw - rect.xy;\n    vec2 _1848 = _1844 * atlas;\n    vec2 _1852 = ddx * _1848;\n    vec2 _1856 = ddy * _1848;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1844), clamp(0.5 * log2(max(max(dot(_1852, _1852), dot(_1856, _1856)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1889 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1896;\n    if (!_1889)\n    {\n        _1896 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1896 = _1889;\n    }\n    if (_1896)\n    {\n        return;\n    }\n    vec3 _1902 = dFdx(world_pos);\n    vec3 _1905 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1909 = fa_cluster_texel(param);\n    int _1913 = int(_1909.w);\n    if (_1913 < 1)\n    {\n        return;\n    }\n    int _1923 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1923;\n    vec4 _1927 = fa_light_texel(param_1);\n    vec2 _1930 = _1927.yz;\n    int _1934 = int(_1927.w);\n    int param_2 = _1923 + 1;\n    vec4 _1939 = fa_light_texel(param_2);\n    float _1940 = _1939.x;\n    int _1946 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1950 = int(_1909.z);\n    vec3 _2215;\n    for (int k = 0; k < _1913; k++)\n    {\n        int _1963 = _1950 + k;\n        int param_3 = _1934 + (_1963 >> 2);\n        int _1980 = (_1923 + 2) + (int(fa_light_texel(param_3)[_1963 & 3]) * 7);\n        int param_4 = _1980 + 6;\n        vec4 _1985 = fa_light_texel(param_4);\n        if (((int(_1985.w + 0.5) >> _1946) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1980;\n        vec4 _2000 = fa_light_texel(param_5);\n        int param_6 = _1980 + 1;\n        vec4 _2005 = fa_light_texel(param_6);\n        int param_7 = _1980 + 2;\n        vec4 _2010 = fa_light_texel(param_7);\n        vec3 _2013 = _2000.xyz;\n        float _2018 = dot(_2013, world_pos) + _2000.w;\n        vec3 _2020 = _2005.xyz;\n        float _2025 = dot(_2020, world_pos) + _2005.w;\n        vec3 _2027 = _2010.xyz;\n        float _2032 = dot(_2027, world_pos) + _2010.w;\n        bool _2037 = abs(_2018) > 0.5;\n        bool _2045;\n        if (!_2037)\n        {\n            _2045 = abs(_2025) > 0.5;\n        }\n        else\n        {\n            _2045 = _2037;\n        }\n        bool _2053;\n        if (!_2045)\n        {\n            _2053 = abs(_2032) > 0.5;\n        }\n        else\n        {\n            _2053 = _2045;\n        }\n        if (_2053)\n        {\n            continue;\n        }\n        float _2068 = clamp(dot(geo_normal, normalize(_2027)) * _1985.z, 0.0, 1.0);\n        if (_2068 <= 0.0)\n        {\n            continue;\n        }\n        float _2088 = (clamp((0.5 - abs(_2032)) * 10.0, 0.0, 1.0) * _2068) * _1985.x;\n        vec2 _2096 = vec2(_2018 + 0.5, 0.5 - _2025);\n        vec2 _2106 = vec2(dot(_2013, _1902), dot(_2020, _1902));\n        vec2 _2116 = vec2(dot(_2013, _1905), dot(_2020, _1905));\n        int param_8 = _1980 + 5;\n        vec4 _2121 = fa_light_texel(param_8);\n        int param_9 = _1980 + 3;\n        vec4 _2126 = fa_light_texel(param_9);\n        int param_10 = _1980 + 4;\n        vec4 _2131 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2121.xyz;\n        bool _2141 = _2126.z > _2126.x;\n        if (_2141)\n        {\n            vec4 param_11 = _2126;\n            vec2 param_12 = _2096;\n            vec2 param_13 = _1930;\n            vec2 param_14 = _2106;\n            vec2 param_15 = _2116;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1940 > 0.5) && (_1940 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2167 = fa_dc_to_linear(param_16);\n                vec4 _10042 = tx;\n                _10042.x = _2167.x;\n                _10042.y = _2167.y;\n                _10042.z = _2167.z;\n                tx = _10042;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2088 * tex_a) * _2121.w, 0.0, 1.0)));\n        if (_2131.z > _2131.x)\n        {\n            vec4 param_17 = _2131;\n            vec2 param_18 = _2096;\n            vec2 param_19 = _1930;\n            vec2 param_20 = _2106;\n            vec2 param_21 = _2116;\n            vec4 _2211 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1940 > 1.5)\n            {\n                vec3 param_22 = _2211.xyz;\n                vec3 _2221 = fa_dc_to_srgb(param_22);\n                _2215 = _2221;\n            }\n            else\n            {\n                _2215 = _2211.xyz;\n            }\n            vec3 _2230 = (_2215 * 2.0) - vec3(1.0);\n            vec2 _2235 = _2230.xy * _1985.y;\n            vec3 _2257 = (normalize(_2013) * _2235.x) + (normalize(_2020) * _2235.y);\n            vec3 _2260 = normalize(normal);\n            normal = normalize(mix(_2260, normalize((_2260 * max(_2230.z, 0.0500000007450580596923828125)) + (_2257 - (_2260 * dot(_2260, _2257)))), vec3(clamp(_2088 * (_2141 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4867 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4875 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4878 = int(_4867);\n    int _4881 = int(_4875);\n    float _4891 = _4875 - float(_4881);\n    int _4946 = (_4878 * 9) + _4881;\n    int _4966 = ((_4878 + 1) * 9) + _4881;\n    return mix(mix(_4942[_4946], _4942[_4946 + 1], _4891), mix(_4942[_4966], _4942[_4966 + 1], _4891), _4867 - float(_4878));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9877 = false;\n    float _9878 = 1.0;\n    float _9879 = 1.0;\n    float _9880 = 1.0;\n    float _9881 = 0.0;\n    float _9882 = 0.0;\n    float _9883 = 0.0;\n    float _9884 = 0.0;\n    float _9886 = 1.0;\n    bool _9887 = false;\n    vec3 _9888 = vec3(0.0);\n    float _9889 = 1.0;\n    float _9890 = 1.0;\n    float _9891 = 1.0;\n    float _9892 = 0.0;\n    float _9893 = 0.0;\n    vec3 _9894 = vec3(1.0, 0.0, 0.0);\n    vec3 _9895 = vec3(0.0, 0.0, 1.0);\n    float _9896 = 1.0;\n    float _9897 = 1.0;\n    float _5017 = clamp(s.specular, 0.0, 1.0);\n    float _5021 = clamp(s.ior, 1.0, 3.0);\n    bool _5026 = (_5017 != 1.0) || (_5021 != 1.5);\n    bool _5035;\n    if (!_5026)\n    {\n        _5035 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _5035 = _5026;\n    }\n    if (_5035)\n    {\n        float _5043 = (_5021 - 1.0) / (_5021 + 1.0);\n        f0 = mix(min(vec3(_5043 * _5043) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _5017, s.albedo, vec3(metallic));\n        _9878 = mix(_5017, 1.0, metallic);\n        _9877 = true;\n    }\n    float _5070 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_5070 > 0.0)\n    {\n        float _5078 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9881 = _5070;\n        _9882 = _5078;\n        float _5085 = _5078 * _5078;\n        _9883 = _5085;\n        _9884 = _5085 * _5085;\n        float _5097 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9886 = _5097;\n        _9879 = 1.0 - (_5070 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5097, 0.0, 1.0), 5.0))));\n        _9877 = true;\n    }\n    vec3 _5116 = max(s.sheen_color, vec3(0.0));\n    float _5125 = max(_5116.x, max(_5116.y, _5116.z));\n    if (_5125 > 0.0)\n    {\n        float _5133 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9887 = true;\n        _9888 = _5116;\n        _9889 = _5133;\n        _9890 = _5133 * _5133;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5133;\n        float _5150 = fa_sheen_albedo(param, param_1);\n        _9892 = _5150;\n        _9891 = 1.0 - min(_5125 * _5150, 1.0);\n        _9877 = true;\n    }\n    _9880 = _9879 * _9891;\n    float _5169 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5169 != 0.0)\n    {\n        vec3 _5184 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5184;\n        if (dot(_5184, _5184) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5196 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5196.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5196.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5196.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5200 = t;\n        vec3 _5201 = normalize(_5200);\n        t = _5201;\n        vec3 _5226 = normalize((_5201 * cos(s.anisotropy_rotation)) + ((cross(n, _5201) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9894 = _5226;\n        _9895 = cross(n, _5226);\n        float _5236 = roughness * roughness;\n        float _5242 = mix(_5236, 1.0, _5169 * _5169);\n        bool _5244 = _5169 > 0.0;\n        _9896 = _5244 ? _5242 : _5236;\n        _9897 = _5244 ? _5236 : _5242;\n        _9893 = _5169;\n        _9877 = true;\n    }\n    return FaLayers(_9877, _9878, _9879, _9880, _9881, _9882, _9883, _9884, i.world_normal, _9886, _9887, _9888, _9889, _9890, _9891, _9892, _9893, _9894, _9895, _9896, _9897);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _4037 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _4037;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4648 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4653 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4648 > 0.0005000000237487256526947021484375)\n    {\n        if (_4653)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4648;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4648;\n        }\n    }\n    bool _4704 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4704)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4735 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4735)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4653 || _4704) || _4735)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _4057 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _4060 = _4057.x;\n    float _4062 = _4057.z;\n    vec2 e = vec2(_4060, _4062);\n    if (_4057.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_4062)) * ((_4060 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_4060)) * ((_4062 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _8102 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _8107 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _8112 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _8117 = fa_light_texel(param_3);\n    bool _8120 = _8117.z < 0.5;\n    bool _8128;\n    if (!_8120)\n    {\n        _8128 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8128 = _8120;\n    }\n    if (_8128)\n    {\n        return vec3(0.0);\n    }\n    float _8135 = max(_8102.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8138 = _8107.xyz;\n    vec3 _8142 = _8102.xyz;\n    vec3 _8146 = (fa_world_pos - _8142) / vec3(_8135);\n    vec3 _8155 = min(_8146 + vec3(0.5), (_8138 - vec3(0.5)) - _8146);\n    float _8164 = min(_8155.x, min(_8155.y, _8155.z));\n    if (!(_8164 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8179 = _8138 - vec3(1.0);\n    vec3 _8180 = clamp(_8146, vec3(0.0), _8179);\n    vec3 _8188 = min(floor(_8180), max(_8138 - vec3(2.0), vec3(0.0)));\n    vec3 _8192 = _8180 - _8188;\n    vec3 _8203 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8135));\n    int _8208 = int(_8112.y + 0.5);\n    float _8213 = 0.3257350027561187744140625 * n.y;\n    float _8217 = 0.3257350027561187744140625 * n.z;\n    float _8221 = 0.3257350027561187744140625 * n.x;\n    float _8228 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8235 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8244 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8251 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8264 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8271 = 8 + int(_8117.w);\n    float _8298;\n    float _8311;\n    float _8325;\n    for (int k = 0; k < _8271; k++)\n    {\n        float _8284 = float(k & 1);\n        float _8288 = float((k >> 1) & 1);\n        float _8292 = float((k >> 2) & 1);\n        if (_8284 > 0.5)\n        {\n            _8298 = _8192.x;\n        }\n        else\n        {\n            _8298 = 1.0 - _8192.x;\n        }\n        if (_8288 > 0.5)\n        {\n            _8311 = _8192.y;\n        }\n        else\n        {\n            _8311 = 1.0 - _8192.y;\n        }\n        if (_8292 > 0.5)\n        {\n            _8325 = _8192.z;\n        }\n        else\n        {\n            _8325 = 1.0 - _8192.z;\n        }\n        float _8335 = (_8298 * _8311) * _8325;\n        if (!(_8335 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8348 = min(_8188 + vec3(_8284, _8288, _8292), _8179);\n        int _8368 = int(((_8112.x + _8348.x) + (_8107.x * (_8348.y + (_8107.y * _8348.z)))) + 0.5);\n        vec2 _8383 = vec2(float(_8368 % _8208) * 10.0, 1024.0 + (float(_8368 / _8208) * 11.0));\n        vec2 param_4 = _8383 + vec2(9.5, 10.5);\n        vec4 _8391 = fa_gi_fetch(param_4);\n        bool _8394 = _8391.y < 0.5;\n        bool _8403;\n        if (!_8394)\n        {\n            _8403 = _8391.x > _8117.y;\n        }\n        else\n        {\n            _8403 = _8394;\n        }\n        if (_8403)\n        {\n            continue;\n        }\n        vec3 _8415 = _8203 - (_8142 + (_8348 * _8135));\n        float _8418 = length(_8415);\n        vec3 _8424 = _8415 / vec3(max(_8418, 9.9999997473787516355514526367188e-05));\n        float _8434 = max(9.9999997473787516355514526367188e-05, (dot(-_8424, n) + 1.0) * 0.5);\n        float w = _8335 * (_8434 * _8434);\n        vec3 param_5 = _8424;\n        vec2 param_6 = (_8383 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8453 = fa_gi_fetch(param_6);\n        float _8460 = _8418 / max(_8112.z, 9.9999997473787516355514526367188e-05);\n        float _8463 = _8453.x;\n        if (_8460 > _8463)\n        {\n            float _8476 = max(_8453.y - (_8463 * _8463), 0.0);\n            float _8481 = _8460 - _8463;\n            float _8490 = _8476 / max(_8476 + (_8481 * _8481), 9.9999999600419720025001879548654e-13);\n            w *= ((_8490 * _8490) * _8490);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8383 + vec2(0.5, 10.5);\n        vec2 param_8 = _8383 + vec2(1.5, 10.5);\n        vec2 param_9 = _8383 + vec2(2.5, 10.5);\n        vec2 param_10 = _8383 + vec2(3.5, 10.5);\n        vec2 param_11 = _8383 + vec2(4.5, 10.5);\n        vec2 param_12 = _8383 + vec2(5.5, 10.5);\n        vec2 param_13 = _8383 + vec2(6.5, 10.5);\n        vec2 param_14 = _8383 + vec2(7.5, 10.5);\n        vec2 param_15 = _8383 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8213)) + (fa_gi_fetch(param_9).xyz * _8217)) + (fa_gi_fetch(param_10).xyz * _8221)) + (fa_gi_fetch(param_11).xyz * _8228)) + (fa_gi_fetch(param_12).xyz * _8235)) + (fa_gi_fetch(param_13).xyz * _8244)) + (fa_gi_fetch(param_14).xyz * _8251)) + (fa_gi_fetch(param_15).xyz * _8264)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8164 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8615;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8615 = _8117.x;\n    }\n    else\n    {\n        _8615 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_8112.w * _8615);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8639 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8644 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8649 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8649) && (k < 8); k++)\n    {\n        int param = _8644 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8639;\n        vec3 _8674 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8679 = param_3 * left;\n        acc += (_8674 * _8679);\n        left -= _8679;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8708 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8708;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8750 = vec4(fa_world_pos, 1.0);\n        vec2 _8769 = vec2(dot(fa_mesh_fs_params[26], _8750), dot(fa_mesh_fs_params[27], _8750)) / vec2(max(dot(fa_mesh_fs_params[28], _8750), 9.9999997473787516355514526367188e-05));\n        float _8778;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8778 = (_8769.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8778 = 0.5 - (_8769.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8769.x * 0.5) + 0.5, _8778) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6546;\n    if (fa_lm.z > 0.5)\n    {\n        _6546 = 0.0;\n    }\n    else\n    {\n        _6546 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6557 = _6546 < 1.0;\n    bool _6563;\n    if (_6557)\n    {\n        int param = li;\n        _6563 = fa_light_baked(param);\n    }\n    else\n    {\n        _6563 = _6557;\n    }\n    return _6563 ? _6546 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _862 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _875 = (c - (ru * hx)) - p;\n        vec3 _881 = ru * (2.0 * hx);\n        float _887 = max(dot(_881, _881), 9.9999999392252902907785028219223e-09);\n        float _891 = dot(_875, _881);\n        float t = clamp((-_891) / _887, 0.0, 1.0);\n        if (_862)\n        {\n            float _906 = dot(r, _881);\n            float _912 = _887 - (_906 * _906);\n            if (abs(_912) > (9.9999997473787516355514526367188e-06 * _887))\n            {\n                t = clamp(((dot(r, _875) * _906) - _891) / _912, 0.0, 1.0);\n            }\n        }\n        return (p + _875) + (_881 * t);\n    }\n    vec3 q = p;\n    float _944 = dot(r, axis);\n    bool _952;\n    if (_862)\n    {\n        _952 = abs(_944) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _952 = _862;\n    }\n    if (_952)\n    {\n        float _962 = dot(c - p, axis) / _944;\n        if (_962 > 0.0)\n        {\n            q = p + (r * _962);\n        }\n    }\n    vec3 _975 = q - c;\n    vec2 xy = vec2(dot(_975, ru), dot(_975, uu));\n    if (shape > 0.5)\n    {\n        float _990 = length(xy);\n        if (_990 > hx)\n        {\n            xy *= (hx / _990);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _624 = abs(d);\n    float _626 = _624.x;\n    float _628 = _624.y;\n    bool _629 = _626 >= _628;\n    bool _637;\n    if (_629)\n    {\n        _637 = _626 >= _624.z;\n    }\n    else\n    {\n        _637 = _629;\n    }\n    int _638;\n    if (_637)\n    {\n        _638 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _652;\n        if (_628 >= _624.z)\n        {\n            _652 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _652 = (d.z > 0.0) ? 4 : 5;\n        }\n        _638 = _652;\n    }\n    return _638;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _782 = dot(d, right);\n    float _786 = dot(d, up);\n    float _797;\n    if (((_782 * _782) + (_786 * _786)) > 1.0000000133514319600180897396058e-10)\n    {\n        _797 = atan(_786, _782) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _797 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_797 - floor(_797)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1028 = fa_light_base(param);\n    bool _1032 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1028;\n    vec4 _1036 = fa_light_texel(param_1);\n    int param_2 = _1028 + 1;\n    vec4 _1041 = fa_light_texel(param_2);\n    float _1044 = _1041.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1056 = _1032 && (_1044 > 2.5);\n    fa_light_is_area = _1056;\n    bool _1058 = _1044 < 0.5;\n    vec3 l;\n    if (_1058)\n    {\n        l = normalize(_1036.xyz);\n        if (_1032)\n        {\n            int param_3 = _1028 + 6;\n            vec4 _1072 = fa_light_texel(param_3);\n            if (_1072.z > 0.5)\n            {\n                int param_4 = _1028 + 4;\n                vec4 _1082 = fa_light_texel(param_4);\n                int param_5 = _1028 + 5;\n                vec4 _1087 = fa_light_texel(param_5);\n                vec2 param_6 = _1072.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1082.xyz) * _1082.w, (-dot(world_pos, _1087.xyz)) * _1087.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1117 = _1036.xyz;\n        vec3 _1119 = _1117 - world_pos;\n        vec3 to_light = _1119;\n        float _1122 = length(_1119);\n        float reach = _1122;\n        bool front = true;\n        if (_1056)\n        {\n            int param_8 = _1028 + 7;\n            reach = max(_1122 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1028 + 4;\n            vec4 _1146 = fa_light_texel(param_9);\n            int param_10 = _1028 + 5;\n            vec4 _1151 = fa_light_texel(param_10);\n            int param_11 = _1028 + 6;\n            vec4 _1156 = fa_light_texel(param_11);\n            float _1157 = _1156.w;\n            int param_12 = _1028 + 2;\n            vec3 _1164 = normalize(fa_light_texel(param_12).xyz);\n            bool _1166 = _1157 > 1.5;\n            bool _1174;\n            if (!_1166)\n            {\n                _1174 = dot(_1164, to_light) < 0.0;\n            }\n            else\n            {\n                _1174 = _1166;\n            }\n            front = _1174;\n            vec3 r = vec3(0.0);\n            vec3 _1183 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1187 = dot(n, n) > 0.5;\n            bool _1195;\n            if (_1187)\n            {\n                _1195 = dot(_1183, _1183) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1195 = _1187;\n            }\n            if (_1195)\n            {\n                r = reflect(-normalize(_1183), normalize(n));\n            }\n            vec3 param_13 = _1117;\n            vec3 param_14 = _1164;\n            vec3 param_15 = _1146.xyz;\n            vec3 param_16 = _1151.xyz;\n            float param_17 = _1146.w;\n            float param_18 = _1151.w;\n            float param_19 = _1157;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1231 = length(to_light);\n        dist = _1231;\n        l = to_light / vec3(max(_1231, 9.9999997473787516355514526367188e-05));\n        float _1245 = reach / max(_1036.w, 0.001000000047497451305389404296875);\n        float _1251 = clamp(1.0 - (_1245 * _1245), 0.0, 1.0);\n        float _1253;\n        if (front)\n        {\n            _1253 = _1251 * _1251;\n        }\n        else\n        {\n            _1253 = 0.0;\n        }\n        atten = _1253;\n        bool _1264 = _1044 < 2.5;\n        if ((_1044 > 1.5) && _1264)\n        {\n            int param_22 = _1028 + 2;\n            vec4 _1272 = fa_light_texel(param_22);\n            float _1282 = _1272.w;\n            int param_23 = _1028 + 3;\n            vec4 _1287 = fa_light_texel(param_23);\n            float _1288 = _1287.x;\n            float cos_inner = _1288;\n            if (_1288 > 1.5)\n            {\n                cos_inner = mix(_1282, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1282, cos_inner, dot(-l, normalize(_1272.xyz)));\n        }\n        if (_1032 && (_1044 < 1.5))\n        {\n            int param_24 = _1028 + 6;\n            vec4 _1312 = fa_light_texel(param_24);\n            if (_1312.z > 0.5)\n            {\n                vec3 _1320 = -to_light;\n                int param_25 = _1028 + 4;\n                int param_26 = _1028 + 5;\n                vec3 _1334 = fa_light_texel(param_25).xyz;\n                vec3 _1338 = fa_light_texel(param_26).xyz;\n                vec3 _1347 = vec3(dot(_1320, _1334), dot(_1320, _1338), dot(_1320, cross(_1334, _1338)));\n                vec3 param_27 = _1347;\n                int _1351 = fa_cube_face(param_27);\n                int param_28 = _1351;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1378 = vec2(dot(_1347, cross(param_29, param_30)), dot(_1347, param_30)) / vec2(max(dot(_1347, param_29), 9.9999997473787516355514526367188e-05));\n                int _1382 = _1351 / 3;\n                vec2 param_31 = _1312.xy + (vec2(float(_1351 - (_1382 * 3)), float(_1382)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1378.x), 0.5 - (0.5 * _1378.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1028 + 7;\n            vec4 _1412 = fa_light_texel(param_33);\n            if (_1412.z > 0.5)\n            {\n                int param_34 = _1028 + 2;\n                int param_35 = _1028 + 4;\n                int param_36 = _1028 + 5;\n                vec2 param_37 = _1412.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1032 && _1264)\n            {\n                int param_42 = _1028 + 6;\n                vec4 _1459 = fa_light_texel(param_42);\n                int param_43 = _1028 + 7;\n                vec4 _1464 = fa_light_texel(param_43);\n                bool _1467 = _1459.z > 0.5;\n                bool _1474;\n                if (!_1467)\n                {\n                    _1474 = _1464.z > 0.5;\n                }\n                else\n                {\n                    _1474 = _1467;\n                }\n                if (_1474)\n                {\n                    int param_44 = _1028 + 2;\n                    vec4 _1481 = fa_light_texel(param_44);\n                    vec3 _1485 = normalize(_1481.xyz);\n                    int param_45 = _1028 + 4;\n                    vec4 _1490 = fa_light_texel(param_45);\n                    int param_46 = _1028 + 5;\n                    vec4 _1495 = fa_light_texel(param_46);\n                    if (_1467)\n                    {\n                        vec3 _1503 = -to_light;\n                        float _1510 = _1481.w;\n                        float _1526 = 0.5 / max(dot(_1503, _1485) * (sqrt(max(1.0 - (_1510 * _1510), 0.0)) / max(_1510, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1459.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1503, _1490.xyz) * _1526), 0.5 - (dot(_1503, _1495.xyz) * _1526));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1464.z > 0.5)\n                    {\n                        vec2 param_49 = _1464.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1485;\n                        vec3 param_52 = _1490.xyz;\n                        vec3 param_53 = _1495.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9865 = _1041.xyz * atten;\n    if (_1032)\n    {\n        _9865 *= fa_light_tint;\n    }\n    int _1595;\n    if (_1058)\n    {\n        _1595 = 0;\n    }\n    else\n    {\n        _1595 = ((_1044 > 1.5) && (_1044 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9865, atten, 1.0, dist, _1595);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2327;\n    if (i == 0)\n    {\n        _2327 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2343;\n        if (i == 1)\n        {\n            _2343 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2351;\n            if (i == 2)\n            {\n                _2351 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2351 = fa_shadows[24].w;\n            }\n            _2343 = _2351;\n        }\n        _2327 = _2343;\n    }\n    return _2327;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2384 = fa_shadow_depth(param, param_1);\n    float _2388;\n    if (conv.x < 0.5)\n    {\n        _2388 = _2384;\n    }\n    else\n    {\n        _2388 = (conv.y * conv.z) / (conv.z - (_2384 * (conv.z - conv.y)));\n    }\n    return _2388;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2434 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2440 = vec2(cos(_2434), sin(_2434));\n    vec2 dir = _2440;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2449;\n        if (k < 0.0)\n        {\n            _2449 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2449 = k;\n        }\n        float _2468 = clamp((_2449 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2487 = sqrt((float(i) + 0.5) * 0.0625) * _2468;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2487));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2501 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2501 < (zr - (_2487 * plane)))\n            {\n                sum += _2501;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2529 = sum / cnt;\n        float _2539;\n        if (k < 0.0)\n        {\n            _2539 = (-k) / max(_2529, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2539 = k;\n        }\n        radius = clamp(((max(zr - _2529, 0.0) * unit) * _2539) / texel_m, 1.5, 16.0);\n        dir = _2440;\n    }\n    float lit = 0.0;\n    int _2565 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2565; i_1++)\n    {\n        float _2584 = sqrt((float(i_1) + 0.5) / float(_2565)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2584));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2584 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2565);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2630 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2635 = clamp(dot(n, l), 0.0, 1.0);\n    float _2641 = sqrt(1.0 - (_2635 * _2635));\n    float _2649 = min(_2641 / max(_2635, 0.20000000298023223876953125), 4.0);\n    float _2654;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2654 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2654 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2679 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2654 * _2641)), 1.0);\n    float _2686 = _2679.x;\n    bool _2689 = _2686 < fa_shadows[ci * 1 + 16].x;\n    bool _2698;\n    if (!_2689)\n    {\n        _2698 = _2686 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2698 = _2689;\n    }\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2679.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2679.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2723;\n    if (!_2716)\n    {\n        _2723 = _2679.z > 1.0;\n    }\n    else\n    {\n        _2723 = _2716;\n    }\n    if (_2723)\n    {\n        return -1.0;\n    }\n    float _2731;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2731 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2731 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2679.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2679.z - ((_2731 * (1.0 + (0.5 * _2649))) / _2630);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2630;\n    float param_5 = _2630 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2649, 3.0)) * 0.5) / _2630;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3109 = int(fa_shadows[25].x + 0.5);\n    if (_3109 < 1)\n    {\n        return 1.0;\n    }\n    float _3124 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3109 - 1;\n    if (_3124 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3136 = _3109 > 1;\n    bool _3143;\n    if (_3136)\n    {\n        _3143 = _3124 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3143 = _3136;\n    }\n    if (_3143)\n    {\n        ci = 1;\n    }\n    bool _3147 = _3109 > 2;\n    bool _3154;\n    if (_3147)\n    {\n        _3154 = _3124 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3154 = _3147;\n    }\n    if (_3154)\n    {\n        ci = 2;\n    }\n    bool _3158 = _3109 > 3;\n    bool _3165;\n    if (_3158)\n    {\n        _3165 = _3124 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3165 = _3158;\n    }\n    if (_3165)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3176 = min(_3109, 4);\n    float _3217;\n    for (int c = ci; c < _3176; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3196 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3196;\n            break;\n        }\n        if (_3196 < 0.0)\n        {\n            continue;\n        }\n        s = _3196;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3217 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3217 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3236 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3217, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3124 - (fa_shadow_split_at(param_7) - _3236)) / _3236, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3268;\n        if ((ci + 1) < _3109)\n        {\n            _3268 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3268 = 1.0;\n        }\n        s = mix(s, _3268, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3373 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3379;\n    if (_3373)\n    {\n        _3379 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3379 = _3373;\n    }\n    if (_3379)\n    {\n        float _3393 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3401 = vec4(fa_world_pos, 1.0);\n        float _3407 = dot(fa_mesh_fs_params[28], _3401);\n        if (_3407 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3426 = vec2(dot(fa_mesh_fs_params[26], _3401), dot(fa_mesh_fs_params[27], _3401)) / vec2(_3407);\n            float _3431 = (_3426.x * 0.5) + 0.5;\n            float _3435;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3435 = (_3426.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3435 = 0.5 - (_3426.y * 0.5);\n            }\n            bool _3451 = _3431 >= 0.0;\n            bool _3457;\n            if (_3451)\n            {\n                _3457 = _3431 < 1.0;\n            }\n            else\n            {\n                _3457 = _3451;\n            }\n            bool _3463;\n            if (_3457)\n            {\n                _3463 = _3435 >= 0.0;\n            }\n            else\n            {\n                _3463 = _3457;\n            }\n            bool _3469;\n            if (_3463)\n            {\n                _3469 = _3435 < 1.0;\n            }\n            else\n            {\n                _3469 = _3463;\n            }\n            if (_3469)\n            {\n                vec4 _3494 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3431, _3435) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3497 = _3494.w > 0.5;\n                bool _3513;\n                if (_3497)\n                {\n                    _3513 = abs(_3393 - _3494.x) <= (((0.00200000009499490261077880859375 * _3393) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3513 = _3497;\n                }\n                if (_3513)\n                {\n                    float _3519;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3519 = min(_3494.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3519 = _3494.y;\n                    }\n                    return _3519;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3556 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3559 = _3556.w > 0.5;\n    bool _3569;\n    if (_3559)\n    {\n        _3569 = abs(d - _3556.x) <= tol;\n    }\n    else\n    {\n        _3569 = _3559;\n    }\n    if (_3569)\n    {\n        best = min(best, mod(floor(_3556.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2789 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2796;\n    if (!_2789)\n    {\n        _2796 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2796 = _2789;\n    }\n    if (_2796)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2809 = fa_light_texel(param);\n    float _2810 = _2809.x;\n    if (_2810 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2819 = int(_2810 + 0.5);\n    int param_1 = _2819;\n    vec4 _2823 = fa_light_texel(param_1);\n    int param_2 = _2819 + 1;\n    vec4 _2828 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2831 = _2823.y;\n    if (_2831 > 0.0)\n    {\n        float _2848 = 1.0 - smoothstep(0.75 * _2831, _2831, length(world - fa_shadows[27].xyz));\n        fade = _2848;\n        if (_2848 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2823.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2872 = (_2819 + 2) + (face * 6);\n    int param_4 = _2872;\n    int param_5 = _2872 + 1;\n    int param_6 = _2872 + 3;\n    vec4 _2886 = fa_light_texel(param_6);\n    int param_7 = _2872 + 4;\n    vec4 _2891 = fa_light_texel(param_7);\n    int param_8 = _2872 + 5;\n    vec4 _2896 = fa_light_texel(param_8);\n    float _2908 = _2896.x * max(dot(_2886, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2913 = clamp(dot(n, l), 0.0, 1.0);\n    float _2936 = clamp(dot(n, _2886.xyz), -1.0, 1.0);\n    float _2955 = min(sqrt(1.0 - (_2936 * _2936)) / max(abs(dot(n, world - lpos)) / max(dot(_2886, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2958 = _2828.y;\n    float _2960;\n    if (_2958 > 0.0)\n    {\n        _2960 = _2958;\n    }\n    else\n    {\n        _2960 = 1.5 * _2908;\n    }\n    vec4 _2980 = vec4(world + (n * (_2960 * sqrt(1.0 - (_2913 * _2913)))), 1.0);\n    float _2984 = dot(_2886, _2980);\n    float _2987 = _2896.y;\n    if (_2984 < _2987)\n    {\n        return 1.0;\n    }\n    vec2 _3002 = vec2(dot(fa_light_texel(param_4), _2980), dot(fa_light_texel(param_5), _2980)) / vec2(_2984);\n    float _3004 = _3002.x;\n    bool _3007 = _3004 < _2891.x;\n    bool _3016;\n    if (!_3007)\n    {\n        _3016 = _3004 > _2891.z;\n    }\n    else\n    {\n        _3016 = _3007;\n    }\n    bool _3025;\n    if (!_3016)\n    {\n        _3025 = _3002.y < _2891.y;\n    }\n    else\n    {\n        _3025 = _3016;\n    }\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3002.y > _2891.w;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    if (_3034)\n    {\n        return 1.0;\n    }\n    float _3040 = _2828.x;\n    float _3042;\n    if (_3040 > 0.0)\n    {\n        _3042 = _3040;\n    }\n    else\n    {\n        _3042 = 1.5 * _2908;\n    }\n    vec2 param_9 = _3002;\n    vec4 param_10 = _2891;\n    float param_11 = _2984 - (_3042 * (1.0 + (0.5 * _2955)));\n    float param_12 = _2908;\n    float param_13 = 1.0;\n    float param_14 = _2896.z * 0.25;\n    float param_15 = (_2908 * min(_2955, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2987, _2896.z);\n    int param_17 = int(_2823.z + 0.5);\n    float param_18 = _2823.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3587 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3593;\n    if (_3587)\n    {\n        _3593 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3593 = _3587;\n    }\n    bool _3599;\n    if (_3593)\n    {\n        _3599 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3599 = _3593;\n    }\n    if (_3599)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3611 = fa_light_texel(param);\n        float _3612 = _3611.z;\n        if (_3612 > 0.5)\n        {\n            float _3625 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3631 = ((0.00200000009499490261077880859375 * _3625) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3637 = vec4(world, 1.0);\n            float _3642 = dot(fa_mesh_fs_params[28], _3637);\n            if (_3642 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3659 = vec2(dot(fa_mesh_fs_params[26], _3637), dot(fa_mesh_fs_params[27], _3637)) / vec2(_3642);\n                float _3664 = (_3659.x * 0.5) + 0.5;\n                float _3668;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3668 = (_3659.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3668 = 0.5 - (_3659.y * 0.5);\n                }\n                bool _3684 = _3664 >= 0.0;\n                bool _3690;\n                if (_3684)\n                {\n                    _3690 = _3664 < 1.0;\n                }\n                else\n                {\n                    _3690 = _3684;\n                }\n                bool _3696;\n                if (_3690)\n                {\n                    _3696 = _3668 >= 0.0;\n                }\n                else\n                {\n                    _3696 = _3690;\n                }\n                bool _3702;\n                if (_3696)\n                {\n                    _3702 = _3668 < 1.0;\n                }\n                else\n                {\n                    _3702 = _3696;\n                }\n                if (_3702)\n                {\n                    ivec2 _3709 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3720 = clamp(ivec2(vec2(_3664, _3668) * fa_mesh_fs_params[24].zw), ivec2(0), _3709 - ivec2(1));\n                    float _3724;\n                    if (_3612 < 1.5)\n                    {\n                        _3724 = 1.0;\n                    }\n                    else\n                    {\n                        _3724 = (_3612 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3740 = texelFetch(fa_screen_tex_fa_shadow_smp, _3720, 0);\n                    bool _3743 = _3740.w > 0.5;\n                    bool _3753;\n                    if (_3743)\n                    {\n                        _3753 = abs(_3625 - _3740.x) <= _3631;\n                    }\n                    else\n                    {\n                        _3753 = _3743;\n                    }\n                    if (_3753)\n                    {\n                        best = mod(floor(_3740.z / _3724), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3720 + ivec2(-1);\n                        ivec2 param_2 = _3709;\n                        float param_3 = _3625;\n                        float param_4 = _3631;\n                        float param_5 = _3724;\n                        float param_6 = best;\n                        float _3779 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3779;\n                        ivec2 param_7 = _3720 + ivec2(0, -1);\n                        ivec2 param_8 = _3709;\n                        float param_9 = _3625;\n                        float param_10 = _3631;\n                        float param_11 = _3724;\n                        float param_12 = _3779;\n                        float _3794 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3794;\n                        ivec2 param_13 = _3720 + ivec2(1, -1);\n                        ivec2 param_14 = _3709;\n                        float param_15 = _3625;\n                        float param_16 = _3631;\n                        float param_17 = _3724;\n                        float param_18 = _3794;\n                        float _3809 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3809;\n                        ivec2 param_19 = _3720 + ivec2(-1, 0);\n                        ivec2 param_20 = _3709;\n                        float param_21 = _3625;\n                        float param_22 = _3631;\n                        float param_23 = _3724;\n                        float param_24 = _3809;\n                        float _3824 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3824;\n                        ivec2 param_25 = _3720 + ivec2(1, 0);\n                        ivec2 param_26 = _3709;\n                        float param_27 = _3625;\n                        float param_28 = _3631;\n                        float param_29 = _3724;\n                        float param_30 = _3824;\n                        float _3839 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3839;\n                        ivec2 param_31 = _3720 + ivec2(-1, 1);\n                        ivec2 param_32 = _3709;\n                        float param_33 = _3625;\n                        float param_34 = _3631;\n                        float param_35 = _3724;\n                        float param_36 = _3839;\n                        float _3854 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3854;\n                        ivec2 param_37 = _3720 + ivec2(0, 1);\n                        ivec2 param_38 = _3709;\n                        float param_39 = _3625;\n                        float param_40 = _3631;\n                        float param_41 = _3724;\n                        float param_42 = _3854;\n                        float _3869 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3869;\n                        ivec2 param_43 = _3720 + ivec2(1);\n                        ivec2 param_44 = _3709;\n                        float param_45 = _3625;\n                        float param_46 = _3631;\n                        float param_47 = _3724;\n                        float param_48 = _3869;\n                        float _3884 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3884;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3892;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3892 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3892 = best;\n                        }\n                        return _3892;\n                    }\n                }\n            }\n            float _3915;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3915 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3915 = 1.0;\n            }\n            return _3915;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5760 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5767;\n    if (!_5760)\n    {\n        _5767 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5767 = _5760;\n    }\n    if (_5767)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5780 = fa_light_texel(param);\n    float _5781 = _5780.y;\n    float len = _5781;\n    if (_5781 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5793 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5802 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5793);\n    if (_5802 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5808 = len;\n    float _5811 = min(_5808, 0.89999997615814208984375 * dist);\n    len = _5811;\n    float _5816 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5793);\n    float _5821 = _5816 + (0.5 * _5811);\n    vec3 _5827 = world + (gn * _5816);\n    float _5829 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5890;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5844 = (float(k) + _5829) * 0.083333335816860198974609375;\n        vec3 _5852 = _5827 + (l * (_5844 * len));\n        vec4 _5858 = vec4(_5852, 1.0);\n        float _5863 = dot(fa_mesh_fs_params[28], _5858);\n        if (_5863 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5881 = vec2(dot(fa_mesh_fs_params[26], _5858), dot(fa_mesh_fs_params[27], _5858)) / vec2(_5863);\n        float _5885 = _5881.x * 0.5;\n        float _5886 = _5885 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5890 = (_5881.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5890 = 0.5 - (_5881.y * 0.5);\n        }\n        bool _5906 = _5886 < 0.0;\n        bool _5913;\n        if (!_5906)\n        {\n            _5913 = _5886 >= 1.0;\n        }\n        else\n        {\n            _5913 = _5906;\n        }\n        bool _5920;\n        if (!_5913)\n        {\n            _5920 = _5890 < 0.0;\n        }\n        else\n        {\n            _5920 = _5913;\n        }\n        bool _5927;\n        if (!_5920)\n        {\n            _5927 = _5890 >= 1.0;\n        }\n        else\n        {\n            _5927 = _5920;\n        }\n        if (_5927)\n        {\n            break;\n        }\n        vec4 _5951 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5886, _5890) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5951.w < 0.5)\n        {\n            continue;\n        }\n        float _5969 = (dot(fa_mesh_fs_params[29].xyz, _5852) + fa_mesh_fs_params[29].w) - _5951.x;\n        if ((_5969 > _5816) && (_5969 < _5821))\n        {\n            occ = max(occ, (1.0 - (_5844 * _5844)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5886, 0.5 - _5885), min(_5890, 1.0 - _5890))));\n        }\n    }\n    return 1.0 - (occ * _5802);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6631 = fa_baked_keep(param);\n    if (_6631 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6657 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9934 = _6657.color;\n    float _9935 = _6657.attenuation;\n    float _9936 = _6657.shadow;\n    bool _6660 = _6657.type == 0;\n    if (_6660 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6657.direction;\n        float _6671 = fa_shadow_factor(param_5, param_6);\n        _9936 = _6671;\n        _9934 *= _6671;\n    }\n    else\n    {\n        bool _6682 = _6657.type != 0;\n        bool _6688;\n        if (_6682)\n        {\n            _6688 = _9935 > 0.0;\n        }\n        else\n        {\n            _6688 = _6682;\n        }\n        if (_6688)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6657.direction;\n            float _6707 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9936 = _6707;\n            _9934 *= _6707;\n        }\n    }\n    bool _6717 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6723;\n    if (_6717)\n    {\n        _6723 = _9935 > 0.0;\n    }\n    else\n    {\n        _6723 = _6717;\n    }\n    if (_6723)\n    {\n        float _6730;\n        if (_6660)\n        {\n            _6730 = 1000000000.0;\n        }\n        else\n        {\n            _6730 = _6657._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6657.direction;\n        float param_18 = _6730;\n        float _6748 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9936 *= _6748;\n        _9934 *= _6748;\n    }\n    float _6761 = _9935;\n    float _6762 = _6761 * _6631;\n    _9935 = _6762;\n    vec3 _6766 = _9934;\n    vec3 _6767 = _6766 * _6631;\n    _9934 = _6767;\n    return LightSample(_6657.direction, _6767, _6762, _9936, _6657._distance, _6657.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6801 = v - (n * dot(v, n));\n    vec3 t = _6801;\n    float _6805 = dot(_6801, _6801);\n    float l2 = _6805;\n    if (_6805 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6815;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6815 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6815 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6815;\n        l2 = dot(_6815, _6815);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7202;\n    if ((j == 0) || (j == 7))\n    {\n        _7202 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7212;\n        if ((j == 3) || (j == 4))\n        {\n            _7212 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7212 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7202 = _7212;\n    }\n    float _7233;\n    if ((j == 1) || (j == 2))\n    {\n        _7233 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7242;\n        if ((j == 5) || (j == 6))\n        {\n            _7242 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7242 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7233 = _7242;\n    }\n    return (pc + (ex * _7202)) + (ey * _7233);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6850 = dot(a, a);\n    float _6854 = dot(b, b);\n    if ((_6850 < 1.0000000195414813782625560981111e-24) || (_6854 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6868 = a * inversesqrt(_6850);\n    vec3 _6873 = b * inversesqrt(_6854);\n    float _6877 = dot(_6868, _6873);\n    float _6880 = abs(_6877);\n    float g = (((((((((((0.0416471660137176513671875 * _6880) - 0.1924748718738555908203125) * _6880) + 0.4179156124591827392578125) * _6880) - 0.616057217121124267578125) * _6880) + 0.777722418308258056640625) * _6880) - 0.999542415142059326171875) * _6880) + 1.570791721343994140625;\n    if (_6877 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6877 * _6877), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6868, _6873) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6937 = a.z > 0.0;\n    bool _6941 = b.z > 0.0;\n    if (_6937 && _6941)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6937 != _6941)\n        {\n            vec3 _6976 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6976.z = 0.0;\n            if (_6937)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6976;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6976;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6976;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6976;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _7025 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _7051 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _7077 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _7103 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _7025;\n    vec3 param_1 = _7051;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _7051;\n    vec3 param_7 = _7077;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _7077;\n    vec3 param_13 = _7103;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _7103;\n    vec3 param_19 = _7025;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7271 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7289;\n    for (int k = 0; k < (2 * _7271); k++)\n    {\n        bool _7286 = k >= _7271;\n        if (_7286)\n        {\n            _7289 = k - _7271;\n        }\n        else\n        {\n            _7289 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7271 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7335 = 2 * _7289;\n            int param_4 = _7335 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7335 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7335 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7372 = bvec4(_7286);\n        vec4 param_16 = vec4(_7372.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7372.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7372.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7372.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7383 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7286)\n        {\n            vec2 _10190 = sum;\n            _10190.y = _10190.y + _7383;\n            sum = _10190;\n        }\n        else\n        {\n            vec2 _10193 = sum;\n            _10193.x = _10193.x + _7383;\n            sum = _10193;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7407 = fa_light_base(param);\n    int param_1 = _7407;\n    int param_2 = _7407 + 1;\n    int param_3 = _7407 + 2;\n    int param_4 = _7407 + 4;\n    vec4 _7429 = fa_light_texel(param_4);\n    int param_5 = _7407 + 5;\n    vec4 _7434 = fa_light_texel(param_5);\n    int param_6 = _7407 + 6;\n    vec4 _7439 = fa_light_texel(param_6);\n    float _7440 = _7439.w;\n    vec3 _7445 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7447 = _7440 < 1.5;\n    bool _7454;\n    if (_7447)\n    {\n        _7454 = dot(normalize(fa_light_texel(param_3).xyz), _7445) >= 0.0;\n    }\n    else\n    {\n        _7454 = _7447;\n    }\n    if (_7454)\n    {\n        return vec3(0.0);\n    }\n    bool _7463 = (_7440 > 0.5) && _7447;\n    float _7467 = _7463 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7470 = _7429.xyz;\n    float _7472 = _7429.w;\n    vec3 _7478 = _7434.xyz;\n    float _7480 = _7434.w;\n    vec3 up = _7478 * (_7480 * _7467);\n    float _7486;\n    if (_7463)\n    {\n        _7486 = (3.1415927410125732421875 * _7472) * _7472;\n    }\n    else\n    {\n        _7486 = (4.0 * _7472) * _7480;\n    }\n    if (_7440 > 1.5)\n    {\n        vec3 _7512 = cross(_7470, -_7445);\n        vec3 perp = _7512;\n        float _7516 = dot(_7512, _7512);\n        vec3 _7519;\n        if (_7516 > 1.0000000133514319600180897396058e-10)\n        {\n            _7519 = perp * inversesqrt(_7516);\n        }\n        else\n        {\n            _7519 = _7478;\n        }\n        perp = _7519;\n        up = _7519 * _7480;\n    }\n    float _7540 = max(_7486, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7550 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7550;\n    vec3 param_10 = n;\n    vec3 param_11 = _7445;\n    vec3 param_12 = _7550;\n    vec3 param_13 = n;\n    vec3 param_14 = _7470 * (_7472 * _7467);\n    vec3 param_15 = _7550;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7581 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7581;\n    vec2 param_21 = _7581 + vec2(64.0, 0.0);\n    vec4 _7591 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7440;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7603 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7603.x) + (((f0 * _7591.x) + ((vec3(f90) - f0) * _7591.y)) * _7603.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7445, _7445)) + _7540) / _7540) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5497 = 1.0 / alpha;\n    return ((2.0 + _5497) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5497)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5532 = max(dot(L.nc, l), 0.0);\n    float _5538 = max(dot(L.nc, h), 0.0);\n    float _5547 = ((_5538 * _5538) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5547) * _5547)) * (0.5 / max(mix((2.0 * _5532) * L.coat_ndv, _5532 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5532)) * _5532;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7640;\n    if (L.sheen_on)\n    {\n        _7640 = L.sheen_scale;\n    }\n    else\n    {\n        _7640 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7640);\n    vec3 _7653 = normalize(l + v);\n    int param = li;\n    vec3 _7664 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7673 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7653), 0.0);\n        float param_3 = _7673;\n        float param_4 = ndv;\n        result += ((L.sheen * _7664) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7673)) * _7673) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7653;\n        float param_8 = max(dot(v, _7653), 0.0);\n        result += (_7664 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5400 = tdh / at;\n    float _5404 = bdh / ab;\n    float _5416 = ((_5400 * _5400) + (_5404 * _5404)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5416) * _5416);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5596 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5675 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5675) * _5675);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5596);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5596));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4799 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4802 = _4799.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4802 * _4802, exp2((-9.27999973297119140625) * ndv)) * _4802) + _4799.y)) + _4799.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4109;\n    if (lv == 0)\n    {\n        _4109 = 0.0;\n    }\n    else\n    {\n        _4109 = res + 2.0;\n    }\n    float _4119;\n    if (lv == 0)\n    {\n        _4119 = 0.0;\n    }\n    else\n    {\n        _4119 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4109, _4119)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4165;\n    if (res > 64.5)\n    {\n        _4165 = 5.0;\n    }\n    else\n    {\n        _4165 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4180 = clamp(rough, 0.0, 1.0) * (_4165 - 1.0);\n    int _4187 = int(min(floor(_4180), _4165 - 2.0));\n    float _4192 = _4180 - float(_4187);\n    vec3 param = d;\n    vec2 _4196 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4187;\n    vec2 param_4 = _4196;\n    vec3 _4206 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4192 < 0.00200000009499490261077880859375)\n    {\n        return _4206;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4187 + 1;\n    vec2 param_8 = _4196;\n    return mix(_4206, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4192));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4277 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4284 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4291 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4297 = dot(bx.xyz, d);\n    float _4301 = dot(by.xyz, d);\n    float _4305 = dot(bz.xyz, d);\n    float _4311;\n    if (_4297 > 9.9999999747524270787835121154785e-07)\n    {\n        _4311 = (1.0 - _4277) / _4297;\n    }\n    else\n    {\n        float _4325;\n        if (_4297 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4325 = ((-1.0) - _4277) / _4297;\n        }\n        else\n        {\n            _4325 = 1000000015047466219876688855040.0;\n        }\n        _4311 = _4325;\n    }\n    float tx = _4311;\n    float _4342;\n    if (_4301 > 9.9999999747524270787835121154785e-07)\n    {\n        _4342 = (1.0 - _4284) / _4301;\n    }\n    else\n    {\n        float _4355;\n        if (_4301 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4355 = ((-1.0) - _4284) / _4301;\n        }\n        else\n        {\n            _4355 = 1000000015047466219876688855040.0;\n        }\n        _4342 = _4355;\n    }\n    float ty = _4342;\n    float _4371;\n    if (_4305 > 9.9999999747524270787835121154785e-07)\n    {\n        _4371 = (1.0 - _4291) / _4305;\n    }\n    else\n    {\n        float _4384;\n        if (_4305 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4384 = ((-1.0) - _4291) / _4305;\n        }\n        else\n        {\n            _4384 = 1000000015047466219876688855040.0;\n        }\n        _4371 = _4384;\n    }\n    float _4396 = tx;\n    float _4399 = (_4396 > 0.0) ? _4396 : 1000000015047466219876688855040.0;\n    tx = _4399;\n    float _4400 = ty;\n    float _4403 = (_4400 > 0.0) ? _4400 : 1000000015047466219876688855040.0;\n    ty = _4403;\n    float _4413 = min(_4399, min(_4403, (_4371 > 0.0) ? _4371 : 1000000015047466219876688855040.0));\n    if (_4413 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4429 = (fa_world_pos + (d * _4413)) - posw.xyz;\n    vec3 _4434;\n    if (dot(_4429, _4429) > 1.0000000133514319600180897396058e-10)\n    {\n        _4434 = normalize(_4429);\n    }\n    else\n    {\n        _4434 = d;\n    }\n    return _4434;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4480 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4480 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4508 = rough * rough;\n            float _4539 = 0.60000002384185791015625 * _4508;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4508)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4539, 0.0500000007450580596923828125 + _4539, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4508 * 0.60000002384185791015625));\n        }\n        outc = base * _4480;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4598 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4598 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4630 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4630 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5277;\n        if (L.aniso >= 0.0)\n        {\n            _5277 = L.b;\n        }\n        else\n        {\n            _5277 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5277, v), _5277), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5313 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5313.x) + (vec3(L.f90) * _5313.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5371 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5371.x) + _5371.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4841 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4841.x) + vec3(_4841.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _6073 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _6077 = fa_xm_origin(param_1);\n    vec2 _6083 = (uv * _6073) - vec2(0.5);\n    vec2 _6086 = fract(_6083);\n    vec2 _6089 = floor(_6083);\n    vec2 param_2 = _6073;\n    vec2 param_3 = _6077;\n    vec2 param_4 = _6089;\n    vec2 param_5 = _6073;\n    vec2 param_6 = _6077;\n    vec2 param_7 = _6089 + vec2(1.0, 0.0);\n    vec2 param_8 = _6073;\n    vec2 param_9 = _6077;\n    vec2 param_10 = _6089 + vec2(0.0, 1.0);\n    vec2 param_11 = _6073;\n    vec2 param_12 = _6077;\n    vec2 param_13 = _6089 + vec2(1.0);\n    vec3 _6131 = vec3(_6086.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6131), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6131), vec3(_6086.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6150 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6154 = clamp(lod, 0.0, _6150);\n    int _6158 = int(floor(_6154));\n    int param = _6158;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6168 = float(_6158);\n    float _6169 = _6154 - _6168;\n    bool _6171 = _6169 > 0.001000000047497451305389404296875;\n    bool _6178;\n    if (_6171)\n    {\n        _6178 = _6168 < _6150;\n    }\n    else\n    {\n        _6178 = _6171;\n    }\n    if (_6178)\n    {\n        int param_2 = _6158 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6169));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6204 = fa_env_brdf(param, param_1);\n    vec3 _6228 = ((vec3(1.0) - clamp((f0 * _6204.x) + (vec3(f90) * _6204.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6228;\n    float _6234 = max(s.thickness, 0.0);\n    bool _6239 = _6234 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6239)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6234);\n    }\n    bool _6264 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6270;\n    if (_6264)\n    {\n        _6270 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6270 = _6264;\n    }\n    bool _6277;\n    if (!_6270)\n    {\n        _6277 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6277 = _6270;\n    }\n    if (_6277)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6292 = vec4(fa_world_pos, 1.0);\n    float _6297 = dot(fa_mesh_fs_params[28], _6292);\n    vec2 uv0 = vec2(0.5);\n    if (_6297 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6315 = vec2(dot(fa_mesh_fs_params[26], _6292), dot(fa_mesh_fs_params[27], _6292)) / vec2(_6297);\n        float _6323;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6323 = (_6315.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6323 = 0.5 - (_6315.y * 0.5);\n        }\n        uv0 = vec2((_6315.x * 0.5) + 0.5, _6323);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6344 = fa_xm_size(param_2);\n        vec2 _6352 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6344);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6352), 0).w > 0.5)\n        {\n            int _6372 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6395 = abs(dx) > _6372;\n                    bool _6403;\n                    if (!_6395)\n                    {\n                        _6403 = abs(dy) > _6372;\n                    }\n                    else\n                    {\n                        _6403 = _6395;\n                    }\n                    if (_6403)\n                    {\n                        continue;\n                    }\n                    vec4 _6424 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6352 + vec2(float(dx), float(dy)), vec2(0.0), _6344 - vec2(1.0))), 0);\n                    if (_6424.w > 0.5)\n                    {\n                        acc += _6424.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6228 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6239)\n    {\n        vec4 _6472 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6234), 1.0);\n        float _6477 = dot(fa_mesh_fs_params[28], _6472);\n        uv = vec2(0.5);\n        if (_6477 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6494 = vec2(dot(fa_mesh_fs_params[26], _6472), dot(fa_mesh_fs_params[27], _6472)) / vec2(_6477);\n            float _6502;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6502 = (_6494.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6502 = 0.5 - (_6494.y * 0.5);\n            }\n            uv = vec2((_6494.x * 0.5) + 0.5, _6502);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3296 = int(fa_shadows[25].x + 0.5);\n    float _3306 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3311 = _3296 > 0;\n    bool _3320;\n    if (_3311)\n    {\n        int param = _3296 - 1;\n        _3320 = _3306 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3320 = _3311;\n    }\n    if (_3320)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3326 = _3296 > 1;\n        bool _3333;\n        if (_3326)\n        {\n            _3333 = _3306 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3333 = _3326;\n        }\n        if (_3333)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3339 = _3296 > 2;\n        bool _3346;\n        if (_3339)\n        {\n            _3346 = _3306 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3346 = _3339;\n        }\n        if (_3346)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3352 = _3296 > 3;\n        bool _3359;\n        if (_3352)\n        {\n            _3359 = _3306 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3359 = _3352;\n        }\n        if (_3359)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9593 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9593 = -_9593;\n    }\n    vec3 _8891 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9593, fa_world_tangent, fa_uv, fa_vertex_color, _8891, gl_FrontFacing);\n    Surface _8899 = fa_standard_surface(param_1);\n    vec3 _9624 = _8899.albedo;\n    float _9625 = _8899.alpha;\n    vec3 _9626 = _8899.normal;\n    float _9627 = _8899.metallic;\n    float _9628 = _8899.roughness;\n    float _9629 = _8899.occlusion;\n    vec3 _9630 = _8899.emission;\n    float _9631 = _8899.clearcoat;\n    float _9632 = _8899.clearcoat_roughness;\n    vec3 _9633 = _8899.sheen_color;\n    float _9634 = _8899.sheen_roughness;\n    float _9635 = _8899.anisotropy;\n    float _9636 = _8899.anisotropy_rotation;\n    float _9637 = _8899.specular;\n    float _9638 = _8899.ior;\n    vec3 _9639 = _8899.specular_color;\n    float _9640 = _8899.transmission;\n    float _9641 = _8899.thickness;\n    vec3 _9642 = _8899.attenuation_color;\n    float _9643 = _8899.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9593, fa_world_tangent, fa_uv, fa_vertex_color, _8891, gl_FrontFacing);\n    Surface param_3 = _8899;\n    surface(param_2, param_3);\n    _9624 = param_3.albedo;\n    _9625 = param_3.alpha;\n    _9626 = param_3.normal;\n    _9627 = param_3.metallic;\n    _9628 = param_3.roughness;\n    _9629 = param_3.occlusion;\n    _9630 = param_3.emission;\n    _9631 = param_3.clearcoat;\n    _9632 = param_3.clearcoat_roughness;\n    _9633 = param_3.sheen_color;\n    _9634 = param_3.sheen_roughness;\n    _9635 = param_3.anisotropy;\n    _9636 = param_3.anisotropy_rotation;\n    _9637 = param_3.specular;\n    _9638 = param_3.ior;\n    _9639 = param_3.specular_color;\n    _9640 = param_3.transmission;\n    _9641 = param_3.thickness;\n    _9642 = param_3.attenuation_color;\n    _9643 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9593;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9624 = param_6;\n    _9626 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9624;\n    }\n    else\n    {\n        vec3 _8939 = normalize(_9626);\n        float _8946 = clamp(_9627, 0.0, 1.0);\n        float _8950 = clamp(_9628, 0.0500000007450580596923828125, 1.0);\n        float _8954 = _8950 * _8950;\n        float _8958 = _8954 * _8954;\n        float _8963 = max(dot(_8939, _8891), 9.9999997473787516355514526367188e-05);\n        float _8969 = 1.0 - _8946;\n        float _8970 = clamp(_9640, 0.0, 1.0) * _8969;\n        vec3 _8979 = (_9624 * _8969) * (1.0 - _8970);\n        vec3 _8986 = mix(vec3(0.039999999105930328369140625), _9624, vec3(_8946));\n        vec3 f0 = _8986;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9593, fa_world_tangent, fa_uv, fa_vertex_color, _8891, gl_FrontFacing);\n        Surface param_9 = Surface(_9624, _9625, _9626, _9627, _9628, _9629, _9630, _9631, _9632, _9633, _9634, _9635, _9636, _9637, _9638, _9639, _9640, _9641, _9642, _9643);\n        vec3 param_10 = _8939;\n        vec3 param_11 = _8891;\n        float param_12 = _8946;\n        float param_13 = _8950;\n        vec3 param_14 = _8986;\n        FaLayers _9002 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8939;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8979) * _9629;\n        if (_9002.on)\n        {\n            lit *= _9002.base_scale;\n        }\n        int _9024 = fa_cl_ndir + fa_cl_local;\n        float _9089;\n        for (int ln = 0; ln < _9024; ln++)\n        {\n            int param_16 = ln;\n            int _9037 = fa_cl_light(param_16);\n            int param_17 = _9037;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _9037;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9593;\n            LightSample _9053 = fa_light_shadowed(param_18, param_19, param_20);\n            float _9061 = max(dot(_8939, _9053.direction), 0.0);\n            float _9067 = _9053.attenuation * _9053.shadow;\n            vec3 _9072 = normalize(_9053.direction + _8891);\n            float _9077 = max(dot(_8939, _9072), 0.0);\n            float _9082 = max(dot(_8891, _9072), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_9002.on)\n                {\n                    _9089 = _9002.f90;\n                }\n                else\n                {\n                    _9089 = 1.0;\n                }\n                int param_21 = _9037;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8939;\n                vec3 param_24 = _8891;\n                vec3 param_25 = _8979;\n                vec3 param_26 = f0;\n                float param_27 = _9089;\n                float param_28 = _8950;\n                float param_29 = _8963;\n                float param_30 = _9067;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_9002.on)\n                {\n                    FaLayers param_31 = _9002;\n                    vec3 param_32 = area;\n                    int param_33 = _9037;\n                    vec3 param_34 = _8939;\n                    vec3 param_35 = _8891;\n                    vec3 param_36 = _9053.direction;\n                    float param_37 = _8963;\n                    float param_38 = _9067;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_9002.on)\n                {\n                    FaLayers param_39 = _9002;\n                    vec3 param_40 = _8979;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8939;\n                    vec3 param_43 = _8891;\n                    vec3 param_44 = _9053.direction;\n                    vec3 param_45 = _9072;\n                    float param_46 = _9061;\n                    float param_47 = _8963;\n                    float param_48 = _9077;\n                    float param_49 = _9082;\n                    float param_50 = _8954;\n                    float param_51 = _8958;\n                    int param_52 = _9037;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _9067));\n                }\n                else\n                {\n                    float _9191 = ((_9077 * _9077) * (_8958 - 1.0)) + 1.0;\n                    int param_53 = _9037;\n                    lit += (((_8979 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _9082, 5.0))) * (((_8958 / ((3.1415927410125732421875 * _9191) * _9191)) * (0.5 / max(mix((2.0 * _9061) * _8963, _9061 + _8963, _8954), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _9061))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_9061 * _9067));\n                }\n            }\n        }\n        if (_9002.on)\n        {\n            FaLayers param_54 = _9002;\n            vec3 param_55 = _8939;\n            vec3 param_56 = _8891;\n            vec3 param_57 = f0;\n            float param_58 = _8950;\n            float param_59 = _9629;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8939;\n            vec3 param_61 = _8891;\n            vec3 param_62 = f0;\n            float param_63 = _8950;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9629);\n        }\n        if (_8970 > 0.0)\n        {\n            float _9289;\n            if (_9002.on)\n            {\n                _9289 = _9002.f90;\n            }\n            else\n            {\n                _9289 = 1.0;\n            }\n            float _9297;\n            if (_9002.on)\n            {\n                _9297 = _9002.base_scale;\n            }\n            else\n            {\n                _9297 = 1.0;\n            }\n            Surface param_64 = Surface(_9624, _9625, _9626, _9627, _9628, _9629, _9630, _9631, _9632, _9633, _9634, _9635, _9636, _9637, _9638, _9639, _9640, _9641, _9642, _9643);\n            vec3 param_65 = _8939;\n            vec3 param_66 = _8891;\n            float param_67 = _8950;\n            vec3 param_68 = f0;\n            float param_69 = _9289;\n            float param_70 = _9297;\n            float param_71 = _8970;\n            float param_72 = fa_tr_blend;\n            vec3 _9321 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9321;\n        }\n        result = lit;\n    }\n    vec3 _9328 = result;\n    vec3 _9329 = _9328 + _9630;\n    result = _9329;\n    vec3 param_73 = _9329;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9338 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9345;\n    if (!_9338)\n    {\n        _9345 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9345 = _9338;\n    }\n    if (_9345)\n    {\n        vec3 _9354 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9360 = dot(_9354, fa_mesh_fs_params[9].xyz);\n        bool _9364 = fa_mesh_fs_params[9].w > 0.5;\n        float _9365;\n        if (_9364)\n        {\n            _9365 = _9360;\n        }\n        else\n        {\n            _9365 = length(_9354);\n        }\n        float _9377 = _9365 - fa_mesh_fs_params[8].x;\n        if (_9377 > 0.0)\n        {\n            float _9386 = fa_mesh_fs_params[7].w * _9377;\n            float tau = _9386 * _9386;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9402;\n                if (_9364)\n                {\n                    _9402 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9360);\n                }\n                else\n                {\n                    _9402 = fa_mesh_fs_params[0].y;\n                }\n                float _9423 = mix(_9402, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9365, 0.0, 1.0));\n                float _9427 = fa_world_pos.y - _9423;\n                float _9432 = _9423 - fa_mesh_fs_params[8].z;\n                float _9437 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9440 = _9432 <= 0.0;\n                bool _9441 = !_9440;\n                bool _9447;\n                if (_9441)\n                {\n                    _9447 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9447 = _9440;\n                }\n                float _9448;\n                if (_9447)\n                {\n                    _9448 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9448 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9432, 80.0));\n                }\n                bool _9475;\n                if (_9441)\n                {\n                    _9475 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9475 = _9440;\n                }\n                float _9476;\n                if (_9475)\n                {\n                    _9476 = fa_mesh_fs_params[8].y * _9432;\n                }\n                else\n                {\n                    _9476 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9432, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9501 = _9437 <= 0.0;\n                bool _9508;\n                if (!_9501)\n                {\n                    _9508 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9508 = _9501;\n                }\n                float _9509;\n                if (_9508)\n                {\n                    _9509 = fa_mesh_fs_params[8].y * _9437;\n                }\n                else\n                {\n                    _9509 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9437, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9536;\n                if (abs(_9427) < 0.001000000047497451305389404296875)\n                {\n                    _9536 = _9448;\n                }\n                else\n                {\n                    _9536 = (_9509 - _9476) / _9427;\n                }\n                tau += (_9377 * max(_9536, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9572 = 1.0 - fa_tr_blend;\n        result /= vec3(_9572);\n        _9625 *= _9572;\n    }\n    fa_frag_color = vec4(result, _9625);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_675",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2337",
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
            "inst_name": "_7741",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
          },
          {
            "slot": 11,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4942[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat fa_rt_slope;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1613 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1620;\n    if (!_1613)\n    {\n        _1620 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1620 = _1613;\n    }\n    bool _1628;\n    if (!_1620)\n    {\n        _1628 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1628 = _1620;\n    }\n    bool _1635;\n    if (!_1628)\n    {\n        _1635 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1635 = _1628;\n    }\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    if (_1642)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1652 = vec4(world_pos, 1.0);\n    float _1658 = dot(fa_mesh_fs_params[16], _1652);\n    if (!(_1658 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1680 = vec2(dot(fa_mesh_fs_params[14], _1652), dot(fa_mesh_fs_params[15], _1652)) / vec2(_1658);\n    int _1684 = int(fa_mesh_fs_params[18].x);\n    int _1688 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1688) + clamp(int(floor(((_1680.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1688 - 1)) * _1684)) + clamp(int(floor(((_1680.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1684 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1764 = fa_cluster_texel(param);\n    return ivec2(int(_1764.x), int(_1764.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    float _6576 = dot(fa_mesh_fs_params[29].xyz, world_pos) + fa_mesh_fs_params[29].w;\n    float _6579 = fwidth(_6576);\n    bool _6582 = fa_mesh_fs_params[25].y > 0.5;\n    bool _6589;\n    if (!_6582)\n    {\n        _6589 = fa_mesh_fs_params[25].w > 0.5;\n    }\n    else\n    {\n        _6589 = _6582;\n    }\n    if (_6589)\n    {\n        fa_rt_slope = min(1.5 * _6579, 0.100000001490116119384765625 * _6576);\n    }\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6605 = fa_cluster_lookup(param);\n    fa_cl_slot = _6605.x;\n    fa_cl_local = _6605.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7793 = fa_linear_to_srgb(param);\n        c = _7793;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7801 = fa_srgb_to_linear(param_1);\n            c = _7801;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _558;\n    if (i.front_facing)\n    {\n        _558 = i.world_normal;\n    }\n    else\n    {\n        _558 = -i.world_normal;\n    }\n    vec3 _582 = normalize(i.world_tangent.xyz - (_558 * dot(_558, i.world_tangent.xyz)));\n    vec3 _609 = normalize(((_582 * m.x) + ((cross(_558, _582) * i.world_tangent.w) * m.y)) + (_558 * m.z));\n    vec3 _612;\n    if (i.front_facing)\n    {\n        _612 = _609;\n    }\n    else\n    {\n        _612 = -_609;\n    }\n    return _612;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7833 = fa_tex_fix(param_2, param_3);\n    vec4 _10207 = base_t;\n    _10207.x = _7833.x;\n    _10207.y = _7833.y;\n    _10207.z = _7833.z;\n    base_t = _10207;\n    vec4 _7847 = (_10207 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9954 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7881 = fa_tex_fix(param_6, param_7);\n        vec3 _7884 = (_7881 * 2.0) - vec3(1.0);\n        vec2 _7889 = _7884.xy * fa_mesh_fs_params[6].x;\n        vec3 _10215 = _7884;\n        _10215.x = _7889.x;\n        _10215.y = _7889.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _10215;\n        _9954 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7919 = fa_tex_fix(param_12, param_13);\n    vec4 _10218 = mrt;\n    _10218.x = _7919.x;\n    _10218.y = _7919.y;\n    _10218.z = _7919.z;\n    mrt = _10218;\n    vec4 _7949 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7949.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7960 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7992 = fa_tex_fix(param_20, param_21);\n    float _9959 = fa_mesh_fs_params[20].x;\n    float _9960 = fa_mesh_fs_params[20].y;\n    float _9963 = fa_mesh_fs_params[20].z;\n    float _9962 = fa_mesh_fs_params[21].w;\n    float _9965 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9959 *= _7960.y;\n            _9960 *= _7960.z;\n            _9962 *= _7949.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9963 *= mrt.x;\n            _9965 *= mrt.w;\n        }\n    }\n    return Surface(_7847.xyz, _7847.w, _9954, clamp(fa_mesh_fs_params[5].x * _7919.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7919.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7960.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7992), _9959, _9960, fa_mesh_fs_params[21].xyz, _9962, _9963, fa_mesh_fs_params[20].w, _9965, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1844 = rect.zw - rect.xy;\n    vec2 _1848 = _1844 * atlas;\n    vec2 _1852 = ddx * _1848;\n    vec2 _1856 = ddy * _1848;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1844), clamp(0.5 * log2(max(max(dot(_1852, _1852), dot(_1856, _1856)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1889 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1896;\n    if (!_1889)\n    {\n        _1896 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1896 = _1889;\n    }\n    if (_1896)\n    {\n        return;\n    }\n    vec3 _1902 = dFdx(world_pos);\n    vec3 _1905 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1909 = fa_cluster_texel(param);\n    int _1913 = int(_1909.w);\n    if (_1913 < 1)\n    {\n        return;\n    }\n    int _1923 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1923;\n    vec4 _1927 = fa_light_texel(param_1);\n    vec2 _1930 = _1927.yz;\n    int _1934 = int(_1927.w);\n    int param_2 = _1923 + 1;\n    vec4 _1939 = fa_light_texel(param_2);\n    float _1940 = _1939.x;\n    int _1946 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1950 = int(_1909.z);\n    vec3 _2215;\n    for (int k = 0; k < _1913; k++)\n    {\n        int _1963 = _1950 + k;\n        int param_3 = _1934 + (_1963 >> 2);\n        int _1980 = (_1923 + 2) + (int(fa_light_texel(param_3)[_1963 & 3]) * 7);\n        int param_4 = _1980 + 6;\n        vec4 _1985 = fa_light_texel(param_4);\n        if (((int(_1985.w + 0.5) >> _1946) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1980;\n        vec4 _2000 = fa_light_texel(param_5);\n        int param_6 = _1980 + 1;\n        vec4 _2005 = fa_light_texel(param_6);\n        int param_7 = _1980 + 2;\n        vec4 _2010 = fa_light_texel(param_7);\n        vec3 _2013 = _2000.xyz;\n        float _2018 = dot(_2013, world_pos) + _2000.w;\n        vec3 _2020 = _2005.xyz;\n        float _2025 = dot(_2020, world_pos) + _2005.w;\n        vec3 _2027 = _2010.xyz;\n        float _2032 = dot(_2027, world_pos) + _2010.w;\n        bool _2037 = abs(_2018) > 0.5;\n        bool _2045;\n        if (!_2037)\n        {\n            _2045 = abs(_2025) > 0.5;\n        }\n        else\n        {\n            _2045 = _2037;\n        }\n        bool _2053;\n        if (!_2045)\n        {\n            _2053 = abs(_2032) > 0.5;\n        }\n        else\n        {\n            _2053 = _2045;\n        }\n        if (_2053)\n        {\n            continue;\n        }\n        float _2068 = clamp(dot(geo_normal, normalize(_2027)) * _1985.z, 0.0, 1.0);\n        if (_2068 <= 0.0)\n        {\n            continue;\n        }\n        float _2088 = (clamp((0.5 - abs(_2032)) * 10.0, 0.0, 1.0) * _2068) * _1985.x;\n        vec2 _2096 = vec2(_2018 + 0.5, 0.5 - _2025);\n        vec2 _2106 = vec2(dot(_2013, _1902), dot(_2020, _1902));\n        vec2 _2116 = vec2(dot(_2013, _1905), dot(_2020, _1905));\n        int param_8 = _1980 + 5;\n        vec4 _2121 = fa_light_texel(param_8);\n        int param_9 = _1980 + 3;\n        vec4 _2126 = fa_light_texel(param_9);\n        int param_10 = _1980 + 4;\n        vec4 _2131 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2121.xyz;\n        bool _2141 = _2126.z > _2126.x;\n        if (_2141)\n        {\n            vec4 param_11 = _2126;\n            vec2 param_12 = _2096;\n            vec2 param_13 = _1930;\n            vec2 param_14 = _2106;\n            vec2 param_15 = _2116;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1940 > 0.5) && (_1940 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2167 = fa_dc_to_linear(param_16);\n                vec4 _10042 = tx;\n                _10042.x = _2167.x;\n                _10042.y = _2167.y;\n                _10042.z = _2167.z;\n                tx = _10042;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2088 * tex_a) * _2121.w, 0.0, 1.0)));\n        if (_2131.z > _2131.x)\n        {\n            vec4 param_17 = _2131;\n            vec2 param_18 = _2096;\n            vec2 param_19 = _1930;\n            vec2 param_20 = _2106;\n            vec2 param_21 = _2116;\n            vec4 _2211 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1940 > 1.5)\n            {\n                vec3 param_22 = _2211.xyz;\n                vec3 _2221 = fa_dc_to_srgb(param_22);\n                _2215 = _2221;\n            }\n            else\n            {\n                _2215 = _2211.xyz;\n            }\n            vec3 _2230 = (_2215 * 2.0) - vec3(1.0);\n            vec2 _2235 = _2230.xy * _1985.y;\n            vec3 _2257 = (normalize(_2013) * _2235.x) + (normalize(_2020) * _2235.y);\n            vec3 _2260 = normalize(normal);\n            normal = normalize(mix(_2260, normalize((_2260 * max(_2230.z, 0.0500000007450580596923828125)) + (_2257 - (_2260 * dot(_2260, _2257)))), vec3(clamp(_2088 * (_2141 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4867 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4875 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4878 = int(_4867);\n    int _4881 = int(_4875);\n    float _4891 = _4875 - float(_4881);\n    int _4946 = (_4878 * 9) + _4881;\n    int _4966 = ((_4878 + 1) * 9) + _4881;\n    return mix(mix(_4942[_4946], _4942[_4946 + 1], _4891), mix(_4942[_4966], _4942[_4966 + 1], _4891), _4867 - float(_4878));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9877 = false;\n    float _9878 = 1.0;\n    float _9879 = 1.0;\n    float _9880 = 1.0;\n    float _9881 = 0.0;\n    float _9882 = 0.0;\n    float _9883 = 0.0;\n    float _9884 = 0.0;\n    float _9886 = 1.0;\n    bool _9887 = false;\n    vec3 _9888 = vec3(0.0);\n    float _9889 = 1.0;\n    float _9890 = 1.0;\n    float _9891 = 1.0;\n    float _9892 = 0.0;\n    float _9893 = 0.0;\n    vec3 _9894 = vec3(1.0, 0.0, 0.0);\n    vec3 _9895 = vec3(0.0, 0.0, 1.0);\n    float _9896 = 1.0;\n    float _9897 = 1.0;\n    float _5017 = clamp(s.specular, 0.0, 1.0);\n    float _5021 = clamp(s.ior, 1.0, 3.0);\n    bool _5026 = (_5017 != 1.0) || (_5021 != 1.5);\n    bool _5035;\n    if (!_5026)\n    {\n        _5035 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _5035 = _5026;\n    }\n    if (_5035)\n    {\n        float _5043 = (_5021 - 1.0) / (_5021 + 1.0);\n        f0 = mix(min(vec3(_5043 * _5043) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _5017, s.albedo, vec3(metallic));\n        _9878 = mix(_5017, 1.0, metallic);\n        _9877 = true;\n    }\n    float _5070 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_5070 > 0.0)\n    {\n        float _5078 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9881 = _5070;\n        _9882 = _5078;\n        float _5085 = _5078 * _5078;\n        _9883 = _5085;\n        _9884 = _5085 * _5085;\n        float _5097 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9886 = _5097;\n        _9879 = 1.0 - (_5070 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _5097, 0.0, 1.0), 5.0))));\n        _9877 = true;\n    }\n    vec3 _5116 = max(s.sheen_color, vec3(0.0));\n    float _5125 = max(_5116.x, max(_5116.y, _5116.z));\n    if (_5125 > 0.0)\n    {\n        float _5133 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9887 = true;\n        _9888 = _5116;\n        _9889 = _5133;\n        _9890 = _5133 * _5133;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5133;\n        float _5150 = fa_sheen_albedo(param, param_1);\n        _9892 = _5150;\n        _9891 = 1.0 - min(_5125 * _5150, 1.0);\n        _9877 = true;\n    }\n    _9880 = _9879 * _9891;\n    float _5169 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5169 != 0.0)\n    {\n        vec3 _5184 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5184;\n        if (dot(_5184, _5184) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5196 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5196.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5196.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5196.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5200 = t;\n        vec3 _5201 = normalize(_5200);\n        t = _5201;\n        vec3 _5226 = normalize((_5201 * cos(s.anisotropy_rotation)) + ((cross(n, _5201) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9894 = _5226;\n        _9895 = cross(n, _5226);\n        float _5236 = roughness * roughness;\n        float _5242 = mix(_5236, 1.0, _5169 * _5169);\n        bool _5244 = _5169 > 0.0;\n        _9896 = _5244 ? _5242 : _5236;\n        _9897 = _5244 ? _5236 : _5242;\n        _9893 = _5169;\n        _9877 = true;\n    }\n    return FaLayers(_9877, _9878, _9879, _9880, _9881, _9882, _9883, _9884, i.world_normal, _9886, _9887, _9888, _9889, _9890, _9891, _9892, _9893, _9894, _9895, _9896, _9897);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _4037 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _4037;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4648 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4653 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4648 > 0.0005000000237487256526947021484375)\n    {\n        if (_4653)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4648;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4648;\n        }\n    }\n    bool _4704 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4704)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4735 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4735)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4653 || _4704) || _4735)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _4057 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _4060 = _4057.x;\n    float _4062 = _4057.z;\n    vec2 e = vec2(_4060, _4062);\n    if (_4057.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_4062)) * ((_4060 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_4060)) * ((_4062 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _8102 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _8107 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _8112 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _8117 = fa_light_texel(param_3);\n    bool _8120 = _8117.z < 0.5;\n    bool _8128;\n    if (!_8120)\n    {\n        _8128 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _8128 = _8120;\n    }\n    if (_8128)\n    {\n        return vec3(0.0);\n    }\n    float _8135 = max(_8102.w, 9.9999997473787516355514526367188e-05);\n    vec3 _8138 = _8107.xyz;\n    vec3 _8142 = _8102.xyz;\n    vec3 _8146 = (fa_world_pos - _8142) / vec3(_8135);\n    vec3 _8155 = min(_8146 + vec3(0.5), (_8138 - vec3(0.5)) - _8146);\n    float _8164 = min(_8155.x, min(_8155.y, _8155.z));\n    if (!(_8164 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _8179 = _8138 - vec3(1.0);\n    vec3 _8180 = clamp(_8146, vec3(0.0), _8179);\n    vec3 _8188 = min(floor(_8180), max(_8138 - vec3(2.0), vec3(0.0)));\n    vec3 _8192 = _8180 - _8188;\n    vec3 _8203 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _8135));\n    int _8208 = int(_8112.y + 0.5);\n    float _8213 = 0.3257350027561187744140625 * n.y;\n    float _8217 = 0.3257350027561187744140625 * n.z;\n    float _8221 = 0.3257350027561187744140625 * n.x;\n    float _8228 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _8235 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _8244 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _8251 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _8264 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _8271 = 8 + int(_8117.w);\n    float _8298;\n    float _8311;\n    float _8325;\n    for (int k = 0; k < _8271; k++)\n    {\n        float _8284 = float(k & 1);\n        float _8288 = float((k >> 1) & 1);\n        float _8292 = float((k >> 2) & 1);\n        if (_8284 > 0.5)\n        {\n            _8298 = _8192.x;\n        }\n        else\n        {\n            _8298 = 1.0 - _8192.x;\n        }\n        if (_8288 > 0.5)\n        {\n            _8311 = _8192.y;\n        }\n        else\n        {\n            _8311 = 1.0 - _8192.y;\n        }\n        if (_8292 > 0.5)\n        {\n            _8325 = _8192.z;\n        }\n        else\n        {\n            _8325 = 1.0 - _8192.z;\n        }\n        float _8335 = (_8298 * _8311) * _8325;\n        if (!(_8335 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8348 = min(_8188 + vec3(_8284, _8288, _8292), _8179);\n        int _8368 = int(((_8112.x + _8348.x) + (_8107.x * (_8348.y + (_8107.y * _8348.z)))) + 0.5);\n        vec2 _8383 = vec2(float(_8368 % _8208) * 10.0, 1024.0 + (float(_8368 / _8208) * 11.0));\n        vec2 param_4 = _8383 + vec2(9.5, 10.5);\n        vec4 _8391 = fa_gi_fetch(param_4);\n        bool _8394 = _8391.y < 0.5;\n        bool _8403;\n        if (!_8394)\n        {\n            _8403 = _8391.x > _8117.y;\n        }\n        else\n        {\n            _8403 = _8394;\n        }\n        if (_8403)\n        {\n            continue;\n        }\n        vec3 _8415 = _8203 - (_8142 + (_8348 * _8135));\n        float _8418 = length(_8415);\n        vec3 _8424 = _8415 / vec3(max(_8418, 9.9999997473787516355514526367188e-05));\n        float _8434 = max(9.9999997473787516355514526367188e-05, (dot(-_8424, n) + 1.0) * 0.5);\n        float w = _8335 * (_8434 * _8434);\n        vec3 param_5 = _8424;\n        vec2 param_6 = (_8383 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8453 = fa_gi_fetch(param_6);\n        float _8460 = _8418 / max(_8112.z, 9.9999997473787516355514526367188e-05);\n        float _8463 = _8453.x;\n        if (_8460 > _8463)\n        {\n            float _8476 = max(_8453.y - (_8463 * _8463), 0.0);\n            float _8481 = _8460 - _8463;\n            float _8490 = _8476 / max(_8476 + (_8481 * _8481), 9.9999999600419720025001879548654e-13);\n            w *= ((_8490 * _8490) * _8490);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8383 + vec2(0.5, 10.5);\n        vec2 param_8 = _8383 + vec2(1.5, 10.5);\n        vec2 param_9 = _8383 + vec2(2.5, 10.5);\n        vec2 param_10 = _8383 + vec2(3.5, 10.5);\n        vec2 param_11 = _8383 + vec2(4.5, 10.5);\n        vec2 param_12 = _8383 + vec2(5.5, 10.5);\n        vec2 param_13 = _8383 + vec2(6.5, 10.5);\n        vec2 param_14 = _8383 + vec2(7.5, 10.5);\n        vec2 param_15 = _8383 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _8213)) + (fa_gi_fetch(param_9).xyz * _8217)) + (fa_gi_fetch(param_10).xyz * _8221)) + (fa_gi_fetch(param_11).xyz * _8228)) + (fa_gi_fetch(param_12).xyz * _8235)) + (fa_gi_fetch(param_13).xyz * _8244)) + (fa_gi_fetch(param_14).xyz * _8251)) + (fa_gi_fetch(param_15).xyz * _8264)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_8164 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8615;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8615 = _8117.x;\n    }\n    else\n    {\n        _8615 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_8112.w * _8615);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8639 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8644 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8649 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8649) && (k < 8); k++)\n    {\n        int param = _8644 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8639;\n        vec3 _8674 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8679 = param_3 * left;\n        acc += (_8674 * _8679);\n        left -= _8679;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8708 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8708;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[53].x > 0.5)\n    {\n        vec4 _8750 = vec4(fa_world_pos, 1.0);\n        vec2 _8769 = vec2(dot(fa_mesh_fs_params[26], _8750), dot(fa_mesh_fs_params[27], _8750)) / vec2(max(dot(fa_mesh_fs_params[28], _8750), 9.9999997473787516355514526367188e-05));\n        float _8778;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _8778 = (_8769.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _8778 = 0.5 - (_8769.y * 0.5);\n        }\n        return texelFetch(fa_lightmap_fa_env_smp, clamp(ivec2(vec2((_8769.x * 0.5) + 0.5, _8778) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6546;\n    if (fa_lm.z > 0.5)\n    {\n        _6546 = 0.0;\n    }\n    else\n    {\n        _6546 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6557 = _6546 < 1.0;\n    bool _6563;\n    if (_6557)\n    {\n        int param = li;\n        _6563 = fa_light_baked(param);\n    }\n    else\n    {\n        _6563 = _6557;\n    }\n    return _6563 ? _6546 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _862 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _875 = (c - (ru * hx)) - p;\n        vec3 _881 = ru * (2.0 * hx);\n        float _887 = max(dot(_881, _881), 9.9999999392252902907785028219223e-09);\n        float _891 = dot(_875, _881);\n        float t = clamp((-_891) / _887, 0.0, 1.0);\n        if (_862)\n        {\n            float _906 = dot(r, _881);\n            float _912 = _887 - (_906 * _906);\n            if (abs(_912) > (9.9999997473787516355514526367188e-06 * _887))\n            {\n                t = clamp(((dot(r, _875) * _906) - _891) / _912, 0.0, 1.0);\n            }\n        }\n        return (p + _875) + (_881 * t);\n    }\n    vec3 q = p;\n    float _944 = dot(r, axis);\n    bool _952;\n    if (_862)\n    {\n        _952 = abs(_944) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _952 = _862;\n    }\n    if (_952)\n    {\n        float _962 = dot(c - p, axis) / _944;\n        if (_962 > 0.0)\n        {\n            q = p + (r * _962);\n        }\n    }\n    vec3 _975 = q - c;\n    vec2 xy = vec2(dot(_975, ru), dot(_975, uu));\n    if (shape > 0.5)\n    {\n        float _990 = length(xy);\n        if (_990 > hx)\n        {\n            xy *= (hx / _990);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _624 = abs(d);\n    float _626 = _624.x;\n    float _628 = _624.y;\n    bool _629 = _626 >= _628;\n    bool _637;\n    if (_629)\n    {\n        _637 = _626 >= _624.z;\n    }\n    else\n    {\n        _637 = _629;\n    }\n    int _638;\n    if (_637)\n    {\n        _638 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _652;\n        if (_628 >= _624.z)\n        {\n            _652 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _652 = (d.z > 0.0) ? 4 : 5;\n        }\n        _638 = _652;\n    }\n    return _638;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _782 = dot(d, right);\n    float _786 = dot(d, up);\n    float _797;\n    if (((_782 * _782) + (_786 * _786)) > 1.0000000133514319600180897396058e-10)\n    {\n        _797 = atan(_786, _782) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _797 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_797 - floor(_797)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1028 = fa_light_base(param);\n    bool _1032 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1028;\n    vec4 _1036 = fa_light_texel(param_1);\n    int param_2 = _1028 + 1;\n    vec4 _1041 = fa_light_texel(param_2);\n    float _1044 = _1041.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1056 = _1032 && (_1044 > 2.5);\n    fa_light_is_area = _1056;\n    bool _1058 = _1044 < 0.5;\n    vec3 l;\n    if (_1058)\n    {\n        l = normalize(_1036.xyz);\n        if (_1032)\n        {\n            int param_3 = _1028 + 6;\n            vec4 _1072 = fa_light_texel(param_3);\n            if (_1072.z > 0.5)\n            {\n                int param_4 = _1028 + 4;\n                vec4 _1082 = fa_light_texel(param_4);\n                int param_5 = _1028 + 5;\n                vec4 _1087 = fa_light_texel(param_5);\n                vec2 param_6 = _1072.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1082.xyz) * _1082.w, (-dot(world_pos, _1087.xyz)) * _1087.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1117 = _1036.xyz;\n        vec3 _1119 = _1117 - world_pos;\n        vec3 to_light = _1119;\n        float _1122 = length(_1119);\n        float reach = _1122;\n        bool front = true;\n        if (_1056)\n        {\n            int param_8 = _1028 + 7;\n            reach = max(_1122 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1028 + 4;\n            vec4 _1146 = fa_light_texel(param_9);\n            int param_10 = _1028 + 5;\n            vec4 _1151 = fa_light_texel(param_10);\n            int param_11 = _1028 + 6;\n            vec4 _1156 = fa_light_texel(param_11);\n            float _1157 = _1156.w;\n            int param_12 = _1028 + 2;\n            vec3 _1164 = normalize(fa_light_texel(param_12).xyz);\n            bool _1166 = _1157 > 1.5;\n            bool _1174;\n            if (!_1166)\n            {\n                _1174 = dot(_1164, to_light) < 0.0;\n            }\n            else\n            {\n                _1174 = _1166;\n            }\n            front = _1174;\n            vec3 r = vec3(0.0);\n            vec3 _1183 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1187 = dot(n, n) > 0.5;\n            bool _1195;\n            if (_1187)\n            {\n                _1195 = dot(_1183, _1183) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1195 = _1187;\n            }\n            if (_1195)\n            {\n                r = reflect(-normalize(_1183), normalize(n));\n            }\n            vec3 param_13 = _1117;\n            vec3 param_14 = _1164;\n            vec3 param_15 = _1146.xyz;\n            vec3 param_16 = _1151.xyz;\n            float param_17 = _1146.w;\n            float param_18 = _1151.w;\n            float param_19 = _1157;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1231 = length(to_light);\n        dist = _1231;\n        l = to_light / vec3(max(_1231, 9.9999997473787516355514526367188e-05));\n        float _1245 = reach / max(_1036.w, 0.001000000047497451305389404296875);\n        float _1251 = clamp(1.0 - (_1245 * _1245), 0.0, 1.0);\n        float _1253;\n        if (front)\n        {\n            _1253 = _1251 * _1251;\n        }\n        else\n        {\n            _1253 = 0.0;\n        }\n        atten = _1253;\n        bool _1264 = _1044 < 2.5;\n        if ((_1044 > 1.5) && _1264)\n        {\n            int param_22 = _1028 + 2;\n            vec4 _1272 = fa_light_texel(param_22);\n            float _1282 = _1272.w;\n            int param_23 = _1028 + 3;\n            vec4 _1287 = fa_light_texel(param_23);\n            float _1288 = _1287.x;\n            float cos_inner = _1288;\n            if (_1288 > 1.5)\n            {\n                cos_inner = mix(_1282, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1282, cos_inner, dot(-l, normalize(_1272.xyz)));\n        }\n        if (_1032 && (_1044 < 1.5))\n        {\n            int param_24 = _1028 + 6;\n            vec4 _1312 = fa_light_texel(param_24);\n            if (_1312.z > 0.5)\n            {\n                vec3 _1320 = -to_light;\n                int param_25 = _1028 + 4;\n                int param_26 = _1028 + 5;\n                vec3 _1334 = fa_light_texel(param_25).xyz;\n                vec3 _1338 = fa_light_texel(param_26).xyz;\n                vec3 _1347 = vec3(dot(_1320, _1334), dot(_1320, _1338), dot(_1320, cross(_1334, _1338)));\n                vec3 param_27 = _1347;\n                int _1351 = fa_cube_face(param_27);\n                int param_28 = _1351;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1378 = vec2(dot(_1347, cross(param_29, param_30)), dot(_1347, param_30)) / vec2(max(dot(_1347, param_29), 9.9999997473787516355514526367188e-05));\n                int _1382 = _1351 / 3;\n                vec2 param_31 = _1312.xy + (vec2(float(_1351 - (_1382 * 3)), float(_1382)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1378.x), 0.5 - (0.5 * _1378.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1028 + 7;\n            vec4 _1412 = fa_light_texel(param_33);\n            if (_1412.z > 0.5)\n            {\n                int param_34 = _1028 + 2;\n                int param_35 = _1028 + 4;\n                int param_36 = _1028 + 5;\n                vec2 param_37 = _1412.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1032 && _1264)\n            {\n                int param_42 = _1028 + 6;\n                vec4 _1459 = fa_light_texel(param_42);\n                int param_43 = _1028 + 7;\n                vec4 _1464 = fa_light_texel(param_43);\n                bool _1467 = _1459.z > 0.5;\n                bool _1474;\n                if (!_1467)\n                {\n                    _1474 = _1464.z > 0.5;\n                }\n                else\n                {\n                    _1474 = _1467;\n                }\n                if (_1474)\n                {\n                    int param_44 = _1028 + 2;\n                    vec4 _1481 = fa_light_texel(param_44);\n                    vec3 _1485 = normalize(_1481.xyz);\n                    int param_45 = _1028 + 4;\n                    vec4 _1490 = fa_light_texel(param_45);\n                    int param_46 = _1028 + 5;\n                    vec4 _1495 = fa_light_texel(param_46);\n                    if (_1467)\n                    {\n                        vec3 _1503 = -to_light;\n                        float _1510 = _1481.w;\n                        float _1526 = 0.5 / max(dot(_1503, _1485) * (sqrt(max(1.0 - (_1510 * _1510), 0.0)) / max(_1510, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1459.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1503, _1490.xyz) * _1526), 0.5 - (dot(_1503, _1495.xyz) * _1526));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1464.z > 0.5)\n                    {\n                        vec2 param_49 = _1464.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1485;\n                        vec3 param_52 = _1490.xyz;\n                        vec3 param_53 = _1495.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9865 = _1041.xyz * atten;\n    if (_1032)\n    {\n        _9865 *= fa_light_tint;\n    }\n    int _1595;\n    if (_1058)\n    {\n        _1595 = 0;\n    }\n    else\n    {\n        _1595 = ((_1044 > 1.5) && (_1044 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9865, atten, 1.0, dist, _1595);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2327;\n    if (i == 0)\n    {\n        _2327 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2343;\n        if (i == 1)\n        {\n            _2343 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2351;\n            if (i == 2)\n            {\n                _2351 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2351 = fa_shadows[24].w;\n            }\n            _2343 = _2351;\n        }\n        _2327 = _2343;\n    }\n    return _2327;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2384 = fa_shadow_depth(param, param_1);\n    float _2388;\n    if (conv.x < 0.5)\n    {\n        _2388 = _2384;\n    }\n    else\n    {\n        _2388 = (conv.y * conv.z) / (conv.z - (_2384 * (conv.z - conv.y)));\n    }\n    return _2388;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2434 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2440 = vec2(cos(_2434), sin(_2434));\n    vec2 dir = _2440;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2449;\n        if (k < 0.0)\n        {\n            _2449 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2449 = k;\n        }\n        float _2468 = clamp((_2449 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2487 = sqrt((float(i) + 0.5) * 0.0625) * _2468;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2487));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2501 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2501 < (zr - (_2487 * plane)))\n            {\n                sum += _2501;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2529 = sum / cnt;\n        float _2539;\n        if (k < 0.0)\n        {\n            _2539 = (-k) / max(_2529, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2539 = k;\n        }\n        radius = clamp(((max(zr - _2529, 0.0) * unit) * _2539) / texel_m, 1.5, 16.0);\n        dir = _2440;\n    }\n    float lit = 0.0;\n    int _2565 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2565; i_1++)\n    {\n        float _2584 = sqrt((float(i_1) + 0.5) / float(_2565)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2584));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2584 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2565);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2630 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2635 = clamp(dot(n, l), 0.0, 1.0);\n    float _2641 = sqrt(1.0 - (_2635 * _2635));\n    float _2649 = min(_2641 / max(_2635, 0.20000000298023223876953125), 4.0);\n    float _2654;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2654 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2654 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2679 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2654 * _2641)), 1.0);\n    float _2686 = _2679.x;\n    bool _2689 = _2686 < fa_shadows[ci * 1 + 16].x;\n    bool _2698;\n    if (!_2689)\n    {\n        _2698 = _2686 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2698 = _2689;\n    }\n    bool _2707;\n    if (!_2698)\n    {\n        _2707 = _2679.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2707 = _2698;\n    }\n    bool _2716;\n    if (!_2707)\n    {\n        _2716 = _2679.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2716 = _2707;\n    }\n    bool _2723;\n    if (!_2716)\n    {\n        _2723 = _2679.z > 1.0;\n    }\n    else\n    {\n        _2723 = _2716;\n    }\n    if (_2723)\n    {\n        return -1.0;\n    }\n    float _2731;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2731 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2731 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2679.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2679.z - ((_2731 * (1.0 + (0.5 * _2649))) / _2630);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2630;\n    float param_5 = _2630 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2649, 3.0)) * 0.5) / _2630;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3109 = int(fa_shadows[25].x + 0.5);\n    if (_3109 < 1)\n    {\n        return 1.0;\n    }\n    float _3124 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3109 - 1;\n    if (_3124 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3136 = _3109 > 1;\n    bool _3143;\n    if (_3136)\n    {\n        _3143 = _3124 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3143 = _3136;\n    }\n    if (_3143)\n    {\n        ci = 1;\n    }\n    bool _3147 = _3109 > 2;\n    bool _3154;\n    if (_3147)\n    {\n        _3154 = _3124 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3154 = _3147;\n    }\n    if (_3154)\n    {\n        ci = 2;\n    }\n    bool _3158 = _3109 > 3;\n    bool _3165;\n    if (_3158)\n    {\n        _3165 = _3124 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3165 = _3158;\n    }\n    if (_3165)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3176 = min(_3109, 4);\n    float _3217;\n    for (int c = ci; c < _3176; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3196 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3196;\n            break;\n        }\n        if (_3196 < 0.0)\n        {\n            continue;\n        }\n        s = _3196;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3217 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3217 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3236 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3217, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3124 - (fa_shadow_split_at(param_7) - _3236)) / _3236, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3268;\n        if ((ci + 1) < _3109)\n        {\n            _3268 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3268 = 1.0;\n        }\n        s = mix(s, _3268, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3373 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3379;\n    if (_3373)\n    {\n        _3379 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3379 = _3373;\n    }\n    if (_3379)\n    {\n        float _3393 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        vec4 _3401 = vec4(fa_world_pos, 1.0);\n        float _3407 = dot(fa_mesh_fs_params[28], _3401);\n        if (_3407 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3426 = vec2(dot(fa_mesh_fs_params[26], _3401), dot(fa_mesh_fs_params[27], _3401)) / vec2(_3407);\n            float _3431 = (_3426.x * 0.5) + 0.5;\n            float _3435;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3435 = (_3426.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3435 = 0.5 - (_3426.y * 0.5);\n            }\n            bool _3451 = _3431 >= 0.0;\n            bool _3457;\n            if (_3451)\n            {\n                _3457 = _3431 < 1.0;\n            }\n            else\n            {\n                _3457 = _3451;\n            }\n            bool _3463;\n            if (_3457)\n            {\n                _3463 = _3435 >= 0.0;\n            }\n            else\n            {\n                _3463 = _3457;\n            }\n            bool _3469;\n            if (_3463)\n            {\n                _3469 = _3435 < 1.0;\n            }\n            else\n            {\n                _3469 = _3463;\n            }\n            if (_3469)\n            {\n                vec4 _3494 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3431, _3435) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3497 = _3494.w > 0.5;\n                bool _3513;\n                if (_3497)\n                {\n                    _3513 = abs(_3393 - _3494.x) <= (((0.00200000009499490261077880859375 * _3393) + 0.00999999977648258209228515625) + fa_rt_slope);\n                }\n                else\n                {\n                    _3513 = _3497;\n                }\n                if (_3513)\n                {\n                    float _3519;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3519 = min(_3494.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3519 = _3494.y;\n                    }\n                    return _3519;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_rt_local_tap(ivec2 p, ivec2 size, float d, float tol, float div, inout float best)\n{\n    vec4 _3556 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(p, ivec2(0), size - ivec2(1)), 0);\n    bool _3559 = _3556.w > 0.5;\n    bool _3569;\n    if (_3559)\n    {\n        _3569 = abs(d - _3556.x) <= tol;\n    }\n    else\n    {\n        _3569 = _3559;\n    }\n    if (_3569)\n    {\n        best = min(best, mod(floor(_3556.z / div), 256.0) * 0.0039215688593685626983642578125);\n    }\n    return best;\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2789 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2796;\n    if (!_2789)\n    {\n        _2796 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2796 = _2789;\n    }\n    if (_2796)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2809 = fa_light_texel(param);\n    float _2810 = _2809.x;\n    if (_2810 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2819 = int(_2810 + 0.5);\n    int param_1 = _2819;\n    vec4 _2823 = fa_light_texel(param_1);\n    int param_2 = _2819 + 1;\n    vec4 _2828 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2831 = _2823.y;\n    if (_2831 > 0.0)\n    {\n        float _2848 = 1.0 - smoothstep(0.75 * _2831, _2831, length(world - fa_shadows[27].xyz));\n        fade = _2848;\n        if (_2848 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2823.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2872 = (_2819 + 2) + (face * 6);\n    int param_4 = _2872;\n    int param_5 = _2872 + 1;\n    int param_6 = _2872 + 3;\n    vec4 _2886 = fa_light_texel(param_6);\n    int param_7 = _2872 + 4;\n    vec4 _2891 = fa_light_texel(param_7);\n    int param_8 = _2872 + 5;\n    vec4 _2896 = fa_light_texel(param_8);\n    float _2908 = _2896.x * max(dot(_2886, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2913 = clamp(dot(n, l), 0.0, 1.0);\n    float _2936 = clamp(dot(n, _2886.xyz), -1.0, 1.0);\n    float _2955 = min(sqrt(1.0 - (_2936 * _2936)) / max(abs(dot(n, world - lpos)) / max(dot(_2886, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2958 = _2828.y;\n    float _2960;\n    if (_2958 > 0.0)\n    {\n        _2960 = _2958;\n    }\n    else\n    {\n        _2960 = 1.5 * _2908;\n    }\n    vec4 _2980 = vec4(world + (n * (_2960 * sqrt(1.0 - (_2913 * _2913)))), 1.0);\n    float _2984 = dot(_2886, _2980);\n    float _2987 = _2896.y;\n    if (_2984 < _2987)\n    {\n        return 1.0;\n    }\n    vec2 _3002 = vec2(dot(fa_light_texel(param_4), _2980), dot(fa_light_texel(param_5), _2980)) / vec2(_2984);\n    float _3004 = _3002.x;\n    bool _3007 = _3004 < _2891.x;\n    bool _3016;\n    if (!_3007)\n    {\n        _3016 = _3004 > _2891.z;\n    }\n    else\n    {\n        _3016 = _3007;\n    }\n    bool _3025;\n    if (!_3016)\n    {\n        _3025 = _3002.y < _2891.y;\n    }\n    else\n    {\n        _3025 = _3016;\n    }\n    bool _3034;\n    if (!_3025)\n    {\n        _3034 = _3002.y > _2891.w;\n    }\n    else\n    {\n        _3034 = _3025;\n    }\n    if (_3034)\n    {\n        return 1.0;\n    }\n    float _3040 = _2828.x;\n    float _3042;\n    if (_3040 > 0.0)\n    {\n        _3042 = _3040;\n    }\n    else\n    {\n        _3042 = 1.5 * _2908;\n    }\n    vec2 param_9 = _3002;\n    vec4 param_10 = _2891;\n    float param_11 = _2984 - (_3042 * (1.0 + (0.5 * _2955)));\n    float param_12 = _2908;\n    float param_13 = 1.0;\n    float param_14 = _2896.z * 0.25;\n    float param_15 = (_2908 * min(_2955, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2987, _2896.z);\n    int param_17 = int(_2823.z + 0.5);\n    float param_18 = _2823.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3587 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3593;\n    if (_3587)\n    {\n        _3593 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3593 = _3587;\n    }\n    bool _3599;\n    if (_3593)\n    {\n        _3599 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3599 = _3593;\n    }\n    if (_3599)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3611 = fa_light_texel(param);\n        float _3612 = _3611.z;\n        if (_3612 > 0.5)\n        {\n            float _3625 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3631 = ((0.00200000009499490261077880859375 * _3625) + 0.00999999977648258209228515625) + fa_rt_slope;\n            vec4 _3637 = vec4(world, 1.0);\n            float _3642 = dot(fa_mesh_fs_params[28], _3637);\n            if (_3642 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3659 = vec2(dot(fa_mesh_fs_params[26], _3637), dot(fa_mesh_fs_params[27], _3637)) / vec2(_3642);\n                float _3664 = (_3659.x * 0.5) + 0.5;\n                float _3668;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3668 = (_3659.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3668 = 0.5 - (_3659.y * 0.5);\n                }\n                bool _3684 = _3664 >= 0.0;\n                bool _3690;\n                if (_3684)\n                {\n                    _3690 = _3664 < 1.0;\n                }\n                else\n                {\n                    _3690 = _3684;\n                }\n                bool _3696;\n                if (_3690)\n                {\n                    _3696 = _3668 >= 0.0;\n                }\n                else\n                {\n                    _3696 = _3690;\n                }\n                bool _3702;\n                if (_3696)\n                {\n                    _3702 = _3668 < 1.0;\n                }\n                else\n                {\n                    _3702 = _3696;\n                }\n                if (_3702)\n                {\n                    ivec2 _3709 = ivec2(fa_mesh_fs_params[24].zw);\n                    ivec2 _3720 = clamp(ivec2(vec2(_3664, _3668) * fa_mesh_fs_params[24].zw), ivec2(0), _3709 - ivec2(1));\n                    float _3724;\n                    if (_3612 < 1.5)\n                    {\n                        _3724 = 1.0;\n                    }\n                    else\n                    {\n                        _3724 = (_3612 < 2.5) ? 256.0 : 65536.0;\n                    }\n                    float best = 2.0;\n                    vec4 _3740 = texelFetch(fa_screen_tex_fa_shadow_smp, _3720, 0);\n                    bool _3743 = _3740.w > 0.5;\n                    bool _3753;\n                    if (_3743)\n                    {\n                        _3753 = abs(_3625 - _3740.x) <= _3631;\n                    }\n                    else\n                    {\n                        _3753 = _3743;\n                    }\n                    if (_3753)\n                    {\n                        best = mod(floor(_3740.z / _3724), 256.0) * 0.0039215688593685626983642578125;\n                    }\n                    else\n                    {\n                        ivec2 param_1 = _3720 + ivec2(-1);\n                        ivec2 param_2 = _3709;\n                        float param_3 = _3625;\n                        float param_4 = _3631;\n                        float param_5 = _3724;\n                        float param_6 = best;\n                        float _3779 = fa_rt_local_tap(param_1, param_2, param_3, param_4, param_5, param_6);\n                        best = _3779;\n                        ivec2 param_7 = _3720 + ivec2(0, -1);\n                        ivec2 param_8 = _3709;\n                        float param_9 = _3625;\n                        float param_10 = _3631;\n                        float param_11 = _3724;\n                        float param_12 = _3779;\n                        float _3794 = fa_rt_local_tap(param_7, param_8, param_9, param_10, param_11, param_12);\n                        best = _3794;\n                        ivec2 param_13 = _3720 + ivec2(1, -1);\n                        ivec2 param_14 = _3709;\n                        float param_15 = _3625;\n                        float param_16 = _3631;\n                        float param_17 = _3724;\n                        float param_18 = _3794;\n                        float _3809 = fa_rt_local_tap(param_13, param_14, param_15, param_16, param_17, param_18);\n                        best = _3809;\n                        ivec2 param_19 = _3720 + ivec2(-1, 0);\n                        ivec2 param_20 = _3709;\n                        float param_21 = _3625;\n                        float param_22 = _3631;\n                        float param_23 = _3724;\n                        float param_24 = _3809;\n                        float _3824 = fa_rt_local_tap(param_19, param_20, param_21, param_22, param_23, param_24);\n                        best = _3824;\n                        ivec2 param_25 = _3720 + ivec2(1, 0);\n                        ivec2 param_26 = _3709;\n                        float param_27 = _3625;\n                        float param_28 = _3631;\n                        float param_29 = _3724;\n                        float param_30 = _3824;\n                        float _3839 = fa_rt_local_tap(param_25, param_26, param_27, param_28, param_29, param_30);\n                        best = _3839;\n                        ivec2 param_31 = _3720 + ivec2(-1, 1);\n                        ivec2 param_32 = _3709;\n                        float param_33 = _3625;\n                        float param_34 = _3631;\n                        float param_35 = _3724;\n                        float param_36 = _3839;\n                        float _3854 = fa_rt_local_tap(param_31, param_32, param_33, param_34, param_35, param_36);\n                        best = _3854;\n                        ivec2 param_37 = _3720 + ivec2(0, 1);\n                        ivec2 param_38 = _3709;\n                        float param_39 = _3625;\n                        float param_40 = _3631;\n                        float param_41 = _3724;\n                        float param_42 = _3854;\n                        float _3869 = fa_rt_local_tap(param_37, param_38, param_39, param_40, param_41, param_42);\n                        best = _3869;\n                        ivec2 param_43 = _3720 + ivec2(1);\n                        ivec2 param_44 = _3709;\n                        float param_45 = _3625;\n                        float param_46 = _3631;\n                        float param_47 = _3724;\n                        float param_48 = _3869;\n                        float _3884 = fa_rt_local_tap(param_43, param_44, param_45, param_46, param_47, param_48);\n                        best = _3884;\n                    }\n                    if (best <= 1.0)\n                    {\n                        float _3892;\n                        if (fa_mesh_fs_params[25].z > 0.5)\n                        {\n                            int param_49 = li;\n                            vec3 param_50 = lpos;\n                            vec3 param_51 = world;\n                            vec3 param_52 = n;\n                            vec3 param_53 = l;\n                            _3892 = min(best, fa_shadow_local(param_49, param_50, param_51, param_52, param_53));\n                        }\n                        else\n                        {\n                            _3892 = best;\n                        }\n                        return _3892;\n                    }\n                }\n            }\n            float _3915;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_54 = li;\n                vec3 param_55 = lpos;\n                vec3 param_56 = world;\n                vec3 param_57 = n;\n                vec3 param_58 = l;\n                _3915 = fa_shadow_local(param_54, param_55, param_56, param_57, param_58);\n            }\n            else\n            {\n                _3915 = 1.0;\n            }\n            return _3915;\n        }\n    }\n    int param_59 = li;\n    vec3 param_60 = lpos;\n    vec3 param_61 = world;\n    vec3 param_62 = n;\n    vec3 param_63 = l;\n    return fa_shadow_local(param_59, param_60, param_61, param_62, param_63);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5760 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5767;\n    if (!_5760)\n    {\n        _5767 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5767 = _5760;\n    }\n    if (_5767)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5780 = fa_light_texel(param);\n    float _5781 = _5780.y;\n    float len = _5781;\n    if (_5781 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5793 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5802 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5793);\n    if (_5802 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5808 = len;\n    float _5811 = min(_5808, 0.89999997615814208984375 * dist);\n    len = _5811;\n    float _5816 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5793);\n    float _5821 = _5816 + (0.5 * _5811);\n    vec3 _5827 = world + (gn * _5816);\n    float _5829 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5890;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5844 = (float(k) + _5829) * 0.083333335816860198974609375;\n        vec3 _5852 = _5827 + (l * (_5844 * len));\n        vec4 _5858 = vec4(_5852, 1.0);\n        float _5863 = dot(fa_mesh_fs_params[28], _5858);\n        if (_5863 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5881 = vec2(dot(fa_mesh_fs_params[26], _5858), dot(fa_mesh_fs_params[27], _5858)) / vec2(_5863);\n        float _5885 = _5881.x * 0.5;\n        float _5886 = _5885 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5890 = (_5881.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5890 = 0.5 - (_5881.y * 0.5);\n        }\n        bool _5906 = _5886 < 0.0;\n        bool _5913;\n        if (!_5906)\n        {\n            _5913 = _5886 >= 1.0;\n        }\n        else\n        {\n            _5913 = _5906;\n        }\n        bool _5920;\n        if (!_5913)\n        {\n            _5920 = _5890 < 0.0;\n        }\n        else\n        {\n            _5920 = _5913;\n        }\n        bool _5927;\n        if (!_5920)\n        {\n            _5927 = _5890 >= 1.0;\n        }\n        else\n        {\n            _5927 = _5920;\n        }\n        if (_5927)\n        {\n            break;\n        }\n        vec4 _5951 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5886, _5890) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5951.w < 0.5)\n        {\n            continue;\n        }\n        float _5969 = (dot(fa_mesh_fs_params[29].xyz, _5852) + fa_mesh_fs_params[29].w) - _5951.x;\n        if ((_5969 > _5816) && (_5969 < _5821))\n        {\n            occ = max(occ, (1.0 - (_5844 * _5844)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5886, 0.5 - _5885), min(_5890, 1.0 - _5890))));\n        }\n    }\n    return 1.0 - (occ * _5802);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6631 = fa_baked_keep(param);\n    if (_6631 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6657 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9934 = _6657.color;\n    float _9935 = _6657.attenuation;\n    float _9936 = _6657.shadow;\n    bool _6660 = _6657.type == 0;\n    if (_6660 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6657.direction;\n        float _6671 = fa_shadow_factor(param_5, param_6);\n        _9936 = _6671;\n        _9934 *= _6671;\n    }\n    else\n    {\n        bool _6682 = _6657.type != 0;\n        bool _6688;\n        if (_6682)\n        {\n            _6688 = _9935 > 0.0;\n        }\n        else\n        {\n            _6688 = _6682;\n        }\n        if (_6688)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6657.direction;\n            float _6707 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9936 = _6707;\n            _9934 *= _6707;\n        }\n    }\n    bool _6717 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6723;\n    if (_6717)\n    {\n        _6723 = _9935 > 0.0;\n    }\n    else\n    {\n        _6723 = _6717;\n    }\n    if (_6723)\n    {\n        float _6730;\n        if (_6660)\n        {\n            _6730 = 1000000000.0;\n        }\n        else\n        {\n            _6730 = _6657._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6657.direction;\n        float param_18 = _6730;\n        float _6748 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9936 *= _6748;\n        _9934 *= _6748;\n    }\n    float _6761 = _9935;\n    float _6762 = _6761 * _6631;\n    _9935 = _6762;\n    vec3 _6766 = _9934;\n    vec3 _6767 = _6766 * _6631;\n    _9934 = _6767;\n    return LightSample(_6657.direction, _6767, _6762, _9936, _6657._distance, _6657.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6801 = v - (n * dot(v, n));\n    vec3 t = _6801;\n    float _6805 = dot(_6801, _6801);\n    float l2 = _6805;\n    if (_6805 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6815;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6815 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6815 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6815;\n        l2 = dot(_6815, _6815);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _7202;\n    if ((j == 0) || (j == 7))\n    {\n        _7202 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7212;\n        if ((j == 3) || (j == 4))\n        {\n            _7212 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7212 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7202 = _7212;\n    }\n    float _7233;\n    if ((j == 1) || (j == 2))\n    {\n        _7233 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _7242;\n        if ((j == 5) || (j == 6))\n        {\n            _7242 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _7242 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _7233 = _7242;\n    }\n    return (pc + (ex * _7202)) + (ey * _7233);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6850 = dot(a, a);\n    float _6854 = dot(b, b);\n    if ((_6850 < 1.0000000195414813782625560981111e-24) || (_6854 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6868 = a * inversesqrt(_6850);\n    vec3 _6873 = b * inversesqrt(_6854);\n    float _6877 = dot(_6868, _6873);\n    float _6880 = abs(_6877);\n    float g = (((((((((((0.0416471660137176513671875 * _6880) - 0.1924748718738555908203125) * _6880) + 0.4179156124591827392578125) * _6880) - 0.616057217121124267578125) * _6880) + 0.777722418308258056640625) * _6880) - 0.999542415142059326171875) * _6880) + 1.570791721343994140625;\n    if (_6877 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6877 * _6877), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6868, _6873) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6937 = a.z > 0.0;\n    bool _6941 = b.z > 0.0;\n    if (_6937 && _6941)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6937 != _6941)\n        {\n            vec3 _6976 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6976.z = 0.0;\n            if (_6937)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6976;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6976;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6976;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6976;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _7025 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _7051 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _7077 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _7103 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _7025;\n    vec3 param_1 = _7051;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _7051;\n    vec3 param_7 = _7077;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _7077;\n    vec3 param_13 = _7103;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _7103;\n    vec3 param_19 = _7025;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _7271 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _7289;\n    for (int k = 0; k < (2 * _7271); k++)\n    {\n        bool _7286 = k >= _7271;\n        if (_7286)\n        {\n            _7289 = k - _7271;\n        }\n        else\n        {\n            _7289 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_7271 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7335 = 2 * _7289;\n            int param_4 = _7335 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7335 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7335 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7372 = bvec4(_7286);\n        vec4 param_16 = vec4(_7372.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7372.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7372.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7372.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7383 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_7286)\n        {\n            vec2 _10190 = sum;\n            _10190.y = _10190.y + _7383;\n            sum = _10190;\n        }\n        else\n        {\n            vec2 _10193 = sum;\n            _10193.x = _10193.x + _7383;\n            sum = _10193;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7407 = fa_light_base(param);\n    int param_1 = _7407;\n    int param_2 = _7407 + 1;\n    int param_3 = _7407 + 2;\n    int param_4 = _7407 + 4;\n    vec4 _7429 = fa_light_texel(param_4);\n    int param_5 = _7407 + 5;\n    vec4 _7434 = fa_light_texel(param_5);\n    int param_6 = _7407 + 6;\n    vec4 _7439 = fa_light_texel(param_6);\n    float _7440 = _7439.w;\n    vec3 _7445 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7447 = _7440 < 1.5;\n    bool _7454;\n    if (_7447)\n    {\n        _7454 = dot(normalize(fa_light_texel(param_3).xyz), _7445) >= 0.0;\n    }\n    else\n    {\n        _7454 = _7447;\n    }\n    if (_7454)\n    {\n        return vec3(0.0);\n    }\n    bool _7463 = (_7440 > 0.5) && _7447;\n    float _7467 = _7463 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7470 = _7429.xyz;\n    float _7472 = _7429.w;\n    vec3 _7478 = _7434.xyz;\n    float _7480 = _7434.w;\n    vec3 up = _7478 * (_7480 * _7467);\n    float _7486;\n    if (_7463)\n    {\n        _7486 = (3.1415927410125732421875 * _7472) * _7472;\n    }\n    else\n    {\n        _7486 = (4.0 * _7472) * _7480;\n    }\n    if (_7440 > 1.5)\n    {\n        vec3 _7512 = cross(_7470, -_7445);\n        vec3 perp = _7512;\n        float _7516 = dot(_7512, _7512);\n        vec3 _7519;\n        if (_7516 > 1.0000000133514319600180897396058e-10)\n        {\n            _7519 = perp * inversesqrt(_7516);\n        }\n        else\n        {\n            _7519 = _7478;\n        }\n        perp = _7519;\n        up = _7519 * _7480;\n    }\n    float _7540 = max(_7486, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7550 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7550;\n    vec3 param_10 = n;\n    vec3 param_11 = _7445;\n    vec3 param_12 = _7550;\n    vec3 param_13 = n;\n    vec3 param_14 = _7470 * (_7472 * _7467);\n    vec3 param_15 = _7550;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7581 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7581;\n    vec2 param_21 = _7581 + vec2(64.0, 0.0);\n    vec4 _7591 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7440;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7603 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7603.x) + (((f0 * _7591.x) + ((vec3(f90) - f0) * _7591.y)) * _7603.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7445, _7445)) + _7540) / _7540) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5497 = 1.0 / alpha;\n    return ((2.0 + _5497) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5497)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5532 = max(dot(L.nc, l), 0.0);\n    float _5538 = max(dot(L.nc, h), 0.0);\n    float _5547 = ((_5538 * _5538) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5547) * _5547)) * (0.5 / max(mix((2.0 * _5532) * L.coat_ndv, _5532 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5532)) * _5532;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7640;\n    if (L.sheen_on)\n    {\n        _7640 = L.sheen_scale;\n    }\n    else\n    {\n        _7640 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7640);\n    vec3 _7653 = normalize(l + v);\n    int param = li;\n    vec3 _7664 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7673 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7653), 0.0);\n        float param_3 = _7673;\n        float param_4 = ndv;\n        result += ((L.sheen * _7664) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7673)) * _7673) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7653;\n        float param_8 = max(dot(v, _7653), 0.0);\n        result += (_7664 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5400 = tdh / at;\n    float _5404 = bdh / ab;\n    float _5416 = ((_5400 * _5400) + (_5404 * _5404)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5416) * _5416);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5596 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5675 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5675) * _5675);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5596);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5596));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4799 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4802 = _4799.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4802 * _4802, exp2((-9.27999973297119140625) * ndv)) * _4802) + _4799.y)) + _4799.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _4109;\n    if (lv == 0)\n    {\n        _4109 = 0.0;\n    }\n    else\n    {\n        _4109 = res + 2.0;\n    }\n    float _4119;\n    if (lv == 0)\n    {\n        _4119 = 0.0;\n    }\n    else\n    {\n        _4119 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_4109, _4119)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4165;\n    if (res > 64.5)\n    {\n        _4165 = 5.0;\n    }\n    else\n    {\n        _4165 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4180 = clamp(rough, 0.0, 1.0) * (_4165 - 1.0);\n    int _4187 = int(min(floor(_4180), _4165 - 2.0));\n    float _4192 = _4180 - float(_4187);\n    vec3 param = d;\n    vec2 _4196 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4187;\n    vec2 param_4 = _4196;\n    vec3 _4206 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4192 < 0.00200000009499490261077880859375)\n    {\n        return _4206;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4187 + 1;\n    vec2 param_8 = _4196;\n    return mix(_4206, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4192));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4277 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4284 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4291 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4297 = dot(bx.xyz, d);\n    float _4301 = dot(by.xyz, d);\n    float _4305 = dot(bz.xyz, d);\n    float _4311;\n    if (_4297 > 9.9999999747524270787835121154785e-07)\n    {\n        _4311 = (1.0 - _4277) / _4297;\n    }\n    else\n    {\n        float _4325;\n        if (_4297 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4325 = ((-1.0) - _4277) / _4297;\n        }\n        else\n        {\n            _4325 = 1000000015047466219876688855040.0;\n        }\n        _4311 = _4325;\n    }\n    float tx = _4311;\n    float _4342;\n    if (_4301 > 9.9999999747524270787835121154785e-07)\n    {\n        _4342 = (1.0 - _4284) / _4301;\n    }\n    else\n    {\n        float _4355;\n        if (_4301 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4355 = ((-1.0) - _4284) / _4301;\n        }\n        else\n        {\n            _4355 = 1000000015047466219876688855040.0;\n        }\n        _4342 = _4355;\n    }\n    float ty = _4342;\n    float _4371;\n    if (_4305 > 9.9999999747524270787835121154785e-07)\n    {\n        _4371 = (1.0 - _4291) / _4305;\n    }\n    else\n    {\n        float _4384;\n        if (_4305 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4384 = ((-1.0) - _4291) / _4305;\n        }\n        else\n        {\n            _4384 = 1000000015047466219876688855040.0;\n        }\n        _4371 = _4384;\n    }\n    float _4396 = tx;\n    float _4399 = (_4396 > 0.0) ? _4396 : 1000000015047466219876688855040.0;\n    tx = _4399;\n    float _4400 = ty;\n    float _4403 = (_4400 > 0.0) ? _4400 : 1000000015047466219876688855040.0;\n    ty = _4403;\n    float _4413 = min(_4399, min(_4403, (_4371 > 0.0) ? _4371 : 1000000015047466219876688855040.0));\n    if (_4413 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4429 = (fa_world_pos + (d * _4413)) - posw.xyz;\n    vec3 _4434;\n    if (dot(_4429, _4429) > 1.0000000133514319600180897396058e-10)\n    {\n        _4434 = normalize(_4429);\n    }\n    else\n    {\n        _4434 = d;\n    }\n    return _4434;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4480 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4480 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4508 = rough * rough;\n            float _4539 = 0.60000002384185791015625 * _4508;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4508)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4539, 0.0500000007450580596923828125 + _4539, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4508 * 0.60000002384185791015625));\n        }\n        outc = base * _4480;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4598 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4598 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4630 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4630 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5277;\n        if (L.aniso >= 0.0)\n        {\n            _5277 = L.b;\n        }\n        else\n        {\n            _5277 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5277, v), _5277), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5313 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5313.x) + (vec3(L.f90) * _5313.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5371 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5371.x) + _5371.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4841 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4841.x) + vec3(_4841.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _6073 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _6077 = fa_xm_origin(param_1);\n    vec2 _6083 = (uv * _6073) - vec2(0.5);\n    vec2 _6086 = fract(_6083);\n    vec2 _6089 = floor(_6083);\n    vec2 param_2 = _6073;\n    vec2 param_3 = _6077;\n    vec2 param_4 = _6089;\n    vec2 param_5 = _6073;\n    vec2 param_6 = _6077;\n    vec2 param_7 = _6089 + vec2(1.0, 0.0);\n    vec2 param_8 = _6073;\n    vec2 param_9 = _6077;\n    vec2 param_10 = _6089 + vec2(0.0, 1.0);\n    vec2 param_11 = _6073;\n    vec2 param_12 = _6077;\n    vec2 param_13 = _6089 + vec2(1.0);\n    vec3 _6131 = vec3(_6086.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6131), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6131), vec3(_6086.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6150 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6154 = clamp(lod, 0.0, _6150);\n    int _6158 = int(floor(_6154));\n    int param = _6158;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6168 = float(_6158);\n    float _6169 = _6154 - _6168;\n    bool _6171 = _6169 > 0.001000000047497451305389404296875;\n    bool _6178;\n    if (_6171)\n    {\n        _6178 = _6168 < _6150;\n    }\n    else\n    {\n        _6178 = _6171;\n    }\n    if (_6178)\n    {\n        int param_2 = _6158 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6169));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6204 = fa_env_brdf(param, param_1);\n    vec3 _6228 = ((vec3(1.0) - clamp((f0 * _6204.x) + (vec3(f90) * _6204.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    vec3 through = _6228;\n    float _6234 = max(s.thickness, 0.0);\n    bool _6239 = _6234 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6239)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6234);\n    }\n    bool _6264 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6270;\n    if (_6264)\n    {\n        _6270 = fa_mesh_fs_params[30].w < 2.5;\n    }\n    else\n    {\n        _6270 = _6264;\n    }\n    bool _6277;\n    if (!_6270)\n    {\n        _6277 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6277 = _6270;\n    }\n    if (_6277)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec4 _6292 = vec4(fa_world_pos, 1.0);\n    float _6297 = dot(fa_mesh_fs_params[28], _6292);\n    vec2 uv0 = vec2(0.5);\n    if (_6297 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6315 = vec2(dot(fa_mesh_fs_params[26], _6292), dot(fa_mesh_fs_params[27], _6292)) / vec2(_6297);\n        float _6323;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6323 = (_6315.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6323 = 0.5 - (_6315.y * 0.5);\n        }\n        uv0 = vec2((_6315.x * 0.5) + 0.5, _6323);\n    }\n    if (fa_mesh_fs_params[30].w > 2.5)\n    {\n        int param_2 = 0;\n        vec2 _6344 = fa_xm_size(param_2);\n        vec2 _6352 = floor(clamp(uv0, vec2(0.0), vec2(0.99989998340606689453125)) * _6344);\n        if (texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(_6352), 0).w > 0.5)\n        {\n            int _6372 = int(floor((clamp(roughness, 0.0, 1.0) * 2.0) + 0.5));\n            vec3 acc = vec3(0.0);\n            float cnt = 0.0;\n            for (int dy = -2; dy <= 2; dy++)\n            {\n                for (int dx = -2; dx <= 2; dx++)\n                {\n                    bool _6395 = abs(dx) > _6372;\n                    bool _6403;\n                    if (!_6395)\n                    {\n                        _6403 = abs(dy) > _6372;\n                    }\n                    else\n                    {\n                        _6403 = _6395;\n                    }\n                    if (_6403)\n                    {\n                        continue;\n                    }\n                    vec4 _6424 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(clamp(_6352 + vec2(float(dx), float(dy)), vec2(0.0), _6344 - vec2(1.0))), 0);\n                    if (_6424.w > 0.5)\n                    {\n                        acc += _6424.xyz;\n                        cnt += 1.0;\n                    }\n                }\n            }\n            return _6228 * (acc / vec3(max(cnt, 1.0)));\n        }\n    }\n    vec2 uv = uv0;\n    if (_6239)\n    {\n        vec4 _6472 = vec4(fa_world_pos + (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6234), 1.0);\n        float _6477 = dot(fa_mesh_fs_params[28], _6472);\n        uv = vec2(0.5);\n        if (_6477 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _6494 = vec2(dot(fa_mesh_fs_params[26], _6472), dot(fa_mesh_fs_params[27], _6472)) / vec2(_6477);\n            float _6502;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _6502 = (_6494.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _6502 = 0.5 - (_6494.y * 0.5);\n            }\n            uv = vec2((_6494.x * 0.5) + 0.5, _6502);\n        }\n    }\n    vec2 param_3 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_4 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_3, param_4);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3296 = int(fa_shadows[25].x + 0.5);\n    float _3306 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3311 = _3296 > 0;\n    bool _3320;\n    if (_3311)\n    {\n        int param = _3296 - 1;\n        _3320 = _3306 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3320 = _3311;\n    }\n    if (_3320)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3326 = _3296 > 1;\n        bool _3333;\n        if (_3326)\n        {\n            _3333 = _3306 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3333 = _3326;\n        }\n        if (_3333)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3339 = _3296 > 2;\n        bool _3346;\n        if (_3339)\n        {\n            _3346 = _3306 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3346 = _3339;\n        }\n        if (_3346)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3352 = _3296 > 3;\n        bool _3359;\n        if (_3352)\n        {\n            _3359 = _3306 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3359 = _3352;\n        }\n        if (_3359)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_rt_slope = 0.0;\n    fa_inst_load();\n    vec3 _9593 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9593 = -_9593;\n    }\n    vec3 _8891 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9593, fa_world_tangent, fa_uv, fa_vertex_color, _8891, gl_FrontFacing);\n    Surface _8899 = fa_standard_surface(param_1);\n    vec3 _9624 = _8899.albedo;\n    float _9625 = _8899.alpha;\n    vec3 _9626 = _8899.normal;\n    float _9627 = _8899.metallic;\n    float _9628 = _8899.roughness;\n    float _9629 = _8899.occlusion;\n    vec3 _9630 = _8899.emission;\n    float _9631 = _8899.clearcoat;\n    float _9632 = _8899.clearcoat_roughness;\n    vec3 _9633 = _8899.sheen_color;\n    float _9634 = _8899.sheen_roughness;\n    float _9635 = _8899.anisotropy;\n    float _9636 = _8899.anisotropy_rotation;\n    float _9637 = _8899.specular;\n    float _9638 = _8899.ior;\n    vec3 _9639 = _8899.specular_color;\n    float _9640 = _8899.transmission;\n    float _9641 = _8899.thickness;\n    vec3 _9642 = _8899.attenuation_color;\n    float _9643 = _8899.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9593, fa_world_tangent, fa_uv, fa_vertex_color, _8891, gl_FrontFacing);\n    Surface param_3 = _8899;\n    surface(param_2, param_3);\n    _9624 = param_3.albedo;\n    _9625 = param_3.alpha;\n    _9626 = param_3.normal;\n    _9627 = param_3.metallic;\n    _9628 = param_3.roughness;\n    _9629 = param_3.occlusion;\n    _9630 = param_3.emission;\n    _9631 = param_3.clearcoat;\n    _9632 = param_3.clearcoat_roughness;\n    _9633 = param_3.sheen_color;\n    _9634 = param_3.sheen_roughness;\n    _9635 = param_3.anisotropy;\n    _9636 = param_3.anisotropy_rotation;\n    _9637 = param_3.specular;\n    _9638 = param_3.ior;\n    _9639 = param_3.specular_color;\n    _9640 = param_3.transmission;\n    _9641 = param_3.thickness;\n    _9642 = param_3.attenuation_color;\n    _9643 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9593;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9624 = param_6;\n    _9626 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9624;\n    }\n    else\n    {\n        vec3 _8939 = normalize(_9626);\n        float _8946 = clamp(_9627, 0.0, 1.0);\n        float _8950 = clamp(_9628, 0.0500000007450580596923828125, 1.0);\n        float _8954 = _8950 * _8950;\n        float _8958 = _8954 * _8954;\n        float _8963 = max(dot(_8939, _8891), 9.9999997473787516355514526367188e-05);\n        float _8969 = 1.0 - _8946;\n        float _8970 = clamp(_9640, 0.0, 1.0) * _8969;\n        vec3 _8979 = (_9624 * _8969) * (1.0 - _8970);\n        vec3 _8986 = mix(vec3(0.039999999105930328369140625), _9624, vec3(_8946));\n        vec3 f0 = _8986;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9593, fa_world_tangent, fa_uv, fa_vertex_color, _8891, gl_FrontFacing);\n        Surface param_9 = Surface(_9624, _9625, _9626, _9627, _9628, _9629, _9630, _9631, _9632, _9633, _9634, _9635, _9636, _9637, _9638, _9639, _9640, _9641, _9642, _9643);\n        vec3 param_10 = _8939;\n        vec3 param_11 = _8891;\n        float param_12 = _8946;\n        float param_13 = _8950;\n        vec3 param_14 = _8986;\n        FaLayers _9002 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8939;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8979) * _9629;\n        if (_9002.on)\n        {\n            lit *= _9002.base_scale;\n        }\n        int _9024 = fa_cl_ndir + fa_cl_local;\n        float _9089;\n        for (int ln = 0; ln < _9024; ln++)\n        {\n            int param_16 = ln;\n            int _9037 = fa_cl_light(param_16);\n            int param_17 = _9037;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _9037;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9593;\n            LightSample _9053 = fa_light_shadowed(param_18, param_19, param_20);\n            float _9061 = max(dot(_8939, _9053.direction), 0.0);\n            float _9067 = _9053.attenuation * _9053.shadow;\n            vec3 _9072 = normalize(_9053.direction + _8891);\n            float _9077 = max(dot(_8939, _9072), 0.0);\n            float _9082 = max(dot(_8891, _9072), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_9002.on)\n                {\n                    _9089 = _9002.f90;\n                }\n                else\n                {\n                    _9089 = 1.0;\n                }\n                int param_21 = _9037;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8939;\n                vec3 param_24 = _8891;\n                vec3 param_25 = _8979;\n                vec3 param_26 = f0;\n                float param_27 = _9089;\n                float param_28 = _8950;\n                float param_29 = _8963;\n                float param_30 = _9067;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_9002.on)\n                {\n                    FaLayers param_31 = _9002;\n                    vec3 param_32 = area;\n                    int param_33 = _9037;\n                    vec3 param_34 = _8939;\n                    vec3 param_35 = _8891;\n                    vec3 param_36 = _9053.direction;\n                    float param_37 = _8963;\n                    float param_38 = _9067;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_9002.on)\n                {\n                    FaLayers param_39 = _9002;\n                    vec3 param_40 = _8979;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8939;\n                    vec3 param_43 = _8891;\n                    vec3 param_44 = _9053.direction;\n                    vec3 param_45 = _9072;\n                    float param_46 = _9061;\n                    float param_47 = _8963;\n                    float param_48 = _9077;\n                    float param_49 = _9082;\n                    float param_50 = _8954;\n                    float param_51 = _8958;\n                    int param_52 = _9037;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _9067));\n                }\n                else\n                {\n                    float _9191 = ((_9077 * _9077) * (_8958 - 1.0)) + 1.0;\n                    int param_53 = _9037;\n                    lit += (((_8979 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _9082, 5.0))) * (((_8958 / ((3.1415927410125732421875 * _9191) * _9191)) * (0.5 / max(mix((2.0 * _9061) * _8963, _9061 + _8963, _8954), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _9061))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_9061 * _9067));\n                }\n            }\n        }\n        if (_9002.on)\n        {\n            FaLayers param_54 = _9002;\n            vec3 param_55 = _8939;\n            vec3 param_56 = _8891;\n            vec3 param_57 = f0;\n            float param_58 = _8950;\n            float param_59 = _9629;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8939;\n            vec3 param_61 = _8891;\n            vec3 param_62 = f0;\n            float param_63 = _8950;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9629);\n        }\n        if (_8970 > 0.0)\n        {\n            float _9289;\n            if (_9002.on)\n            {\n                _9289 = _9002.f90;\n            }\n            else\n            {\n                _9289 = 1.0;\n            }\n            float _9297;\n            if (_9002.on)\n            {\n                _9297 = _9002.base_scale;\n            }\n            else\n            {\n                _9297 = 1.0;\n            }\n            Surface param_64 = Surface(_9624, _9625, _9626, _9627, _9628, _9629, _9630, _9631, _9632, _9633, _9634, _9635, _9636, _9637, _9638, _9639, _9640, _9641, _9642, _9643);\n            vec3 param_65 = _8939;\n            vec3 param_66 = _8891;\n            float param_67 = _8950;\n            vec3 param_68 = f0;\n            float param_69 = _9289;\n            float param_70 = _9297;\n            float param_71 = _8970;\n            float param_72 = fa_tr_blend;\n            vec3 _9321 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _9321;\n        }\n        result = lit;\n    }\n    vec3 _9328 = result;\n    vec3 _9329 = _9328 + _9630;\n    result = _9329;\n    vec3 param_73 = _9329;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _9338 = fa_mesh_fs_params[7].w > 0.0;\n    bool _9345;\n    if (!_9338)\n    {\n        _9345 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _9345 = _9338;\n    }\n    if (_9345)\n    {\n        vec3 _9354 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _9360 = dot(_9354, fa_mesh_fs_params[9].xyz);\n        bool _9364 = fa_mesh_fs_params[9].w > 0.5;\n        float _9365;\n        if (_9364)\n        {\n            _9365 = _9360;\n        }\n        else\n        {\n            _9365 = length(_9354);\n        }\n        float _9377 = _9365 - fa_mesh_fs_params[8].x;\n        if (_9377 > 0.0)\n        {\n            float _9386 = fa_mesh_fs_params[7].w * _9377;\n            float tau = _9386 * _9386;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9402;\n                if (_9364)\n                {\n                    _9402 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _9360);\n                }\n                else\n                {\n                    _9402 = fa_mesh_fs_params[0].y;\n                }\n                float _9423 = mix(_9402, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _9365, 0.0, 1.0));\n                float _9427 = fa_world_pos.y - _9423;\n                float _9432 = _9423 - fa_mesh_fs_params[8].z;\n                float _9437 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9440 = _9432 <= 0.0;\n                bool _9441 = !_9440;\n                bool _9447;\n                if (_9441)\n                {\n                    _9447 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9447 = _9440;\n                }\n                float _9448;\n                if (_9447)\n                {\n                    _9448 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9448 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9432, 80.0));\n                }\n                bool _9475;\n                if (_9441)\n                {\n                    _9475 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9475 = _9440;\n                }\n                float _9476;\n                if (_9475)\n                {\n                    _9476 = fa_mesh_fs_params[8].y * _9432;\n                }\n                else\n                {\n                    _9476 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9432, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9501 = _9437 <= 0.0;\n                bool _9508;\n                if (!_9501)\n                {\n                    _9508 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9508 = _9501;\n                }\n                float _9509;\n                if (_9508)\n                {\n                    _9509 = fa_mesh_fs_params[8].y * _9437;\n                }\n                else\n                {\n                    _9509 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9437, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9536;\n                if (abs(_9427) < 0.001000000047497451305389404296875)\n                {\n                    _9536 = _9448;\n                }\n                else\n                {\n                    _9536 = (_9509 - _9476) / _9427;\n                }\n                tau += (_9377 * max(_9536, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9572 = 1.0 - fa_tr_blend;\n        result /= vec3(_9572);\n        _9625 *= _9572;\n    }\n    fa_frag_color = vec4(result, _9625);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_675",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2337",
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
            "inst_name": "_7741",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
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
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) out vec3 fa_vel_cur;\nlayout(location = 12) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _121 = cross(model[1].xyz, model[2].xyz);\n    float _125 = (dot(model[0].xyz, _121) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_121 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _125, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _125), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _252;\n    if (has_prev)\n    {\n        _252 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _252 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _275 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _282 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_275 * _282).z;\n    fa_pre_r0 = vec3(_275[0].x, _275[1].x, _275[2].x);\n    fa_pre_r1 = vec3(_275[0].y, _275[1].y, _275[2].y);\n    fa_pre_r2 = vec3(_275[0].z, _275[1].z, _275[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _282;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_252)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _282).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nlayout(location = 11) in vec3 fa_vel_cur;\nlayout(location = 12) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _269 = fa_tex_fix(param_2, param_3);\n    vec4 _876 = base_t;\n    _876.x = _269.x;\n    _876.y = _269.y;\n    _876.z = _269.z;\n    base_t = _876;\n    vec4 _285 = (_876 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _831 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _320 = fa_tex_fix(param_6, param_7);\n        vec3 _324 = (_320 * 2.0) - vec3(1.0);\n        vec2 _329 = _324.xy * fa_mesh_fs_params[6].x;\n        vec3 _884 = _324;\n        _884.x = _329.x;\n        _884.y = _329.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _884;\n        _831 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _360 = fa_tex_fix(param_12, param_13);\n    vec4 _887 = mrt;\n    _887.x = _360.x;\n    _887.y = _360.y;\n    _887.z = _360.z;\n    mrt = _887;\n    vec4 _392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _404 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _436 = fa_tex_fix(param_20, param_21);\n    float _836 = fa_mesh_fs_params[20].x;\n    float _837 = fa_mesh_fs_params[20].y;\n    float _840 = fa_mesh_fs_params[20].z;\n    float _839 = fa_mesh_fs_params[21].w;\n    float _842 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _836 *= _404.y;\n            _837 *= _404.z;\n            _839 *= _392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _840 *= mrt.x;\n            _842 *= mrt.w;\n        }\n    }\n    return Surface(_285.xyz, _285.w, _831, clamp(fa_mesh_fs_params[5].x * _360.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _360.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_404.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _436), _836, _837, fa_mesh_fs_params[21].xyz, _839, _840, fa_mesh_fs_params[20].w, _842, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _726 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _726 = -_726;\n    }\n    vec3 _587 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _602 = normalize(param_2.normal);\n    vec3 _617 = normalize(vec3(dot(fa_pre_r0, _602), dot(fa_pre_r1, _602), dot(fa_pre_r2, _602)));\n    float _629 = _617.z;\n    vec2 e = _617.xy / vec2((abs(_617.x) + abs(_617.y)) + abs(_629));\n    if (_629 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _673 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _680;\n    if (_673)\n    {\n        _680 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _680 = _673;\n    }\n    if (_680)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_68",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_246",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_254",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) out vec3 fa_vel_cur;\nlayout(location = 12) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 13) in vec4 fa_prev_r0;\nlayout(location = 14) in vec4 fa_prev_r1;\nlayout(location = 15) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _225 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_225 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_225 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_225 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _137 = cross(model[1].xyz, model[2].xyz);\n    float _141 = (dot(model[0].xyz, _137) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_137 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _141, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _141), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _353 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _353;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _353 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _353 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _496;\n    if (has_prev)\n    {\n        _496 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _496 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _519 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _526 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_519 * _526).z;\n    fa_pre_r0 = vec3(_519[0].x, _519[1].x, _519[2].x);\n    fa_pre_r1 = vec3(_519[0].y, _519[1].y, _519[2].y);\n    fa_pre_r2 = vec3(_519[0].z, _519[1].z, _519[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _526;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_496)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _526).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nlayout(location = 11) in vec3 fa_vel_cur;\nlayout(location = 12) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _269 = fa_tex_fix(param_2, param_3);\n    vec4 _876 = base_t;\n    _876.x = _269.x;\n    _876.y = _269.y;\n    _876.z = _269.z;\n    base_t = _876;\n    vec4 _285 = (_876 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _831 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _320 = fa_tex_fix(param_6, param_7);\n        vec3 _324 = (_320 * 2.0) - vec3(1.0);\n        vec2 _329 = _324.xy * fa_mesh_fs_params[6].x;\n        vec3 _884 = _324;\n        _884.x = _329.x;\n        _884.y = _329.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _884;\n        _831 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _360 = fa_tex_fix(param_12, param_13);\n    vec4 _887 = mrt;\n    _887.x = _360.x;\n    _887.y = _360.y;\n    _887.z = _360.z;\n    mrt = _887;\n    vec4 _392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _404 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _436 = fa_tex_fix(param_20, param_21);\n    float _836 = fa_mesh_fs_params[20].x;\n    float _837 = fa_mesh_fs_params[20].y;\n    float _840 = fa_mesh_fs_params[20].z;\n    float _839 = fa_mesh_fs_params[21].w;\n    float _842 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _836 *= _404.y;\n            _837 *= _404.z;\n            _839 *= _392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _840 *= mrt.x;\n            _842 *= mrt.w;\n        }\n    }\n    return Surface(_285.xyz, _285.w, _831, clamp(fa_mesh_fs_params[5].x * _360.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _360.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_404.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _436), _836, _837, fa_mesh_fs_params[21].xyz, _839, _840, fa_mesh_fs_params[20].w, _842, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _726 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _726 = -_726;\n    }\n    vec3 _587 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _602 = normalize(param_2.normal);\n    vec3 _617 = normalize(vec3(dot(fa_pre_r0, _602), dot(fa_pre_r1, _602), dot(fa_pre_r2, _602)));\n    float _629 = _617.z;\n    vec2 e = _617.xy / vec2((abs(_617.x) + abs(_617.y)) + abs(_629));\n    if (_629 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _673 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _680;\n    if (_673)\n    {\n        _680 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _680 = _673;\n    }\n    if (_680)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 14,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 15,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_85",
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
            "inst_name": "_234",
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
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_491",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_254",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "texture": {
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
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
