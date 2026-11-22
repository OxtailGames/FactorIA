{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "4c53dbda8aab388115fbab7a39659e445919577d7a668a882fd90e50900366c5",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4361[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1594 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1601;\n    if (!_1594)\n    {\n        _1601 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1601 = _1594;\n    }\n    bool _1609;\n    if (!_1601)\n    {\n        _1609 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1609 = _1601;\n    }\n    bool _1616;\n    if (!_1609)\n    {\n        _1616 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1616 = _1609;\n    }\n    bool _1623;\n    if (!_1616)\n    {\n        _1623 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1623 = _1616;\n    }\n    if (_1623)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1633 = vec4(world_pos, 1.0);\n    float _1639 = dot(fa_mesh_fs_params[16], _1633);\n    if (!(_1639 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1661 = vec2(dot(fa_mesh_fs_params[14], _1633), dot(fa_mesh_fs_params[15], _1633)) / vec2(_1639);\n    int _1665 = int(fa_mesh_fs_params[18].x);\n    int _1669 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1669) + clamp(int(floor(((_1661.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1669 - 1)) * _1665)) + clamp(int(floor(((_1661.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1665 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1745 = fa_cluster_texel(param);\n    return ivec2(int(_1745.x), int(_1745.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5836 = fa_cluster_lookup(param);\n    fa_cl_slot = _5836.x;\n    fa_cl_local = _5836.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7025 = fa_linear_to_srgb(param);\n        c = _7025;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7033 = fa_srgb_to_linear(param_1);\n            c = _7033;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _538;\n    if (i.front_facing)\n    {\n        _538 = i.world_normal;\n    }\n    else\n    {\n        _538 = -i.world_normal;\n    }\n    vec3 _562 = normalize(i.world_tangent.xyz - (_538 * dot(_538, i.world_tangent.xyz)));\n    vec3 _589 = normalize(((_562 * m.x) + ((cross(_538, _562) * i.world_tangent.w) * m.y)) + (_538 * m.z));\n    vec3 _592;\n    if (i.front_facing)\n    {\n        _592 = _589;\n    }\n    else\n    {\n        _592 = -_589;\n    }\n    return _592;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7064 = fa_tex_fix(param_2, param_3);\n    vec4 _9326 = base_t;\n    _9326.x = _7064.x;\n    _9326.y = _7064.y;\n    _9326.z = _7064.z;\n    base_t = _9326;\n    vec4 _7078 = (_9326 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9102 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7110 = fa_tex_fix(param_6, param_7);\n        vec3 _7113 = (_7110 * 2.0) - vec3(1.0);\n        vec2 _7118 = _7113.xy * fa_mesh_fs_params[6].x;\n        vec3 _9334 = _7113;\n        _9334.x = _7118.x;\n        _9334.y = _7118.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9334;\n        _9102 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7146 = fa_tex_fix(param_12, param_13);\n    vec4 _9337 = mrt;\n    _9337.x = _7146.x;\n    _9337.y = _7146.y;\n    _9337.z = _7146.z;\n    mrt = _9337;\n    vec4 _7174 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7174.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7185 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7215 = fa_tex_fix(param_20, param_21);\n    float _9107 = fa_mesh_fs_params[20].x;\n    float _9108 = fa_mesh_fs_params[20].y;\n    float _9111 = fa_mesh_fs_params[20].z;\n    float _9110 = fa_mesh_fs_params[21].w;\n    float _9113 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9107 *= _7185.y;\n            _9108 *= _7185.z;\n            _9110 *= _7174.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9111 *= mrt.x;\n            _9113 *= mrt.w;\n        }\n    }\n    return Surface(_7078.xyz, _7078.w, _9102, clamp(fa_mesh_fs_params[5].x * _7146.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7146.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7185.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7215), _9107, _9108, fa_mesh_fs_params[21].xyz, _9110, _9111, fa_mesh_fs_params[20].w, _9113, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1825 = rect.zw - rect.xy;\n    vec2 _1829 = _1825 * atlas;\n    vec2 _1833 = ddx * _1829;\n    vec2 _1837 = ddy * _1829;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1825), clamp(0.5 * log2(max(max(dot(_1833, _1833), dot(_1837, _1837)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1870 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1877;\n    if (!_1870)\n    {\n        _1877 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1877 = _1870;\n    }\n    if (_1877)\n    {\n        return;\n    }\n    vec3 _1883 = dFdx(world_pos);\n    vec3 _1886 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1890 = fa_cluster_texel(param);\n    int _1894 = int(_1890.w);\n    if (_1894 < 1)\n    {\n        return;\n    }\n    int _1904 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1904;\n    vec4 _1908 = fa_light_texel(param_1);\n    vec2 _1911 = _1908.yz;\n    int _1915 = int(_1908.w);\n    int param_2 = _1904 + 1;\n    vec4 _1920 = fa_light_texel(param_2);\n    float _1921 = _1920.x;\n    int _1927 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1931 = int(_1890.z);\n    vec3 _2196;\n    for (int k = 0; k < _1894; k++)\n    {\n        int _1944 = _1931 + k;\n        int param_3 = _1915 + (_1944 >> 2);\n        int _1961 = (_1904 + 2) + (int(fa_light_texel(param_3)[_1944 & 3]) * 7);\n        int param_4 = _1961 + 6;\n        vec4 _1966 = fa_light_texel(param_4);\n        if (((int(_1966.w + 0.5) >> _1927) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1961;\n        vec4 _1981 = fa_light_texel(param_5);\n        int param_6 = _1961 + 1;\n        vec4 _1986 = fa_light_texel(param_6);\n        int param_7 = _1961 + 2;\n        vec4 _1991 = fa_light_texel(param_7);\n        vec3 _1994 = _1981.xyz;\n        float _1999 = dot(_1994, world_pos) + _1981.w;\n        vec3 _2001 = _1986.xyz;\n        float _2006 = dot(_2001, world_pos) + _1986.w;\n        vec3 _2008 = _1991.xyz;\n        float _2013 = dot(_2008, world_pos) + _1991.w;\n        bool _2018 = abs(_1999) > 0.5;\n        bool _2026;\n        if (!_2018)\n        {\n            _2026 = abs(_2006) > 0.5;\n        }\n        else\n        {\n            _2026 = _2018;\n        }\n        bool _2034;\n        if (!_2026)\n        {\n            _2034 = abs(_2013) > 0.5;\n        }\n        else\n        {\n            _2034 = _2026;\n        }\n        if (_2034)\n        {\n            continue;\n        }\n        float _2049 = clamp(dot(geo_normal, normalize(_2008)) * _1966.z, 0.0, 1.0);\n        if (_2049 <= 0.0)\n        {\n            continue;\n        }\n        float _2069 = (clamp((0.5 - abs(_2013)) * 10.0, 0.0, 1.0) * _2049) * _1966.x;\n        vec2 _2077 = vec2(_1999 + 0.5, 0.5 - _2006);\n        vec2 _2087 = vec2(dot(_1994, _1883), dot(_2001, _1883));\n        vec2 _2097 = vec2(dot(_1994, _1886), dot(_2001, _1886));\n        int param_8 = _1961 + 5;\n        vec4 _2102 = fa_light_texel(param_8);\n        int param_9 = _1961 + 3;\n        vec4 _2107 = fa_light_texel(param_9);\n        int param_10 = _1961 + 4;\n        vec4 _2112 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2102.xyz;\n        bool _2122 = _2107.z > _2107.x;\n        if (_2122)\n        {\n            vec4 param_11 = _2107;\n            vec2 param_12 = _2077;\n            vec2 param_13 = _1911;\n            vec2 param_14 = _2087;\n            vec2 param_15 = _2097;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1921 > 0.5) && (_1921 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2148 = fa_dc_to_linear(param_16);\n                vec4 _9190 = tx;\n                _9190.x = _2148.x;\n                _9190.y = _2148.y;\n                _9190.z = _2148.z;\n                tx = _9190;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2069 * tex_a) * _2102.w, 0.0, 1.0)));\n        if (_2112.z > _2112.x)\n        {\n            vec4 param_17 = _2112;\n            vec2 param_18 = _2077;\n            vec2 param_19 = _1911;\n            vec2 param_20 = _2087;\n            vec2 param_21 = _2097;\n            vec4 _2192 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1921 > 1.5)\n            {\n                vec3 param_22 = _2192.xyz;\n                vec3 _2202 = fa_dc_to_srgb(param_22);\n                _2196 = _2202;\n            }\n            else\n            {\n                _2196 = _2192.xyz;\n            }\n            vec3 _2211 = (_2196 * 2.0) - vec3(1.0);\n            vec2 _2216 = _2211.xy * _1966.y;\n            vec3 _2238 = (normalize(_1994) * _2216.x) + (normalize(_2001) * _2216.y);\n            vec3 _2241 = normalize(normal);\n            normal = normalize(mix(_2241, normalize((_2241 * max(_2211.z, 0.0500000007450580596923828125)) + (_2238 - (_2241 * dot(_2241, _2238)))), vec3(clamp(_2069 * (_2122 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4286 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4294 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4297 = int(_4286);\n    int _4300 = int(_4294);\n    float _4310 = _4294 - float(_4300);\n    int _4365 = (_4297 * 9) + _4300;\n    int _4385 = ((_4297 + 1) * 9) + _4300;\n    return mix(mix(_4361[_4365], _4361[_4365 + 1], _4310), mix(_4361[_4385], _4361[_4385 + 1], _4310), _4286 - float(_4297));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9025 = false;\n    float _9026 = 1.0;\n    float _9027 = 1.0;\n    float _9028 = 1.0;\n    float _9029 = 0.0;\n    float _9030 = 0.0;\n    float _9031 = 0.0;\n    float _9032 = 0.0;\n    float _9034 = 1.0;\n    bool _9035 = false;\n    vec3 _9036 = vec3(0.0);\n    float _9037 = 1.0;\n    float _9038 = 1.0;\n    float _9039 = 1.0;\n    float _9040 = 0.0;\n    float _9041 = 0.0;\n    vec3 _9042 = vec3(1.0, 0.0, 0.0);\n    vec3 _9043 = vec3(0.0, 0.0, 1.0);\n    float _9044 = 1.0;\n    float _9045 = 1.0;\n    float _4436 = clamp(s.specular, 0.0, 1.0);\n    float _4440 = clamp(s.ior, 1.0, 3.0);\n    bool _4445 = (_4436 != 1.0) || (_4440 != 1.5);\n    bool _4454;\n    if (!_4445)\n    {\n        _4454 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4454 = _4445;\n    }\n    if (_4454)\n    {\n        float _4462 = (_4440 - 1.0) / (_4440 + 1.0);\n        f0 = mix(min(vec3(_4462 * _4462) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4436, s.albedo, vec3(metallic));\n        _9026 = mix(_4436, 1.0, metallic);\n        _9025 = true;\n    }\n    float _4489 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4489 > 0.0)\n    {\n        float _4497 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9029 = _4489;\n        _9030 = _4497;\n        float _4504 = _4497 * _4497;\n        _9031 = _4504;\n        _9032 = _4504 * _4504;\n        float _4516 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9034 = _4516;\n        _9027 = 1.0 - (_4489 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4516, 0.0, 1.0), 5.0))));\n        _9025 = true;\n    }\n    vec3 _4535 = max(s.sheen_color, vec3(0.0));\n    float _4544 = max(_4535.x, max(_4535.y, _4535.z));\n    if (_4544 > 0.0)\n    {\n        float _4552 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9035 = true;\n        _9036 = _4535;\n        _9037 = _4552;\n        _9038 = _4552 * _4552;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4552;\n        float _4569 = fa_sheen_albedo(param, param_1);\n        _9040 = _4569;\n        _9039 = 1.0 - min(_4544 * _4569, 1.0);\n        _9025 = true;\n    }\n    _9028 = _9027 * _9039;\n    float _4588 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4588 != 0.0)\n    {\n        vec3 _4603 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4603;\n        if (dot(_4603, _4603) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4615 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4615.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4615.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4615.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4619 = t;\n        vec3 _4620 = normalize(_4619);\n        t = _4620;\n        vec3 _4645 = normalize((_4620 * cos(s.anisotropy_rotation)) + ((cross(n, _4620) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9042 = _4645;\n        _9043 = cross(n, _4645);\n        float _4655 = roughness * roughness;\n        float _4661 = mix(_4655, 1.0, _4588 * _4588);\n        bool _4663 = _4588 > 0.0;\n        _9044 = _4663 ? _4661 : _4655;\n        _9045 = _4663 ? _4655 : _4661;\n        _9041 = _4588;\n        _9025 = true;\n    }\n    return FaLayers(_9025, _9026, _9027, _9028, _9029, _9030, _9031, _9032, i.world_normal, _9034, _9035, _9036, _9037, _9038, _9039, _9040, _9041, _9042, _9043, _9044, _9045);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3454 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3454;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4067 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4072 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4067 > 0.0005000000237487256526947021484375)\n    {\n        if (_4072)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4067;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4067;\n        }\n    }\n    bool _4123 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4123)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4154 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4154)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4072 || _4123) || _4154)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3474 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3477 = _3474.x;\n    float _3479 = _3474.z;\n    vec2 e = vec2(_3477, _3479);\n    if (_3474.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3479)) * ((_3477 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3477)) * ((_3479 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7325 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7330 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7335 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7340 = fa_light_texel(param_3);\n    bool _7343 = _7340.z < 0.5;\n    bool _7351;\n    if (!_7343)\n    {\n        _7351 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7351 = _7343;\n    }\n    if (_7351)\n    {\n        return vec3(0.0);\n    }\n    float _7358 = max(_7325.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7361 = _7330.xyz;\n    vec3 _7365 = _7325.xyz;\n    vec3 _7369 = (fa_world_pos - _7365) / vec3(_7358);\n    vec3 _7378 = min(_7369 + vec3(0.5), (_7361 - vec3(0.5)) - _7369);\n    float _7387 = min(_7378.x, min(_7378.y, _7378.z));\n    if (!(_7387 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7402 = _7361 - vec3(1.0);\n    vec3 _7403 = clamp(_7369, vec3(0.0), _7402);\n    vec3 _7411 = min(floor(_7403), max(_7361 - vec3(2.0), vec3(0.0)));\n    vec3 _7415 = _7403 - _7411;\n    vec3 _7426 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7358));\n    int _7431 = int(_7335.y + 0.5);\n    float _7436 = 0.3257350027561187744140625 * n.y;\n    float _7440 = 0.3257350027561187744140625 * n.z;\n    float _7444 = 0.3257350027561187744140625 * n.x;\n    float _7451 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7458 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7467 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7474 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7487 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7494 = 8 + int(_7340.w);\n    float _7521;\n    float _7534;\n    float _7548;\n    for (int k = 0; k < _7494; k++)\n    {\n        float _7507 = float(k & 1);\n        float _7511 = float((k >> 1) & 1);\n        float _7515 = float((k >> 2) & 1);\n        if (_7507 > 0.5)\n        {\n            _7521 = _7415.x;\n        }\n        else\n        {\n            _7521 = 1.0 - _7415.x;\n        }\n        if (_7511 > 0.5)\n        {\n            _7534 = _7415.y;\n        }\n        else\n        {\n            _7534 = 1.0 - _7415.y;\n        }\n        if (_7515 > 0.5)\n        {\n            _7548 = _7415.z;\n        }\n        else\n        {\n            _7548 = 1.0 - _7415.z;\n        }\n        float _7558 = (_7521 * _7534) * _7548;\n        if (!(_7558 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7571 = min(_7411 + vec3(_7507, _7511, _7515), _7402);\n        int _7591 = int(((_7335.x + _7571.x) + (_7330.x * (_7571.y + (_7330.y * _7571.z)))) + 0.5);\n        vec2 _7606 = vec2(float(_7591 % _7431) * 10.0, 1024.0 + (float(_7591 / _7431) * 11.0));\n        vec2 param_4 = _7606 + vec2(9.5, 10.5);\n        vec4 _7614 = fa_gi_fetch(param_4);\n        bool _7617 = _7614.y < 0.5;\n        bool _7626;\n        if (!_7617)\n        {\n            _7626 = _7614.x > _7340.y;\n        }\n        else\n        {\n            _7626 = _7617;\n        }\n        if (_7626)\n        {\n            continue;\n        }\n        vec3 _7638 = _7426 - (_7365 + (_7571 * _7358));\n        float _7641 = length(_7638);\n        vec3 _7647 = _7638 / vec3(max(_7641, 9.9999997473787516355514526367188e-05));\n        float _7657 = max(9.9999997473787516355514526367188e-05, (dot(-_7647, n) + 1.0) * 0.5);\n        float w = _7558 * (_7657 * _7657);\n        vec3 param_5 = _7647;\n        vec2 param_6 = (_7606 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7676 = fa_gi_fetch(param_6);\n        float _7683 = _7641 / max(_7335.z, 9.9999997473787516355514526367188e-05);\n        float _7686 = _7676.x;\n        if (_7683 > _7686)\n        {\n            float _7699 = max(_7676.y - (_7686 * _7686), 0.0);\n            float _7704 = _7683 - _7686;\n            float _7713 = _7699 / max(_7699 + (_7704 * _7704), 9.9999999600419720025001879548654e-13);\n            w *= ((_7713 * _7713) * _7713);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7606 + vec2(0.5, 10.5);\n        vec2 param_8 = _7606 + vec2(1.5, 10.5);\n        vec2 param_9 = _7606 + vec2(2.5, 10.5);\n        vec2 param_10 = _7606 + vec2(3.5, 10.5);\n        vec2 param_11 = _7606 + vec2(4.5, 10.5);\n        vec2 param_12 = _7606 + vec2(5.5, 10.5);\n        vec2 param_13 = _7606 + vec2(6.5, 10.5);\n        vec2 param_14 = _7606 + vec2(7.5, 10.5);\n        vec2 param_15 = _7606 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7436)) + (fa_gi_fetch(param_9).xyz * _7440)) + (fa_gi_fetch(param_10).xyz * _7444)) + (fa_gi_fetch(param_11).xyz * _7451)) + (fa_gi_fetch(param_12).xyz * _7458)) + (fa_gi_fetch(param_13).xyz * _7467)) + (fa_gi_fetch(param_14).xyz * _7474)) + (fa_gi_fetch(param_15).xyz * _7487)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7387 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7838;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7838 = _7340.x;\n    }\n    else\n    {\n        _7838 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7335.w * _7838);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7862 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7867 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7872 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7872) && (k < 8); k++)\n    {\n        int param = _7867 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7862;\n        vec3 _7897 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7902 = param_3 * left;\n        acc += (_7897 * _7902);\n        left -= _7902;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7931 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7931;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5806;\n    if (fa_lm.z > 0.5)\n    {\n        _5806 = 0.0;\n    }\n    else\n    {\n        _5806 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5817 = _5806 < 1.0;\n    bool _5823;\n    if (_5817)\n    {\n        int param = li;\n        _5823 = fa_light_baked(param);\n    }\n    else\n    {\n        _5823 = _5817;\n    }\n    return _5823 ? _5806 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _843 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _856 = (c - (ru * hx)) - p;\n        vec3 _862 = ru * (2.0 * hx);\n        float _868 = max(dot(_862, _862), 9.9999999392252902907785028219223e-09);\n        float _872 = dot(_856, _862);\n        float t = clamp((-_872) / _868, 0.0, 1.0);\n        if (_843)\n        {\n            float _887 = dot(r, _862);\n            float _893 = _868 - (_887 * _887);\n            if (abs(_893) > (9.9999997473787516355514526367188e-06 * _868))\n            {\n                t = clamp(((dot(r, _856) * _887) - _872) / _893, 0.0, 1.0);\n            }\n        }\n        return (p + _856) + (_862 * t);\n    }\n    vec3 q = p;\n    float _925 = dot(r, axis);\n    bool _933;\n    if (_843)\n    {\n        _933 = abs(_925) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _933 = _843;\n    }\n    if (_933)\n    {\n        float _943 = dot(c - p, axis) / _925;\n        if (_943 > 0.0)\n        {\n            q = p + (r * _943);\n        }\n    }\n    vec3 _956 = q - c;\n    vec2 xy = vec2(dot(_956, ru), dot(_956, uu));\n    if (shape > 0.5)\n    {\n        float _971 = length(xy);\n        if (_971 > hx)\n        {\n            xy *= (hx / _971);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _604 = abs(d);\n    float _606 = _604.x;\n    float _608 = _604.y;\n    bool _609 = _606 >= _608;\n    bool _617;\n    if (_609)\n    {\n        _617 = _606 >= _604.z;\n    }\n    else\n    {\n        _617 = _609;\n    }\n    int _618;\n    if (_617)\n    {\n        _618 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _633;\n        if (_608 >= _604.z)\n        {\n            _633 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _633 = (d.z > 0.0) ? 4 : 5;\n        }\n        _618 = _633;\n    }\n    return _618;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _763 = dot(d, right);\n    float _767 = dot(d, up);\n    float _778;\n    if (((_763 * _763) + (_767 * _767)) > 1.0000000133514319600180897396058e-10)\n    {\n        _778 = atan(_767, _763) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _778 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_778 - floor(_778)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1009 = fa_light_base(param);\n    bool _1013 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1009;\n    vec4 _1017 = fa_light_texel(param_1);\n    int param_2 = _1009 + 1;\n    vec4 _1022 = fa_light_texel(param_2);\n    float _1025 = _1022.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1037 = _1013 && (_1025 > 2.5);\n    fa_light_is_area = _1037;\n    bool _1039 = _1025 < 0.5;\n    vec3 l;\n    if (_1039)\n    {\n        l = normalize(_1017.xyz);\n        if (_1013)\n        {\n            int param_3 = _1009 + 6;\n            vec4 _1053 = fa_light_texel(param_3);\n            if (_1053.z > 0.5)\n            {\n                int param_4 = _1009 + 4;\n                vec4 _1063 = fa_light_texel(param_4);\n                int param_5 = _1009 + 5;\n                vec4 _1068 = fa_light_texel(param_5);\n                vec2 param_6 = _1053.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1063.xyz) * _1063.w, (-dot(world_pos, _1068.xyz)) * _1068.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1098 = _1017.xyz;\n        vec3 _1100 = _1098 - world_pos;\n        vec3 to_light = _1100;\n        float _1103 = length(_1100);\n        float reach = _1103;\n        bool front = true;\n        if (_1037)\n        {\n            int param_8 = _1009 + 7;\n            reach = max(_1103 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1009 + 4;\n            vec4 _1127 = fa_light_texel(param_9);\n            int param_10 = _1009 + 5;\n            vec4 _1132 = fa_light_texel(param_10);\n            int param_11 = _1009 + 6;\n            vec4 _1137 = fa_light_texel(param_11);\n            float _1138 = _1137.w;\n            int param_12 = _1009 + 2;\n            vec3 _1145 = normalize(fa_light_texel(param_12).xyz);\n            bool _1147 = _1138 > 1.5;\n            bool _1155;\n            if (!_1147)\n            {\n                _1155 = dot(_1145, to_light) < 0.0;\n            }\n            else\n            {\n                _1155 = _1147;\n            }\n            front = _1155;\n            vec3 r = vec3(0.0);\n            vec3 _1164 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1168 = dot(n, n) > 0.5;\n            bool _1176;\n            if (_1168)\n            {\n                _1176 = dot(_1164, _1164) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1176 = _1168;\n            }\n            if (_1176)\n            {\n                r = reflect(-normalize(_1164), normalize(n));\n            }\n            vec3 param_13 = _1098;\n            vec3 param_14 = _1145;\n            vec3 param_15 = _1127.xyz;\n            vec3 param_16 = _1132.xyz;\n            float param_17 = _1127.w;\n            float param_18 = _1132.w;\n            float param_19 = _1138;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1212 = length(to_light);\n        dist = _1212;\n        l = to_light / vec3(max(_1212, 9.9999997473787516355514526367188e-05));\n        float _1226 = reach / max(_1017.w, 0.001000000047497451305389404296875);\n        float _1232 = clamp(1.0 - (_1226 * _1226), 0.0, 1.0);\n        float _1234;\n        if (front)\n        {\n            _1234 = _1232 * _1232;\n        }\n        else\n        {\n            _1234 = 0.0;\n        }\n        atten = _1234;\n        bool _1245 = _1025 < 2.5;\n        if ((_1025 > 1.5) && _1245)\n        {\n            int param_22 = _1009 + 2;\n            vec4 _1253 = fa_light_texel(param_22);\n            float _1263 = _1253.w;\n            int param_23 = _1009 + 3;\n            vec4 _1268 = fa_light_texel(param_23);\n            float _1269 = _1268.x;\n            float cos_inner = _1269;\n            if (_1269 > 1.5)\n            {\n                cos_inner = mix(_1263, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1263, cos_inner, dot(-l, normalize(_1253.xyz)));\n        }\n        if (_1013 && (_1025 < 1.5))\n        {\n            int param_24 = _1009 + 6;\n            vec4 _1293 = fa_light_texel(param_24);\n            if (_1293.z > 0.5)\n            {\n                vec3 _1301 = -to_light;\n                int param_25 = _1009 + 4;\n                int param_26 = _1009 + 5;\n                vec3 _1315 = fa_light_texel(param_25).xyz;\n                vec3 _1319 = fa_light_texel(param_26).xyz;\n                vec3 _1328 = vec3(dot(_1301, _1315), dot(_1301, _1319), dot(_1301, cross(_1315, _1319)));\n                vec3 param_27 = _1328;\n                int _1332 = fa_cube_face(param_27);\n                int param_28 = _1332;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1359 = vec2(dot(_1328, cross(param_29, param_30)), dot(_1328, param_30)) / vec2(max(dot(_1328, param_29), 9.9999997473787516355514526367188e-05));\n                int _1363 = _1332 / 3;\n                vec2 param_31 = _1293.xy + (vec2(float(_1332 - (_1363 * 3)), float(_1363)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1359.x), 0.5 - (0.5 * _1359.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1009 + 7;\n            vec4 _1393 = fa_light_texel(param_33);\n            if (_1393.z > 0.5)\n            {\n                int param_34 = _1009 + 2;\n                int param_35 = _1009 + 4;\n                int param_36 = _1009 + 5;\n                vec2 param_37 = _1393.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1013 && _1245)\n            {\n                int param_42 = _1009 + 6;\n                vec4 _1440 = fa_light_texel(param_42);\n                int param_43 = _1009 + 7;\n                vec4 _1445 = fa_light_texel(param_43);\n                bool _1448 = _1440.z > 0.5;\n                bool _1455;\n                if (!_1448)\n                {\n                    _1455 = _1445.z > 0.5;\n                }\n                else\n                {\n                    _1455 = _1448;\n                }\n                if (_1455)\n                {\n                    int param_44 = _1009 + 2;\n                    vec4 _1462 = fa_light_texel(param_44);\n                    vec3 _1466 = normalize(_1462.xyz);\n                    int param_45 = _1009 + 4;\n                    vec4 _1471 = fa_light_texel(param_45);\n                    int param_46 = _1009 + 5;\n                    vec4 _1476 = fa_light_texel(param_46);\n                    if (_1448)\n                    {\n                        vec3 _1484 = -to_light;\n                        float _1491 = _1462.w;\n                        float _1507 = 0.5 / max(dot(_1484, _1466) * (sqrt(max(1.0 - (_1491 * _1491), 0.0)) / max(_1491, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1440.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1484, _1471.xyz) * _1507), 0.5 - (dot(_1484, _1476.xyz) * _1507));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1445.z > 0.5)\n                    {\n                        vec2 param_49 = _1445.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1466;\n                        vec3 param_52 = _1471.xyz;\n                        vec3 param_53 = _1476.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9013 = _1022.xyz * atten;\n    if (_1013)\n    {\n        _9013 *= fa_light_tint;\n    }\n    int _1576;\n    if (_1039)\n    {\n        _1576 = 0;\n    }\n    else\n    {\n        _1576 = ((_1025 > 1.5) && (_1025 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9013, atten, 1.0, dist, _1576);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2308;\n    if (i == 0)\n    {\n        _2308 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2324;\n        if (i == 1)\n        {\n            _2324 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2332;\n            if (i == 2)\n            {\n                _2332 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2332 = fa_shadows[24].w;\n            }\n            _2324 = _2332;\n        }\n        _2308 = _2324;\n    }\n    return _2308;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2365 = fa_shadow_depth(param, param_1);\n    float _2369;\n    if (conv.x < 0.5)\n    {\n        _2369 = _2365;\n    }\n    else\n    {\n        _2369 = (conv.y * conv.z) / (conv.z - (_2365 * (conv.z - conv.y)));\n    }\n    return _2369;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2415 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2421 = vec2(cos(_2415), sin(_2415));\n    vec2 dir = _2421;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2430;\n        if (k < 0.0)\n        {\n            _2430 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2430 = k;\n        }\n        float _2449 = clamp((_2430 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2468 = sqrt((float(i) + 0.5) * 0.0625) * _2449;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2468));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2482 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2482 < (zr - (_2468 * plane)))\n            {\n                sum += _2482;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2510 = sum / cnt;\n        float _2520;\n        if (k < 0.0)\n        {\n            _2520 = (-k) / max(_2510, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2520 = k;\n        }\n        radius = clamp(((max(zr - _2510, 0.0) * unit) * _2520) / texel_m, 1.5, 16.0);\n        dir = _2421;\n    }\n    float lit = 0.0;\n    int _2546 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2546; i_1++)\n    {\n        float _2565 = sqrt((float(i_1) + 0.5) / float(_2546)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2565));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2565 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2546);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2611 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2616 = clamp(dot(n, l), 0.0, 1.0);\n    float _2622 = sqrt(1.0 - (_2616 * _2616));\n    float _2630 = min(_2622 / max(_2616, 0.20000000298023223876953125), 4.0);\n    float _2635;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2635 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2635 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2660 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2635 * _2622)), 1.0);\n    float _2667 = _2660.x;\n    bool _2670 = _2667 < fa_shadows[ci * 1 + 16].x;\n    bool _2679;\n    if (!_2670)\n    {\n        _2679 = _2667 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2679 = _2670;\n    }\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2660.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2660.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2704;\n    if (!_2697)\n    {\n        _2704 = _2660.z > 1.0;\n    }\n    else\n    {\n        _2704 = _2697;\n    }\n    if (_2704)\n    {\n        return -1.0;\n    }\n    float _2712;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2712 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2712 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2660.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2660.z - ((_2712 * (1.0 + (0.5 * _2630))) / _2611);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2611;\n    float param_5 = _2611 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2630, 3.0)) * 0.5) / _2611;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3090 = int(fa_shadows[25].x + 0.5);\n    if (_3090 < 1)\n    {\n        return 1.0;\n    }\n    float _3105 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3090 - 1;\n    if (_3105 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3117 = _3090 > 1;\n    bool _3124;\n    if (_3117)\n    {\n        _3124 = _3105 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3124 = _3117;\n    }\n    if (_3124)\n    {\n        ci = 1;\n    }\n    bool _3128 = _3090 > 2;\n    bool _3135;\n    if (_3128)\n    {\n        _3135 = _3105 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3135 = _3128;\n    }\n    if (_3135)\n    {\n        ci = 2;\n    }\n    bool _3139 = _3090 > 3;\n    bool _3146;\n    if (_3139)\n    {\n        _3146 = _3105 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3146 = _3139;\n    }\n    if (_3146)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3157 = min(_3090, 4);\n    float _3198;\n    for (int c = ci; c < _3157; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3177 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3177;\n            break;\n        }\n        if (_3177 < 0.0)\n        {\n            continue;\n        }\n        s = _3177;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3198 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3198 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3217 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3198, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3105 - (fa_shadow_split_at(param_7) - _3217)) / _3217, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3249;\n        if ((ci + 1) < _3090)\n        {\n            _3249 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3249 = 1.0;\n        }\n        s = mix(s, _3249, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2770 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2777;\n    if (!_2770)\n    {\n        _2777 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2777 = _2770;\n    }\n    if (_2777)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2790 = fa_light_texel(param);\n    float _2791 = _2790.x;\n    if (_2791 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2800 = int(_2791 + 0.5);\n    int param_1 = _2800;\n    vec4 _2804 = fa_light_texel(param_1);\n    int param_2 = _2800 + 1;\n    vec4 _2809 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2812 = _2804.y;\n    if (_2812 > 0.0)\n    {\n        float _2829 = 1.0 - smoothstep(0.75 * _2812, _2812, length(world - fa_shadows[27].xyz));\n        fade = _2829;\n        if (_2829 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2804.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2853 = (_2800 + 2) + (face * 6);\n    int param_4 = _2853;\n    int param_5 = _2853 + 1;\n    int param_6 = _2853 + 3;\n    vec4 _2867 = fa_light_texel(param_6);\n    int param_7 = _2853 + 4;\n    vec4 _2872 = fa_light_texel(param_7);\n    int param_8 = _2853 + 5;\n    vec4 _2877 = fa_light_texel(param_8);\n    float _2889 = _2877.x * max(dot(_2867, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2894 = clamp(dot(n, l), 0.0, 1.0);\n    float _2917 = clamp(dot(n, _2867.xyz), -1.0, 1.0);\n    float _2936 = min(sqrt(1.0 - (_2917 * _2917)) / max(abs(dot(n, world - lpos)) / max(dot(_2867, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2939 = _2809.y;\n    float _2941;\n    if (_2939 > 0.0)\n    {\n        _2941 = _2939;\n    }\n    else\n    {\n        _2941 = 1.5 * _2889;\n    }\n    vec4 _2961 = vec4(world + (n * (_2941 * sqrt(1.0 - (_2894 * _2894)))), 1.0);\n    float _2965 = dot(_2867, _2961);\n    float _2968 = _2877.y;\n    if (_2965 < _2968)\n    {\n        return 1.0;\n    }\n    vec2 _2983 = vec2(dot(fa_light_texel(param_4), _2961), dot(fa_light_texel(param_5), _2961)) / vec2(_2965);\n    float _2985 = _2983.x;\n    bool _2988 = _2985 < _2872.x;\n    bool _2997;\n    if (!_2988)\n    {\n        _2997 = _2985 > _2872.z;\n    }\n    else\n    {\n        _2997 = _2988;\n    }\n    bool _3006;\n    if (!_2997)\n    {\n        _3006 = _2983.y < _2872.y;\n    }\n    else\n    {\n        _3006 = _2997;\n    }\n    bool _3015;\n    if (!_3006)\n    {\n        _3015 = _2983.y > _2872.w;\n    }\n    else\n    {\n        _3015 = _3006;\n    }\n    if (_3015)\n    {\n        return 1.0;\n    }\n    float _3021 = _2809.x;\n    float _3023;\n    if (_3021 > 0.0)\n    {\n        _3023 = _3021;\n    }\n    else\n    {\n        _3023 = 1.5 * _2889;\n    }\n    vec2 param_9 = _2983;\n    vec4 param_10 = _2872;\n    float param_11 = _2965 - (_3023 * (1.0 + (0.5 * _2936)));\n    float param_12 = _2889;\n    float param_13 = 1.0;\n    float param_14 = _2877.z * 0.25;\n    float param_15 = (_2889 * min(_2936, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2968, _2877.z);\n    int param_17 = int(_2804.z + 0.5);\n    float param_18 = _2804.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5179 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5186;\n    if (!_5179)\n    {\n        _5186 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5186 = _5179;\n    }\n    if (_5186)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5199 = fa_light_texel(param);\n    float _5200 = _5199.y;\n    float len = _5200;\n    if (_5200 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5212 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5222 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5212);\n    if (_5222 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5228 = len;\n    float _5231 = min(_5228, 0.89999997615814208984375 * dist);\n    len = _5231;\n    float _5236 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5212);\n    float _5241 = _5236 + (0.5 * _5231);\n    vec3 _5247 = world + (gn * _5236);\n    float _5249 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5313;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5264 = (float(k) + _5249) * 0.083333335816860198974609375;\n        vec3 _5272 = _5247 + (l * (_5264 * len));\n        vec4 _5278 = vec4(_5272, 1.0);\n        float _5284 = dot(fa_mesh_fs_params[28], _5278);\n        if (_5284 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5304 = vec2(dot(fa_mesh_fs_params[26], _5278), dot(fa_mesh_fs_params[27], _5278)) / vec2(_5284);\n        float _5308 = _5304.x * 0.5;\n        float _5309 = _5308 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5313 = (_5304.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5313 = 0.5 - (_5304.y * 0.5);\n        }\n        bool _5329 = _5309 < 0.0;\n        bool _5336;\n        if (!_5329)\n        {\n            _5336 = _5309 >= 1.0;\n        }\n        else\n        {\n            _5336 = _5329;\n        }\n        bool _5343;\n        if (!_5336)\n        {\n            _5343 = _5313 < 0.0;\n        }\n        else\n        {\n            _5343 = _5336;\n        }\n        bool _5350;\n        if (!_5343)\n        {\n            _5350 = _5313 >= 1.0;\n        }\n        else\n        {\n            _5350 = _5343;\n        }\n        if (_5350)\n        {\n            break;\n        }\n        vec4 _5377 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5309, _5313) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5377.w < 0.5)\n        {\n            continue;\n        }\n        float _5396 = (dot(fa_mesh_fs_params[29].xyz, _5272) + fa_mesh_fs_params[29].w) - _5377.x;\n        if ((_5396 > _5236) && (_5396 < _5241))\n        {\n            occ = max(occ, (1.0 - (_5264 * _5264)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5309, 0.5 - _5308), min(_5313, 1.0 - _5313))));\n        }\n    }\n    return 1.0 - (occ * _5222);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5862 = fa_baked_keep(param);\n    if (_5862 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5888 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9082 = _5888.color;\n    float _9083 = _5888.attenuation;\n    float _9084 = _5888.shadow;\n    bool _5891 = _5888.type == 0;\n    if (_5891 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5888.direction;\n        float _5902 = fa_shadow_factor(param_5, param_6);\n        _9084 = _5902;\n        _9082 *= _5902;\n    }\n    else\n    {\n        bool _5913 = _5888.type != 0;\n        bool _5919;\n        if (_5913)\n        {\n            _5919 = _9083 > 0.0;\n        }\n        else\n        {\n            _5919 = _5913;\n        }\n        if (_5919)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5888.direction;\n            float _5938 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9084 = _5938;\n            _9082 *= _5938;\n        }\n    }\n    bool _5948 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5954;\n    if (_5948)\n    {\n        _5954 = _9083 > 0.0;\n    }\n    else\n    {\n        _5954 = _5948;\n    }\n    if (_5954)\n    {\n        float _5961;\n        if (_5891)\n        {\n            _5961 = 1000000000.0;\n        }\n        else\n        {\n            _5961 = _5888._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5888.direction;\n        float param_18 = _5961;\n        float _5979 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9084 *= _5979;\n        _9082 *= _5979;\n    }\n    float _5992 = _9083;\n    float _5993 = _5992 * _5862;\n    _9083 = _5993;\n    vec3 _5997 = _9082;\n    vec3 _5998 = _5997 * _5862;\n    _9082 = _5998;\n    return LightSample(_5888.direction, _5998, _5993, _9084, _5888._distance, _5888.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6032 = v - (n * dot(v, n));\n    vec3 t = _6032;\n    float _6036 = dot(_6032, _6032);\n    float l2 = _6036;\n    if (_6036 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6046;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6046 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6046 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6046;\n        l2 = dot(_6046, _6046);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6433;\n    if ((j == 0) || (j == 7))\n    {\n        _6433 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6443;\n        if ((j == 3) || (j == 4))\n        {\n            _6443 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6443 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6433 = _6443;\n    }\n    float _6464;\n    if ((j == 1) || (j == 2))\n    {\n        _6464 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6473;\n        if ((j == 5) || (j == 6))\n        {\n            _6473 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6473 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6464 = _6473;\n    }\n    return (pc + (ex * _6433)) + (ey * _6464);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6081 = dot(a, a);\n    float _6085 = dot(b, b);\n    if ((_6081 < 1.0000000195414813782625560981111e-24) || (_6085 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6099 = a * inversesqrt(_6081);\n    vec3 _6104 = b * inversesqrt(_6085);\n    float _6108 = dot(_6099, _6104);\n    float _6111 = abs(_6108);\n    float g = (((((((((((0.0416471660137176513671875 * _6111) - 0.1924748718738555908203125) * _6111) + 0.4179156124591827392578125) * _6111) - 0.616057217121124267578125) * _6111) + 0.777722418308258056640625) * _6111) - 0.999542415142059326171875) * _6111) + 1.570791721343994140625;\n    if (_6108 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6108 * _6108), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6099, _6104) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6168 = a.z > 0.0;\n    bool _6172 = b.z > 0.0;\n    if (_6168 && _6172)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6168 != _6172)\n        {\n            vec3 _6207 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6207.z = 0.0;\n            if (_6168)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6207;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6207;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6207;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6207;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6256 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6282 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6308 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6334 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6256;\n    vec3 param_1 = _6282;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6282;\n    vec3 param_7 = _6308;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6308;\n    vec3 param_13 = _6334;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6334;\n    vec3 param_19 = _6256;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6502 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6520;\n    for (int k = 0; k < (2 * _6502); k++)\n    {\n        bool _6517 = k >= _6502;\n        if (_6517)\n        {\n            _6520 = k - _6502;\n        }\n        else\n        {\n            _6520 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6502 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6566 = 2 * _6520;\n            int param_4 = _6566 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6566 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6566 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6603 = bvec4(_6517);\n        vec4 param_16 = vec4(_6603.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6603.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6603.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6603.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6614 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6517)\n        {\n            vec2 _9309 = sum;\n            _9309.y = _9309.y + _6614;\n            sum = _9309;\n        }\n        else\n        {\n            vec2 _9312 = sum;\n            _9312.x = _9312.x + _6614;\n            sum = _9312;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6638 = fa_light_base(param);\n    int param_1 = _6638;\n    int param_2 = _6638 + 1;\n    int param_3 = _6638 + 2;\n    int param_4 = _6638 + 4;\n    vec4 _6660 = fa_light_texel(param_4);\n    int param_5 = _6638 + 5;\n    vec4 _6665 = fa_light_texel(param_5);\n    int param_6 = _6638 + 6;\n    vec4 _6670 = fa_light_texel(param_6);\n    float _6671 = _6670.w;\n    vec3 _6676 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6678 = _6671 < 1.5;\n    bool _6685;\n    if (_6678)\n    {\n        _6685 = dot(normalize(fa_light_texel(param_3).xyz), _6676) >= 0.0;\n    }\n    else\n    {\n        _6685 = _6678;\n    }\n    if (_6685)\n    {\n        return vec3(0.0);\n    }\n    bool _6694 = (_6671 > 0.5) && _6678;\n    float _6698 = _6694 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6701 = _6660.xyz;\n    float _6703 = _6660.w;\n    vec3 _6709 = _6665.xyz;\n    float _6711 = _6665.w;\n    vec3 up = _6709 * (_6711 * _6698);\n    float _6717;\n    if (_6694)\n    {\n        _6717 = (3.1415927410125732421875 * _6703) * _6703;\n    }\n    else\n    {\n        _6717 = (4.0 * _6703) * _6711;\n    }\n    if (_6671 > 1.5)\n    {\n        vec3 _6743 = cross(_6701, -_6676);\n        vec3 perp = _6743;\n        float _6747 = dot(_6743, _6743);\n        vec3 _6750;\n        if (_6747 > 1.0000000133514319600180897396058e-10)\n        {\n            _6750 = perp * inversesqrt(_6747);\n        }\n        else\n        {\n            _6750 = _6709;\n        }\n        perp = _6750;\n        up = _6750 * _6711;\n    }\n    float _6771 = max(_6717, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6781 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6781;\n    vec3 param_10 = n;\n    vec3 param_11 = _6676;\n    vec3 param_12 = _6781;\n    vec3 param_13 = n;\n    vec3 param_14 = _6701 * (_6703 * _6698);\n    vec3 param_15 = _6781;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6812 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6812;\n    vec2 param_21 = _6812 + vec2(64.0, 0.0);\n    vec4 _6822 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6671;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6834 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6834.x) + (((f0 * _6822.x) + ((vec3(f90) - f0) * _6822.y)) * _6834.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6676, _6676)) + _6771) / _6771) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4916 = 1.0 / alpha;\n    return ((2.0 + _4916) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4916)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4951 = max(dot(L.nc, l), 0.0);\n    float _4957 = max(dot(L.nc, h), 0.0);\n    float _4966 = ((_4957 * _4957) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4966) * _4966)) * (0.5 / max(mix((2.0 * _4951) * L.coat_ndv, _4951 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4951)) * _4951;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _6871;\n    if (L.sheen_on)\n    {\n        _6871 = L.sheen_scale;\n    }\n    else\n    {\n        _6871 = 1.0;\n    }\n    vec3 result = base * (L.keep * _6871);\n    vec3 _6884 = normalize(l + v);\n    int param = li;\n    vec3 _6895 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _6904 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _6884), 0.0);\n        float param_3 = _6904;\n        float param_4 = ndv;\n        result += ((L.sheen * _6895) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6904)) * _6904) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _6884;\n        float param_8 = max(dot(v, _6884), 0.0);\n        result += (_6895 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4819 = tdh / at;\n    float _4823 = bdh / ab;\n    float _4835 = ((_4819 * _4819) + (_4823 * _4823)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4835) * _4835);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5015 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5094 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5094) * _5094);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5015);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5015));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4218 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4221 = _4218.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4221 * _4221, exp2((-9.27999973297119140625) * ndv)) * _4221) + _4218.y)) + _4218.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3526;\n    if (lv == 0)\n    {\n        _3526 = 0.0;\n    }\n    else\n    {\n        _3526 = res + 2.0;\n    }\n    float _3536;\n    if (lv == 0)\n    {\n        _3536 = 0.0;\n    }\n    else\n    {\n        _3536 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3526, _3536)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3582;\n    if (res > 64.5)\n    {\n        _3582 = 5.0;\n    }\n    else\n    {\n        _3582 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3597 = clamp(rough, 0.0, 1.0) * (_3582 - 1.0);\n    int _3604 = int(min(floor(_3597), _3582 - 2.0));\n    float _3609 = _3597 - float(_3604);\n    vec3 param = d;\n    vec2 _3613 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3604;\n    vec2 param_4 = _3613;\n    vec3 _3623 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3609 < 0.00200000009499490261077880859375)\n    {\n        return _3623;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3604 + 1;\n    vec2 param_8 = _3613;\n    return mix(_3623, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3609));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3696 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3703 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3710 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3716 = dot(bx.xyz, d);\n    float _3720 = dot(by.xyz, d);\n    float _3724 = dot(bz.xyz, d);\n    float _3730;\n    if (_3716 > 9.9999999747524270787835121154785e-07)\n    {\n        _3730 = (1.0 - _3696) / _3716;\n    }\n    else\n    {\n        float _3744;\n        if (_3716 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3744 = ((-1.0) - _3696) / _3716;\n        }\n        else\n        {\n            _3744 = 1000000015047466219876688855040.0;\n        }\n        _3730 = _3744;\n    }\n    float tx = _3730;\n    float _3761;\n    if (_3720 > 9.9999999747524270787835121154785e-07)\n    {\n        _3761 = (1.0 - _3703) / _3720;\n    }\n    else\n    {\n        float _3774;\n        if (_3720 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3774 = ((-1.0) - _3703) / _3720;\n        }\n        else\n        {\n            _3774 = 1000000015047466219876688855040.0;\n        }\n        _3761 = _3774;\n    }\n    float ty = _3761;\n    float _3790;\n    if (_3724 > 9.9999999747524270787835121154785e-07)\n    {\n        _3790 = (1.0 - _3710) / _3724;\n    }\n    else\n    {\n        float _3803;\n        if (_3724 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3803 = ((-1.0) - _3710) / _3724;\n        }\n        else\n        {\n            _3803 = 1000000015047466219876688855040.0;\n        }\n        _3790 = _3803;\n    }\n    float _3815 = tx;\n    float _3818 = (_3815 > 0.0) ? _3815 : 1000000015047466219876688855040.0;\n    tx = _3818;\n    float _3819 = ty;\n    float _3822 = (_3819 > 0.0) ? _3819 : 1000000015047466219876688855040.0;\n    ty = _3822;\n    float _3832 = min(_3818, min(_3822, (_3790 > 0.0) ? _3790 : 1000000015047466219876688855040.0));\n    if (_3832 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3848 = (fa_world_pos + (d * _3832)) - posw.xyz;\n    vec3 _3853;\n    if (dot(_3848, _3848) > 1.0000000133514319600180897396058e-10)\n    {\n        _3853 = normalize(_3848);\n    }\n    else\n    {\n        _3853 = d;\n    }\n    return _3853;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3899 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3899 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3927 = rough * rough;\n            float _3958 = 0.60000002384185791015625 * _3927;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3927)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3958, 0.0500000007450580596923828125 + _3958, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3927 * 0.60000002384185791015625));\n        }\n        outc = base * _3899;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4017 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4017 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4049 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4049 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4696;\n        if (L.aniso >= 0.0)\n        {\n            _4696 = L.b;\n        }\n        else\n        {\n            _4696 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4696, v), _4696), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4732 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4732.x) + (vec3(L.f90) * _4732.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4790 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4790.x) + _4790.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4260 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4260.x) + vec3(_4260.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5500 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5504 = fa_xm_origin(param_1);\n    vec2 _5510 = (uv * _5500) - vec2(0.5);\n    vec2 _5513 = fract(_5510);\n    vec2 _5516 = floor(_5510);\n    vec2 param_2 = _5500;\n    vec2 param_3 = _5504;\n    vec2 param_4 = _5516;\n    vec2 param_5 = _5500;\n    vec2 param_6 = _5504;\n    vec2 param_7 = _5516 + vec2(1.0, 0.0);\n    vec2 param_8 = _5500;\n    vec2 param_9 = _5504;\n    vec2 param_10 = _5516 + vec2(0.0, 1.0);\n    vec2 param_11 = _5500;\n    vec2 param_12 = _5504;\n    vec2 param_13 = _5516 + vec2(1.0);\n    vec3 _5558 = vec3(_5513.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5558), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5558), vec3(_5513.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5577 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5581 = clamp(lod, 0.0, _5577);\n    int _5585 = int(floor(_5581));\n    int param = _5585;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5595 = float(_5585);\n    float _5596 = _5581 - _5595;\n    bool _5598 = _5596 > 0.001000000047497451305389404296875;\n    bool _5605;\n    if (_5598)\n    {\n        _5605 = _5595 < _5577;\n    }\n    else\n    {\n        _5605 = _5598;\n    }\n    if (_5605)\n    {\n        int param_2 = _5585 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5596));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5631 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5631.x) + (vec3(f90) * _5631.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5659 = max(s.thickness, 0.0);\n    bool _5664 = _5659 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5664)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5659);\n    }\n    bool _5689 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5696;\n    if (!_5689)\n    {\n        _5696 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5696 = _5689;\n    }\n    if (_5696)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5664)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5659);\n    }\n    vec4 _5731 = vec4(world, 1.0);\n    float _5736 = dot(fa_mesh_fs_params[28], _5731);\n    vec2 uv = vec2(0.5);\n    if (_5736 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5754 = vec2(dot(fa_mesh_fs_params[26], _5731), dot(fa_mesh_fs_params[27], _5731)) / vec2(_5736);\n        float _5762;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5762 = (_5754.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5762 = 0.5 - (_5754.y * 0.5);\n        }\n        uv = vec2((_5754.x * 0.5) + 0.5, _5762);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3277 = int(fa_shadows[25].x + 0.5);\n    float _3287 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3292 = _3277 > 0;\n    bool _3301;\n    if (_3292)\n    {\n        int param = _3277 - 1;\n        _3301 = _3287 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3301 = _3292;\n    }\n    if (_3301)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3307 = _3277 > 1;\n        bool _3314;\n        if (_3307)\n        {\n            _3314 = _3287 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3314 = _3307;\n        }\n        if (_3314)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3320 = _3277 > 2;\n        bool _3327;\n        if (_3320)\n        {\n            _3327 = _3287 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3327 = _3320;\n        }\n        if (_3327)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3333 = _3277 > 3;\n        bool _3340;\n        if (_3333)\n        {\n            _3340 = _3287 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3340 = _3333;\n        }\n        if (_3340)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8741 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8741 = -_8741;\n    }\n    vec3 _8039 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8741, fa_world_tangent, fa_uv, fa_vertex_color, _8039, gl_FrontFacing);\n    Surface _8047 = fa_standard_surface(param_1);\n    vec3 _8772 = _8047.albedo;\n    float _8773 = _8047.alpha;\n    vec3 _8774 = _8047.normal;\n    float _8775 = _8047.metallic;\n    float _8776 = _8047.roughness;\n    float _8777 = _8047.occlusion;\n    vec3 _8778 = _8047.emission;\n    float _8779 = _8047.clearcoat;\n    float _8780 = _8047.clearcoat_roughness;\n    vec3 _8781 = _8047.sheen_color;\n    float _8782 = _8047.sheen_roughness;\n    float _8783 = _8047.anisotropy;\n    float _8784 = _8047.anisotropy_rotation;\n    float _8785 = _8047.specular;\n    float _8786 = _8047.ior;\n    vec3 _8787 = _8047.specular_color;\n    float _8788 = _8047.transmission;\n    float _8789 = _8047.thickness;\n    vec3 _8790 = _8047.attenuation_color;\n    float _8791 = _8047.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8741, fa_world_tangent, fa_uv, fa_vertex_color, _8039, gl_FrontFacing);\n    Surface param_3 = _8047;\n    surface(param_2, param_3);\n    _8772 = param_3.albedo;\n    _8773 = param_3.alpha;\n    _8774 = param_3.normal;\n    _8775 = param_3.metallic;\n    _8776 = param_3.roughness;\n    _8777 = param_3.occlusion;\n    _8778 = param_3.emission;\n    _8779 = param_3.clearcoat;\n    _8780 = param_3.clearcoat_roughness;\n    _8781 = param_3.sheen_color;\n    _8782 = param_3.sheen_roughness;\n    _8783 = param_3.anisotropy;\n    _8784 = param_3.anisotropy_rotation;\n    _8785 = param_3.specular;\n    _8786 = param_3.ior;\n    _8787 = param_3.specular_color;\n    _8788 = param_3.transmission;\n    _8789 = param_3.thickness;\n    _8790 = param_3.attenuation_color;\n    _8791 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8741;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8772 = param_6;\n    _8774 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8772;\n    }\n    else\n    {\n        vec3 _8087 = normalize(_8774);\n        float _8094 = clamp(_8775, 0.0, 1.0);\n        float _8098 = clamp(_8776, 0.0500000007450580596923828125, 1.0);\n        float _8102 = _8098 * _8098;\n        float _8106 = _8102 * _8102;\n        float _8111 = max(dot(_8087, _8039), 9.9999997473787516355514526367188e-05);\n        float _8117 = 1.0 - _8094;\n        float _8118 = clamp(_8788, 0.0, 1.0) * _8117;\n        vec3 _8127 = (_8772 * _8117) * (1.0 - _8118);\n        vec3 _8134 = mix(vec3(0.039999999105930328369140625), _8772, vec3(_8094));\n        vec3 f0 = _8134;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8741, fa_world_tangent, fa_uv, fa_vertex_color, _8039, gl_FrontFacing);\n        Surface param_9 = Surface(_8772, _8773, _8774, _8775, _8776, _8777, _8778, _8779, _8780, _8781, _8782, _8783, _8784, _8785, _8786, _8787, _8788, _8789, _8790, _8791);\n        vec3 param_10 = _8087;\n        vec3 param_11 = _8039;\n        float param_12 = _8094;\n        float param_13 = _8098;\n        vec3 param_14 = _8134;\n        FaLayers _8150 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8087;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8127) * _8777;\n        if (_8150.on)\n        {\n            lit *= _8150.base_scale;\n        }\n        int _8172 = fa_cl_ndir + fa_cl_local;\n        float _8237;\n        for (int ln = 0; ln < _8172; ln++)\n        {\n            int param_16 = ln;\n            int _8185 = fa_cl_light(param_16);\n            int param_17 = _8185;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8185;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8741;\n            LightSample _8201 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8209 = max(dot(_8087, _8201.direction), 0.0);\n            float _8215 = _8201.attenuation * _8201.shadow;\n            vec3 _8220 = normalize(_8201.direction + _8039);\n            float _8225 = max(dot(_8087, _8220), 0.0);\n            float _8230 = max(dot(_8039, _8220), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8150.on)\n                {\n                    _8237 = _8150.f90;\n                }\n                else\n                {\n                    _8237 = 1.0;\n                }\n                int param_21 = _8185;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8087;\n                vec3 param_24 = _8039;\n                vec3 param_25 = _8127;\n                vec3 param_26 = f0;\n                float param_27 = _8237;\n                float param_28 = _8098;\n                float param_29 = _8111;\n                float param_30 = _8215;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8150.on)\n                {\n                    FaLayers param_31 = _8150;\n                    vec3 param_32 = area;\n                    int param_33 = _8185;\n                    vec3 param_34 = _8087;\n                    vec3 param_35 = _8039;\n                    vec3 param_36 = _8201.direction;\n                    float param_37 = _8111;\n                    float param_38 = _8215;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8150.on)\n                {\n                    FaLayers param_39 = _8150;\n                    vec3 param_40 = _8127;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8087;\n                    vec3 param_43 = _8039;\n                    vec3 param_44 = _8201.direction;\n                    vec3 param_45 = _8220;\n                    float param_46 = _8209;\n                    float param_47 = _8111;\n                    float param_48 = _8225;\n                    float param_49 = _8230;\n                    float param_50 = _8102;\n                    float param_51 = _8106;\n                    int param_52 = _8185;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8215));\n                }\n                else\n                {\n                    float _8339 = ((_8225 * _8225) * (_8106 - 1.0)) + 1.0;\n                    int param_53 = _8185;\n                    lit += (((_8127 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8230, 5.0))) * (((_8106 / ((3.1415927410125732421875 * _8339) * _8339)) * (0.5 / max(mix((2.0 * _8209) * _8111, _8209 + _8111, _8102), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8209))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8209 * _8215));\n                }\n            }\n        }\n        if (_8150.on)\n        {\n            FaLayers param_54 = _8150;\n            vec3 param_55 = _8087;\n            vec3 param_56 = _8039;\n            vec3 param_57 = f0;\n            float param_58 = _8098;\n            float param_59 = _8777;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8087;\n            vec3 param_61 = _8039;\n            vec3 param_62 = f0;\n            float param_63 = _8098;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8777);\n        }\n        if (_8118 > 0.0)\n        {\n            float _8437;\n            if (_8150.on)\n            {\n                _8437 = _8150.f90;\n            }\n            else\n            {\n                _8437 = 1.0;\n            }\n            float _8445;\n            if (_8150.on)\n            {\n                _8445 = _8150.base_scale;\n            }\n            else\n            {\n                _8445 = 1.0;\n            }\n            Surface param_64 = Surface(_8772, _8773, _8774, _8775, _8776, _8777, _8778, _8779, _8780, _8781, _8782, _8783, _8784, _8785, _8786, _8787, _8788, _8789, _8790, _8791);\n            vec3 param_65 = _8087;\n            vec3 param_66 = _8039;\n            float param_67 = _8098;\n            vec3 param_68 = f0;\n            float param_69 = _8437;\n            float param_70 = _8445;\n            float param_71 = _8118;\n            float param_72 = fa_tr_blend;\n            vec3 _8469 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8469;\n        }\n        result = lit;\n    }\n    vec3 _8476 = result;\n    vec3 _8477 = _8476 + _8778;\n    result = _8477;\n    vec3 param_73 = _8477;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8486 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8493;\n    if (!_8486)\n    {\n        _8493 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8493 = _8486;\n    }\n    if (_8493)\n    {\n        vec3 _8502 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8508 = dot(_8502, fa_mesh_fs_params[9].xyz);\n        bool _8512 = fa_mesh_fs_params[9].w > 0.5;\n        float _8513;\n        if (_8512)\n        {\n            _8513 = _8508;\n        }\n        else\n        {\n            _8513 = length(_8502);\n        }\n        float _8525 = _8513 - fa_mesh_fs_params[8].x;\n        if (_8525 > 0.0)\n        {\n            float _8534 = fa_mesh_fs_params[7].w * _8525;\n            float tau = _8534 * _8534;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8550;\n                if (_8512)\n                {\n                    _8550 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8508);\n                }\n                else\n                {\n                    _8550 = fa_mesh_fs_params[0].y;\n                }\n                float _8571 = mix(_8550, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8513, 0.0, 1.0));\n                float _8575 = fa_world_pos.y - _8571;\n                float _8580 = _8571 - fa_mesh_fs_params[8].z;\n                float _8585 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8588 = _8580 <= 0.0;\n                bool _8589 = !_8588;\n                bool _8595;\n                if (_8589)\n                {\n                    _8595 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8595 = _8588;\n                }\n                float _8596;\n                if (_8595)\n                {\n                    _8596 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8596 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8580, 80.0));\n                }\n                bool _8623;\n                if (_8589)\n                {\n                    _8623 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8623 = _8588;\n                }\n                float _8624;\n                if (_8623)\n                {\n                    _8624 = fa_mesh_fs_params[8].y * _8580;\n                }\n                else\n                {\n                    _8624 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8580, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8649 = _8585 <= 0.0;\n                bool _8656;\n                if (!_8649)\n                {\n                    _8656 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8656 = _8649;\n                }\n                float _8657;\n                if (_8656)\n                {\n                    _8657 = fa_mesh_fs_params[8].y * _8585;\n                }\n                else\n                {\n                    _8657 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8585, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8684;\n                if (abs(_8575) < 0.001000000047497451305389404296875)\n                {\n                    _8684 = _8596;\n                }\n                else\n                {\n                    _8684 = (_8657 - _8624) / _8575;\n                }\n                tau += (_8525 * max(_8684, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8720 = 1.0 - fa_tr_blend;\n        result /= vec3(_8720);\n        _8773 *= _8720;\n    }\n    fa_frag_color = vec4(result, _8773);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_656",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2318",
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
            "inst_name": "_6973",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4361[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1594 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1601;\n    if (!_1594)\n    {\n        _1601 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1601 = _1594;\n    }\n    bool _1609;\n    if (!_1601)\n    {\n        _1609 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1609 = _1601;\n    }\n    bool _1616;\n    if (!_1609)\n    {\n        _1616 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1616 = _1609;\n    }\n    bool _1623;\n    if (!_1616)\n    {\n        _1623 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1623 = _1616;\n    }\n    if (_1623)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1633 = vec4(world_pos, 1.0);\n    float _1639 = dot(fa_mesh_fs_params[16], _1633);\n    if (!(_1639 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1661 = vec2(dot(fa_mesh_fs_params[14], _1633), dot(fa_mesh_fs_params[15], _1633)) / vec2(_1639);\n    int _1665 = int(fa_mesh_fs_params[18].x);\n    int _1669 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1669) + clamp(int(floor(((_1661.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1669 - 1)) * _1665)) + clamp(int(floor(((_1661.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1665 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1745 = fa_cluster_texel(param);\n    return ivec2(int(_1745.x), int(_1745.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5836 = fa_cluster_lookup(param);\n    fa_cl_slot = _5836.x;\n    fa_cl_local = _5836.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7025 = fa_linear_to_srgb(param);\n        c = _7025;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7033 = fa_srgb_to_linear(param_1);\n            c = _7033;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _538;\n    if (i.front_facing)\n    {\n        _538 = i.world_normal;\n    }\n    else\n    {\n        _538 = -i.world_normal;\n    }\n    vec3 _562 = normalize(i.world_tangent.xyz - (_538 * dot(_538, i.world_tangent.xyz)));\n    vec3 _589 = normalize(((_562 * m.x) + ((cross(_538, _562) * i.world_tangent.w) * m.y)) + (_538 * m.z));\n    vec3 _592;\n    if (i.front_facing)\n    {\n        _592 = _589;\n    }\n    else\n    {\n        _592 = -_589;\n    }\n    return _592;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7064 = fa_tex_fix(param_2, param_3);\n    vec4 _9326 = base_t;\n    _9326.x = _7064.x;\n    _9326.y = _7064.y;\n    _9326.z = _7064.z;\n    base_t = _9326;\n    vec4 _7078 = (_9326 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9102 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7110 = fa_tex_fix(param_6, param_7);\n        vec3 _7113 = (_7110 * 2.0) - vec3(1.0);\n        vec2 _7118 = _7113.xy * fa_mesh_fs_params[6].x;\n        vec3 _9334 = _7113;\n        _9334.x = _7118.x;\n        _9334.y = _7118.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9334;\n        _9102 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7146 = fa_tex_fix(param_12, param_13);\n    vec4 _9337 = mrt;\n    _9337.x = _7146.x;\n    _9337.y = _7146.y;\n    _9337.z = _7146.z;\n    mrt = _9337;\n    vec4 _7174 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7174.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7185 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7215 = fa_tex_fix(param_20, param_21);\n    float _9107 = fa_mesh_fs_params[20].x;\n    float _9108 = fa_mesh_fs_params[20].y;\n    float _9111 = fa_mesh_fs_params[20].z;\n    float _9110 = fa_mesh_fs_params[21].w;\n    float _9113 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9107 *= _7185.y;\n            _9108 *= _7185.z;\n            _9110 *= _7174.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9111 *= mrt.x;\n            _9113 *= mrt.w;\n        }\n    }\n    return Surface(_7078.xyz, _7078.w, _9102, clamp(fa_mesh_fs_params[5].x * _7146.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7146.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7185.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7215), _9107, _9108, fa_mesh_fs_params[21].xyz, _9110, _9111, fa_mesh_fs_params[20].w, _9113, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1825 = rect.zw - rect.xy;\n    vec2 _1829 = _1825 * atlas;\n    vec2 _1833 = ddx * _1829;\n    vec2 _1837 = ddy * _1829;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1825), clamp(0.5 * log2(max(max(dot(_1833, _1833), dot(_1837, _1837)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1870 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1877;\n    if (!_1870)\n    {\n        _1877 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1877 = _1870;\n    }\n    if (_1877)\n    {\n        return;\n    }\n    vec3 _1883 = dFdx(world_pos);\n    vec3 _1886 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1890 = fa_cluster_texel(param);\n    int _1894 = int(_1890.w);\n    if (_1894 < 1)\n    {\n        return;\n    }\n    int _1904 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1904;\n    vec4 _1908 = fa_light_texel(param_1);\n    vec2 _1911 = _1908.yz;\n    int _1915 = int(_1908.w);\n    int param_2 = _1904 + 1;\n    vec4 _1920 = fa_light_texel(param_2);\n    float _1921 = _1920.x;\n    int _1927 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1931 = int(_1890.z);\n    vec3 _2196;\n    for (int k = 0; k < _1894; k++)\n    {\n        int _1944 = _1931 + k;\n        int param_3 = _1915 + (_1944 >> 2);\n        int _1961 = (_1904 + 2) + (int(fa_light_texel(param_3)[_1944 & 3]) * 7);\n        int param_4 = _1961 + 6;\n        vec4 _1966 = fa_light_texel(param_4);\n        if (((int(_1966.w + 0.5) >> _1927) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1961;\n        vec4 _1981 = fa_light_texel(param_5);\n        int param_6 = _1961 + 1;\n        vec4 _1986 = fa_light_texel(param_6);\n        int param_7 = _1961 + 2;\n        vec4 _1991 = fa_light_texel(param_7);\n        vec3 _1994 = _1981.xyz;\n        float _1999 = dot(_1994, world_pos) + _1981.w;\n        vec3 _2001 = _1986.xyz;\n        float _2006 = dot(_2001, world_pos) + _1986.w;\n        vec3 _2008 = _1991.xyz;\n        float _2013 = dot(_2008, world_pos) + _1991.w;\n        bool _2018 = abs(_1999) > 0.5;\n        bool _2026;\n        if (!_2018)\n        {\n            _2026 = abs(_2006) > 0.5;\n        }\n        else\n        {\n            _2026 = _2018;\n        }\n        bool _2034;\n        if (!_2026)\n        {\n            _2034 = abs(_2013) > 0.5;\n        }\n        else\n        {\n            _2034 = _2026;\n        }\n        if (_2034)\n        {\n            continue;\n        }\n        float _2049 = clamp(dot(geo_normal, normalize(_2008)) * _1966.z, 0.0, 1.0);\n        if (_2049 <= 0.0)\n        {\n            continue;\n        }\n        float _2069 = (clamp((0.5 - abs(_2013)) * 10.0, 0.0, 1.0) * _2049) * _1966.x;\n        vec2 _2077 = vec2(_1999 + 0.5, 0.5 - _2006);\n        vec2 _2087 = vec2(dot(_1994, _1883), dot(_2001, _1883));\n        vec2 _2097 = vec2(dot(_1994, _1886), dot(_2001, _1886));\n        int param_8 = _1961 + 5;\n        vec4 _2102 = fa_light_texel(param_8);\n        int param_9 = _1961 + 3;\n        vec4 _2107 = fa_light_texel(param_9);\n        int param_10 = _1961 + 4;\n        vec4 _2112 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2102.xyz;\n        bool _2122 = _2107.z > _2107.x;\n        if (_2122)\n        {\n            vec4 param_11 = _2107;\n            vec2 param_12 = _2077;\n            vec2 param_13 = _1911;\n            vec2 param_14 = _2087;\n            vec2 param_15 = _2097;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1921 > 0.5) && (_1921 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2148 = fa_dc_to_linear(param_16);\n                vec4 _9190 = tx;\n                _9190.x = _2148.x;\n                _9190.y = _2148.y;\n                _9190.z = _2148.z;\n                tx = _9190;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2069 * tex_a) * _2102.w, 0.0, 1.0)));\n        if (_2112.z > _2112.x)\n        {\n            vec4 param_17 = _2112;\n            vec2 param_18 = _2077;\n            vec2 param_19 = _1911;\n            vec2 param_20 = _2087;\n            vec2 param_21 = _2097;\n            vec4 _2192 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1921 > 1.5)\n            {\n                vec3 param_22 = _2192.xyz;\n                vec3 _2202 = fa_dc_to_srgb(param_22);\n                _2196 = _2202;\n            }\n            else\n            {\n                _2196 = _2192.xyz;\n            }\n            vec3 _2211 = (_2196 * 2.0) - vec3(1.0);\n            vec2 _2216 = _2211.xy * _1966.y;\n            vec3 _2238 = (normalize(_1994) * _2216.x) + (normalize(_2001) * _2216.y);\n            vec3 _2241 = normalize(normal);\n            normal = normalize(mix(_2241, normalize((_2241 * max(_2211.z, 0.0500000007450580596923828125)) + (_2238 - (_2241 * dot(_2241, _2238)))), vec3(clamp(_2069 * (_2122 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4286 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4294 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4297 = int(_4286);\n    int _4300 = int(_4294);\n    float _4310 = _4294 - float(_4300);\n    int _4365 = (_4297 * 9) + _4300;\n    int _4385 = ((_4297 + 1) * 9) + _4300;\n    return mix(mix(_4361[_4365], _4361[_4365 + 1], _4310), mix(_4361[_4385], _4361[_4385 + 1], _4310), _4286 - float(_4297));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9025 = false;\n    float _9026 = 1.0;\n    float _9027 = 1.0;\n    float _9028 = 1.0;\n    float _9029 = 0.0;\n    float _9030 = 0.0;\n    float _9031 = 0.0;\n    float _9032 = 0.0;\n    float _9034 = 1.0;\n    bool _9035 = false;\n    vec3 _9036 = vec3(0.0);\n    float _9037 = 1.0;\n    float _9038 = 1.0;\n    float _9039 = 1.0;\n    float _9040 = 0.0;\n    float _9041 = 0.0;\n    vec3 _9042 = vec3(1.0, 0.0, 0.0);\n    vec3 _9043 = vec3(0.0, 0.0, 1.0);\n    float _9044 = 1.0;\n    float _9045 = 1.0;\n    float _4436 = clamp(s.specular, 0.0, 1.0);\n    float _4440 = clamp(s.ior, 1.0, 3.0);\n    bool _4445 = (_4436 != 1.0) || (_4440 != 1.5);\n    bool _4454;\n    if (!_4445)\n    {\n        _4454 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4454 = _4445;\n    }\n    if (_4454)\n    {\n        float _4462 = (_4440 - 1.0) / (_4440 + 1.0);\n        f0 = mix(min(vec3(_4462 * _4462) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4436, s.albedo, vec3(metallic));\n        _9026 = mix(_4436, 1.0, metallic);\n        _9025 = true;\n    }\n    float _4489 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4489 > 0.0)\n    {\n        float _4497 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9029 = _4489;\n        _9030 = _4497;\n        float _4504 = _4497 * _4497;\n        _9031 = _4504;\n        _9032 = _4504 * _4504;\n        float _4516 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9034 = _4516;\n        _9027 = 1.0 - (_4489 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4516, 0.0, 1.0), 5.0))));\n        _9025 = true;\n    }\n    vec3 _4535 = max(s.sheen_color, vec3(0.0));\n    float _4544 = max(_4535.x, max(_4535.y, _4535.z));\n    if (_4544 > 0.0)\n    {\n        float _4552 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9035 = true;\n        _9036 = _4535;\n        _9037 = _4552;\n        _9038 = _4552 * _4552;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4552;\n        float _4569 = fa_sheen_albedo(param, param_1);\n        _9040 = _4569;\n        _9039 = 1.0 - min(_4544 * _4569, 1.0);\n        _9025 = true;\n    }\n    _9028 = _9027 * _9039;\n    float _4588 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4588 != 0.0)\n    {\n        vec3 _4603 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4603;\n        if (dot(_4603, _4603) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4615 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4615.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4615.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4615.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4619 = t;\n        vec3 _4620 = normalize(_4619);\n        t = _4620;\n        vec3 _4645 = normalize((_4620 * cos(s.anisotropy_rotation)) + ((cross(n, _4620) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9042 = _4645;\n        _9043 = cross(n, _4645);\n        float _4655 = roughness * roughness;\n        float _4661 = mix(_4655, 1.0, _4588 * _4588);\n        bool _4663 = _4588 > 0.0;\n        _9044 = _4663 ? _4661 : _4655;\n        _9045 = _4663 ? _4655 : _4661;\n        _9041 = _4588;\n        _9025 = true;\n    }\n    return FaLayers(_9025, _9026, _9027, _9028, _9029, _9030, _9031, _9032, i.world_normal, _9034, _9035, _9036, _9037, _9038, _9039, _9040, _9041, _9042, _9043, _9044, _9045);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3454 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3454;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4067 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4072 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4067 > 0.0005000000237487256526947021484375)\n    {\n        if (_4072)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4067;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4067;\n        }\n    }\n    bool _4123 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4123)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4154 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4154)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4072 || _4123) || _4154)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3474 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3477 = _3474.x;\n    float _3479 = _3474.z;\n    vec2 e = vec2(_3477, _3479);\n    if (_3474.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3479)) * ((_3477 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3477)) * ((_3479 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7325 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7330 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7335 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7340 = fa_light_texel(param_3);\n    bool _7343 = _7340.z < 0.5;\n    bool _7351;\n    if (!_7343)\n    {\n        _7351 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7351 = _7343;\n    }\n    if (_7351)\n    {\n        return vec3(0.0);\n    }\n    float _7358 = max(_7325.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7361 = _7330.xyz;\n    vec3 _7365 = _7325.xyz;\n    vec3 _7369 = (fa_world_pos - _7365) / vec3(_7358);\n    vec3 _7378 = min(_7369 + vec3(0.5), (_7361 - vec3(0.5)) - _7369);\n    float _7387 = min(_7378.x, min(_7378.y, _7378.z));\n    if (!(_7387 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7402 = _7361 - vec3(1.0);\n    vec3 _7403 = clamp(_7369, vec3(0.0), _7402);\n    vec3 _7411 = min(floor(_7403), max(_7361 - vec3(2.0), vec3(0.0)));\n    vec3 _7415 = _7403 - _7411;\n    vec3 _7426 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7358));\n    int _7431 = int(_7335.y + 0.5);\n    float _7436 = 0.3257350027561187744140625 * n.y;\n    float _7440 = 0.3257350027561187744140625 * n.z;\n    float _7444 = 0.3257350027561187744140625 * n.x;\n    float _7451 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7458 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7467 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7474 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7487 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7494 = 8 + int(_7340.w);\n    float _7521;\n    float _7534;\n    float _7548;\n    for (int k = 0; k < _7494; k++)\n    {\n        float _7507 = float(k & 1);\n        float _7511 = float((k >> 1) & 1);\n        float _7515 = float((k >> 2) & 1);\n        if (_7507 > 0.5)\n        {\n            _7521 = _7415.x;\n        }\n        else\n        {\n            _7521 = 1.0 - _7415.x;\n        }\n        if (_7511 > 0.5)\n        {\n            _7534 = _7415.y;\n        }\n        else\n        {\n            _7534 = 1.0 - _7415.y;\n        }\n        if (_7515 > 0.5)\n        {\n            _7548 = _7415.z;\n        }\n        else\n        {\n            _7548 = 1.0 - _7415.z;\n        }\n        float _7558 = (_7521 * _7534) * _7548;\n        if (!(_7558 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7571 = min(_7411 + vec3(_7507, _7511, _7515), _7402);\n        int _7591 = int(((_7335.x + _7571.x) + (_7330.x * (_7571.y + (_7330.y * _7571.z)))) + 0.5);\n        vec2 _7606 = vec2(float(_7591 % _7431) * 10.0, 1024.0 + (float(_7591 / _7431) * 11.0));\n        vec2 param_4 = _7606 + vec2(9.5, 10.5);\n        vec4 _7614 = fa_gi_fetch(param_4);\n        bool _7617 = _7614.y < 0.5;\n        bool _7626;\n        if (!_7617)\n        {\n            _7626 = _7614.x > _7340.y;\n        }\n        else\n        {\n            _7626 = _7617;\n        }\n        if (_7626)\n        {\n            continue;\n        }\n        vec3 _7638 = _7426 - (_7365 + (_7571 * _7358));\n        float _7641 = length(_7638);\n        vec3 _7647 = _7638 / vec3(max(_7641, 9.9999997473787516355514526367188e-05));\n        float _7657 = max(9.9999997473787516355514526367188e-05, (dot(-_7647, n) + 1.0) * 0.5);\n        float w = _7558 * (_7657 * _7657);\n        vec3 param_5 = _7647;\n        vec2 param_6 = (_7606 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7676 = fa_gi_fetch(param_6);\n        float _7683 = _7641 / max(_7335.z, 9.9999997473787516355514526367188e-05);\n        float _7686 = _7676.x;\n        if (_7683 > _7686)\n        {\n            float _7699 = max(_7676.y - (_7686 * _7686), 0.0);\n            float _7704 = _7683 - _7686;\n            float _7713 = _7699 / max(_7699 + (_7704 * _7704), 9.9999999600419720025001879548654e-13);\n            w *= ((_7713 * _7713) * _7713);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7606 + vec2(0.5, 10.5);\n        vec2 param_8 = _7606 + vec2(1.5, 10.5);\n        vec2 param_9 = _7606 + vec2(2.5, 10.5);\n        vec2 param_10 = _7606 + vec2(3.5, 10.5);\n        vec2 param_11 = _7606 + vec2(4.5, 10.5);\n        vec2 param_12 = _7606 + vec2(5.5, 10.5);\n        vec2 param_13 = _7606 + vec2(6.5, 10.5);\n        vec2 param_14 = _7606 + vec2(7.5, 10.5);\n        vec2 param_15 = _7606 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7436)) + (fa_gi_fetch(param_9).xyz * _7440)) + (fa_gi_fetch(param_10).xyz * _7444)) + (fa_gi_fetch(param_11).xyz * _7451)) + (fa_gi_fetch(param_12).xyz * _7458)) + (fa_gi_fetch(param_13).xyz * _7467)) + (fa_gi_fetch(param_14).xyz * _7474)) + (fa_gi_fetch(param_15).xyz * _7487)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7387 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _7838;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _7838 = _7340.x;\n    }\n    else\n    {\n        _7838 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7335.w * _7838);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _7862 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _7867 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _7872 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _7872) && (k < 8); k++)\n    {\n        int param = _7867 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _7862;\n        vec3 _7897 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _7902 = param_3 * left;\n        acc += (_7897 * _7902);\n        left -= _7902;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _7931 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _7931;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5806;\n    if (fa_lm.z > 0.5)\n    {\n        _5806 = 0.0;\n    }\n    else\n    {\n        _5806 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5817 = _5806 < 1.0;\n    bool _5823;\n    if (_5817)\n    {\n        int param = li;\n        _5823 = fa_light_baked(param);\n    }\n    else\n    {\n        _5823 = _5817;\n    }\n    return _5823 ? _5806 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _843 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _856 = (c - (ru * hx)) - p;\n        vec3 _862 = ru * (2.0 * hx);\n        float _868 = max(dot(_862, _862), 9.9999999392252902907785028219223e-09);\n        float _872 = dot(_856, _862);\n        float t = clamp((-_872) / _868, 0.0, 1.0);\n        if (_843)\n        {\n            float _887 = dot(r, _862);\n            float _893 = _868 - (_887 * _887);\n            if (abs(_893) > (9.9999997473787516355514526367188e-06 * _868))\n            {\n                t = clamp(((dot(r, _856) * _887) - _872) / _893, 0.0, 1.0);\n            }\n        }\n        return (p + _856) + (_862 * t);\n    }\n    vec3 q = p;\n    float _925 = dot(r, axis);\n    bool _933;\n    if (_843)\n    {\n        _933 = abs(_925) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _933 = _843;\n    }\n    if (_933)\n    {\n        float _943 = dot(c - p, axis) / _925;\n        if (_943 > 0.0)\n        {\n            q = p + (r * _943);\n        }\n    }\n    vec3 _956 = q - c;\n    vec2 xy = vec2(dot(_956, ru), dot(_956, uu));\n    if (shape > 0.5)\n    {\n        float _971 = length(xy);\n        if (_971 > hx)\n        {\n            xy *= (hx / _971);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _604 = abs(d);\n    float _606 = _604.x;\n    float _608 = _604.y;\n    bool _609 = _606 >= _608;\n    bool _617;\n    if (_609)\n    {\n        _617 = _606 >= _604.z;\n    }\n    else\n    {\n        _617 = _609;\n    }\n    int _618;\n    if (_617)\n    {\n        _618 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _633;\n        if (_608 >= _604.z)\n        {\n            _633 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _633 = (d.z > 0.0) ? 4 : 5;\n        }\n        _618 = _633;\n    }\n    return _618;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _763 = dot(d, right);\n    float _767 = dot(d, up);\n    float _778;\n    if (((_763 * _763) + (_767 * _767)) > 1.0000000133514319600180897396058e-10)\n    {\n        _778 = atan(_767, _763) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _778 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_778 - floor(_778)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1009 = fa_light_base(param);\n    bool _1013 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1009;\n    vec4 _1017 = fa_light_texel(param_1);\n    int param_2 = _1009 + 1;\n    vec4 _1022 = fa_light_texel(param_2);\n    float _1025 = _1022.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1037 = _1013 && (_1025 > 2.5);\n    fa_light_is_area = _1037;\n    bool _1039 = _1025 < 0.5;\n    vec3 l;\n    if (_1039)\n    {\n        l = normalize(_1017.xyz);\n        if (_1013)\n        {\n            int param_3 = _1009 + 6;\n            vec4 _1053 = fa_light_texel(param_3);\n            if (_1053.z > 0.5)\n            {\n                int param_4 = _1009 + 4;\n                vec4 _1063 = fa_light_texel(param_4);\n                int param_5 = _1009 + 5;\n                vec4 _1068 = fa_light_texel(param_5);\n                vec2 param_6 = _1053.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1063.xyz) * _1063.w, (-dot(world_pos, _1068.xyz)) * _1068.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1098 = _1017.xyz;\n        vec3 _1100 = _1098 - world_pos;\n        vec3 to_light = _1100;\n        float _1103 = length(_1100);\n        float reach = _1103;\n        bool front = true;\n        if (_1037)\n        {\n            int param_8 = _1009 + 7;\n            reach = max(_1103 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1009 + 4;\n            vec4 _1127 = fa_light_texel(param_9);\n            int param_10 = _1009 + 5;\n            vec4 _1132 = fa_light_texel(param_10);\n            int param_11 = _1009 + 6;\n            vec4 _1137 = fa_light_texel(param_11);\n            float _1138 = _1137.w;\n            int param_12 = _1009 + 2;\n            vec3 _1145 = normalize(fa_light_texel(param_12).xyz);\n            bool _1147 = _1138 > 1.5;\n            bool _1155;\n            if (!_1147)\n            {\n                _1155 = dot(_1145, to_light) < 0.0;\n            }\n            else\n            {\n                _1155 = _1147;\n            }\n            front = _1155;\n            vec3 r = vec3(0.0);\n            vec3 _1164 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1168 = dot(n, n) > 0.5;\n            bool _1176;\n            if (_1168)\n            {\n                _1176 = dot(_1164, _1164) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1176 = _1168;\n            }\n            if (_1176)\n            {\n                r = reflect(-normalize(_1164), normalize(n));\n            }\n            vec3 param_13 = _1098;\n            vec3 param_14 = _1145;\n            vec3 param_15 = _1127.xyz;\n            vec3 param_16 = _1132.xyz;\n            float param_17 = _1127.w;\n            float param_18 = _1132.w;\n            float param_19 = _1138;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1212 = length(to_light);\n        dist = _1212;\n        l = to_light / vec3(max(_1212, 9.9999997473787516355514526367188e-05));\n        float _1226 = reach / max(_1017.w, 0.001000000047497451305389404296875);\n        float _1232 = clamp(1.0 - (_1226 * _1226), 0.0, 1.0);\n        float _1234;\n        if (front)\n        {\n            _1234 = _1232 * _1232;\n        }\n        else\n        {\n            _1234 = 0.0;\n        }\n        atten = _1234;\n        bool _1245 = _1025 < 2.5;\n        if ((_1025 > 1.5) && _1245)\n        {\n            int param_22 = _1009 + 2;\n            vec4 _1253 = fa_light_texel(param_22);\n            float _1263 = _1253.w;\n            int param_23 = _1009 + 3;\n            vec4 _1268 = fa_light_texel(param_23);\n            float _1269 = _1268.x;\n            float cos_inner = _1269;\n            if (_1269 > 1.5)\n            {\n                cos_inner = mix(_1263, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1263, cos_inner, dot(-l, normalize(_1253.xyz)));\n        }\n        if (_1013 && (_1025 < 1.5))\n        {\n            int param_24 = _1009 + 6;\n            vec4 _1293 = fa_light_texel(param_24);\n            if (_1293.z > 0.5)\n            {\n                vec3 _1301 = -to_light;\n                int param_25 = _1009 + 4;\n                int param_26 = _1009 + 5;\n                vec3 _1315 = fa_light_texel(param_25).xyz;\n                vec3 _1319 = fa_light_texel(param_26).xyz;\n                vec3 _1328 = vec3(dot(_1301, _1315), dot(_1301, _1319), dot(_1301, cross(_1315, _1319)));\n                vec3 param_27 = _1328;\n                int _1332 = fa_cube_face(param_27);\n                int param_28 = _1332;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1359 = vec2(dot(_1328, cross(param_29, param_30)), dot(_1328, param_30)) / vec2(max(dot(_1328, param_29), 9.9999997473787516355514526367188e-05));\n                int _1363 = _1332 / 3;\n                vec2 param_31 = _1293.xy + (vec2(float(_1332 - (_1363 * 3)), float(_1363)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1359.x), 0.5 - (0.5 * _1359.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1009 + 7;\n            vec4 _1393 = fa_light_texel(param_33);\n            if (_1393.z > 0.5)\n            {\n                int param_34 = _1009 + 2;\n                int param_35 = _1009 + 4;\n                int param_36 = _1009 + 5;\n                vec2 param_37 = _1393.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1013 && _1245)\n            {\n                int param_42 = _1009 + 6;\n                vec4 _1440 = fa_light_texel(param_42);\n                int param_43 = _1009 + 7;\n                vec4 _1445 = fa_light_texel(param_43);\n                bool _1448 = _1440.z > 0.5;\n                bool _1455;\n                if (!_1448)\n                {\n                    _1455 = _1445.z > 0.5;\n                }\n                else\n                {\n                    _1455 = _1448;\n                }\n                if (_1455)\n                {\n                    int param_44 = _1009 + 2;\n                    vec4 _1462 = fa_light_texel(param_44);\n                    vec3 _1466 = normalize(_1462.xyz);\n                    int param_45 = _1009 + 4;\n                    vec4 _1471 = fa_light_texel(param_45);\n                    int param_46 = _1009 + 5;\n                    vec4 _1476 = fa_light_texel(param_46);\n                    if (_1448)\n                    {\n                        vec3 _1484 = -to_light;\n                        float _1491 = _1462.w;\n                        float _1507 = 0.5 / max(dot(_1484, _1466) * (sqrt(max(1.0 - (_1491 * _1491), 0.0)) / max(_1491, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1440.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1484, _1471.xyz) * _1507), 0.5 - (dot(_1484, _1476.xyz) * _1507));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1445.z > 0.5)\n                    {\n                        vec2 param_49 = _1445.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1466;\n                        vec3 param_52 = _1471.xyz;\n                        vec3 param_53 = _1476.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9013 = _1022.xyz * atten;\n    if (_1013)\n    {\n        _9013 *= fa_light_tint;\n    }\n    int _1576;\n    if (_1039)\n    {\n        _1576 = 0;\n    }\n    else\n    {\n        _1576 = ((_1025 > 1.5) && (_1025 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9013, atten, 1.0, dist, _1576);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2308;\n    if (i == 0)\n    {\n        _2308 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2324;\n        if (i == 1)\n        {\n            _2324 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2332;\n            if (i == 2)\n            {\n                _2332 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2332 = fa_shadows[24].w;\n            }\n            _2324 = _2332;\n        }\n        _2308 = _2324;\n    }\n    return _2308;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2365 = fa_shadow_depth(param, param_1);\n    float _2369;\n    if (conv.x < 0.5)\n    {\n        _2369 = _2365;\n    }\n    else\n    {\n        _2369 = (conv.y * conv.z) / (conv.z - (_2365 * (conv.z - conv.y)));\n    }\n    return _2369;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2415 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2421 = vec2(cos(_2415), sin(_2415));\n    vec2 dir = _2421;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2430;\n        if (k < 0.0)\n        {\n            _2430 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2430 = k;\n        }\n        float _2449 = clamp((_2430 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2468 = sqrt((float(i) + 0.5) * 0.0625) * _2449;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2468));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2482 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2482 < (zr - (_2468 * plane)))\n            {\n                sum += _2482;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2510 = sum / cnt;\n        float _2520;\n        if (k < 0.0)\n        {\n            _2520 = (-k) / max(_2510, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2520 = k;\n        }\n        radius = clamp(((max(zr - _2510, 0.0) * unit) * _2520) / texel_m, 1.5, 16.0);\n        dir = _2421;\n    }\n    float lit = 0.0;\n    int _2546 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2546; i_1++)\n    {\n        float _2565 = sqrt((float(i_1) + 0.5) / float(_2546)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2565));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2565 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2546);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2611 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2616 = clamp(dot(n, l), 0.0, 1.0);\n    float _2622 = sqrt(1.0 - (_2616 * _2616));\n    float _2630 = min(_2622 / max(_2616, 0.20000000298023223876953125), 4.0);\n    float _2635;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2635 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2635 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2660 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2635 * _2622)), 1.0);\n    float _2667 = _2660.x;\n    bool _2670 = _2667 < fa_shadows[ci * 1 + 16].x;\n    bool _2679;\n    if (!_2670)\n    {\n        _2679 = _2667 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2679 = _2670;\n    }\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2660.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2660.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2704;\n    if (!_2697)\n    {\n        _2704 = _2660.z > 1.0;\n    }\n    else\n    {\n        _2704 = _2697;\n    }\n    if (_2704)\n    {\n        return -1.0;\n    }\n    float _2712;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2712 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2712 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2660.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2660.z - ((_2712 * (1.0 + (0.5 * _2630))) / _2611);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2611;\n    float param_5 = _2611 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2630, 3.0)) * 0.5) / _2611;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3090 = int(fa_shadows[25].x + 0.5);\n    if (_3090 < 1)\n    {\n        return 1.0;\n    }\n    float _3105 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3090 - 1;\n    if (_3105 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3117 = _3090 > 1;\n    bool _3124;\n    if (_3117)\n    {\n        _3124 = _3105 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3124 = _3117;\n    }\n    if (_3124)\n    {\n        ci = 1;\n    }\n    bool _3128 = _3090 > 2;\n    bool _3135;\n    if (_3128)\n    {\n        _3135 = _3105 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3135 = _3128;\n    }\n    if (_3135)\n    {\n        ci = 2;\n    }\n    bool _3139 = _3090 > 3;\n    bool _3146;\n    if (_3139)\n    {\n        _3146 = _3105 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3146 = _3139;\n    }\n    if (_3146)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3157 = min(_3090, 4);\n    float _3198;\n    for (int c = ci; c < _3157; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3177 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3177;\n            break;\n        }\n        if (_3177 < 0.0)\n        {\n            continue;\n        }\n        s = _3177;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3198 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3198 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3217 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3198, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3105 - (fa_shadow_split_at(param_7) - _3217)) / _3217, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3249;\n        if ((ci + 1) < _3090)\n        {\n            _3249 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3249 = 1.0;\n        }\n        s = mix(s, _3249, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2770 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2777;\n    if (!_2770)\n    {\n        _2777 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2777 = _2770;\n    }\n    if (_2777)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2790 = fa_light_texel(param);\n    float _2791 = _2790.x;\n    if (_2791 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2800 = int(_2791 + 0.5);\n    int param_1 = _2800;\n    vec4 _2804 = fa_light_texel(param_1);\n    int param_2 = _2800 + 1;\n    vec4 _2809 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2812 = _2804.y;\n    if (_2812 > 0.0)\n    {\n        float _2829 = 1.0 - smoothstep(0.75 * _2812, _2812, length(world - fa_shadows[27].xyz));\n        fade = _2829;\n        if (_2829 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2804.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2853 = (_2800 + 2) + (face * 6);\n    int param_4 = _2853;\n    int param_5 = _2853 + 1;\n    int param_6 = _2853 + 3;\n    vec4 _2867 = fa_light_texel(param_6);\n    int param_7 = _2853 + 4;\n    vec4 _2872 = fa_light_texel(param_7);\n    int param_8 = _2853 + 5;\n    vec4 _2877 = fa_light_texel(param_8);\n    float _2889 = _2877.x * max(dot(_2867, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2894 = clamp(dot(n, l), 0.0, 1.0);\n    float _2917 = clamp(dot(n, _2867.xyz), -1.0, 1.0);\n    float _2936 = min(sqrt(1.0 - (_2917 * _2917)) / max(abs(dot(n, world - lpos)) / max(dot(_2867, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2939 = _2809.y;\n    float _2941;\n    if (_2939 > 0.0)\n    {\n        _2941 = _2939;\n    }\n    else\n    {\n        _2941 = 1.5 * _2889;\n    }\n    vec4 _2961 = vec4(world + (n * (_2941 * sqrt(1.0 - (_2894 * _2894)))), 1.0);\n    float _2965 = dot(_2867, _2961);\n    float _2968 = _2877.y;\n    if (_2965 < _2968)\n    {\n        return 1.0;\n    }\n    vec2 _2983 = vec2(dot(fa_light_texel(param_4), _2961), dot(fa_light_texel(param_5), _2961)) / vec2(_2965);\n    float _2985 = _2983.x;\n    bool _2988 = _2985 < _2872.x;\n    bool _2997;\n    if (!_2988)\n    {\n        _2997 = _2985 > _2872.z;\n    }\n    else\n    {\n        _2997 = _2988;\n    }\n    bool _3006;\n    if (!_2997)\n    {\n        _3006 = _2983.y < _2872.y;\n    }\n    else\n    {\n        _3006 = _2997;\n    }\n    bool _3015;\n    if (!_3006)\n    {\n        _3015 = _2983.y > _2872.w;\n    }\n    else\n    {\n        _3015 = _3006;\n    }\n    if (_3015)\n    {\n        return 1.0;\n    }\n    float _3021 = _2809.x;\n    float _3023;\n    if (_3021 > 0.0)\n    {\n        _3023 = _3021;\n    }\n    else\n    {\n        _3023 = 1.5 * _2889;\n    }\n    vec2 param_9 = _2983;\n    vec4 param_10 = _2872;\n    float param_11 = _2965 - (_3023 * (1.0 + (0.5 * _2936)));\n    float param_12 = _2889;\n    float param_13 = 1.0;\n    float param_14 = _2877.z * 0.25;\n    float param_15 = (_2889 * min(_2936, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2968, _2877.z);\n    int param_17 = int(_2804.z + 0.5);\n    float param_18 = _2804.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5179 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5186;\n    if (!_5179)\n    {\n        _5186 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5186 = _5179;\n    }\n    if (_5186)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5199 = fa_light_texel(param);\n    float _5200 = _5199.y;\n    float len = _5200;\n    if (_5200 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5212 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5222 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5212);\n    if (_5222 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5228 = len;\n    float _5231 = min(_5228, 0.89999997615814208984375 * dist);\n    len = _5231;\n    float _5236 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5212);\n    float _5241 = _5236 + (0.5 * _5231);\n    vec3 _5247 = world + (gn * _5236);\n    float _5249 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5313;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5264 = (float(k) + _5249) * 0.083333335816860198974609375;\n        vec3 _5272 = _5247 + (l * (_5264 * len));\n        vec4 _5278 = vec4(_5272, 1.0);\n        float _5284 = dot(fa_mesh_fs_params[28], _5278);\n        if (_5284 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5304 = vec2(dot(fa_mesh_fs_params[26], _5278), dot(fa_mesh_fs_params[27], _5278)) / vec2(_5284);\n        float _5308 = _5304.x * 0.5;\n        float _5309 = _5308 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5313 = (_5304.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5313 = 0.5 - (_5304.y * 0.5);\n        }\n        bool _5329 = _5309 < 0.0;\n        bool _5336;\n        if (!_5329)\n        {\n            _5336 = _5309 >= 1.0;\n        }\n        else\n        {\n            _5336 = _5329;\n        }\n        bool _5343;\n        if (!_5336)\n        {\n            _5343 = _5313 < 0.0;\n        }\n        else\n        {\n            _5343 = _5336;\n        }\n        bool _5350;\n        if (!_5343)\n        {\n            _5350 = _5313 >= 1.0;\n        }\n        else\n        {\n            _5350 = _5343;\n        }\n        if (_5350)\n        {\n            break;\n        }\n        vec4 _5377 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5309, _5313) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5377.w < 0.5)\n        {\n            continue;\n        }\n        float _5396 = (dot(fa_mesh_fs_params[29].xyz, _5272) + fa_mesh_fs_params[29].w) - _5377.x;\n        if ((_5396 > _5236) && (_5396 < _5241))\n        {\n            occ = max(occ, (1.0 - (_5264 * _5264)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5309, 0.5 - _5308), min(_5313, 1.0 - _5313))));\n        }\n    }\n    return 1.0 - (occ * _5222);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5862 = fa_baked_keep(param);\n    if (_5862 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5888 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9082 = _5888.color;\n    float _9083 = _5888.attenuation;\n    float _9084 = _5888.shadow;\n    bool _5891 = _5888.type == 0;\n    if (_5891 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5888.direction;\n        float _5902 = fa_shadow_factor(param_5, param_6);\n        _9084 = _5902;\n        _9082 *= _5902;\n    }\n    else\n    {\n        bool _5913 = _5888.type != 0;\n        bool _5919;\n        if (_5913)\n        {\n            _5919 = _9083 > 0.0;\n        }\n        else\n        {\n            _5919 = _5913;\n        }\n        if (_5919)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5888.direction;\n            float _5938 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9084 = _5938;\n            _9082 *= _5938;\n        }\n    }\n    bool _5948 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5954;\n    if (_5948)\n    {\n        _5954 = _9083 > 0.0;\n    }\n    else\n    {\n        _5954 = _5948;\n    }\n    if (_5954)\n    {\n        float _5961;\n        if (_5891)\n        {\n            _5961 = 1000000000.0;\n        }\n        else\n        {\n            _5961 = _5888._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5888.direction;\n        float param_18 = _5961;\n        float _5979 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9084 *= _5979;\n        _9082 *= _5979;\n    }\n    float _5992 = _9083;\n    float _5993 = _5992 * _5862;\n    _9083 = _5993;\n    vec3 _5997 = _9082;\n    vec3 _5998 = _5997 * _5862;\n    _9082 = _5998;\n    return LightSample(_5888.direction, _5998, _5993, _9084, _5888._distance, _5888.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6032 = v - (n * dot(v, n));\n    vec3 t = _6032;\n    float _6036 = dot(_6032, _6032);\n    float l2 = _6036;\n    if (_6036 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6046;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6046 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6046 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6046;\n        l2 = dot(_6046, _6046);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6433;\n    if ((j == 0) || (j == 7))\n    {\n        _6433 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6443;\n        if ((j == 3) || (j == 4))\n        {\n            _6443 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6443 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6433 = _6443;\n    }\n    float _6464;\n    if ((j == 1) || (j == 2))\n    {\n        _6464 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6473;\n        if ((j == 5) || (j == 6))\n        {\n            _6473 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6473 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6464 = _6473;\n    }\n    return (pc + (ex * _6433)) + (ey * _6464);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6081 = dot(a, a);\n    float _6085 = dot(b, b);\n    if ((_6081 < 1.0000000195414813782625560981111e-24) || (_6085 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6099 = a * inversesqrt(_6081);\n    vec3 _6104 = b * inversesqrt(_6085);\n    float _6108 = dot(_6099, _6104);\n    float _6111 = abs(_6108);\n    float g = (((((((((((0.0416471660137176513671875 * _6111) - 0.1924748718738555908203125) * _6111) + 0.4179156124591827392578125) * _6111) - 0.616057217121124267578125) * _6111) + 0.777722418308258056640625) * _6111) - 0.999542415142059326171875) * _6111) + 1.570791721343994140625;\n    if (_6108 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6108 * _6108), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6099, _6104) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6168 = a.z > 0.0;\n    bool _6172 = b.z > 0.0;\n    if (_6168 && _6172)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6168 != _6172)\n        {\n            vec3 _6207 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6207.z = 0.0;\n            if (_6168)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6207;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6207;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6207;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6207;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6256 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6282 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6308 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6334 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6256;\n    vec3 param_1 = _6282;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6282;\n    vec3 param_7 = _6308;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6308;\n    vec3 param_13 = _6334;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6334;\n    vec3 param_19 = _6256;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6502 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6520;\n    for (int k = 0; k < (2 * _6502); k++)\n    {\n        bool _6517 = k >= _6502;\n        if (_6517)\n        {\n            _6520 = k - _6502;\n        }\n        else\n        {\n            _6520 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6502 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6566 = 2 * _6520;\n            int param_4 = _6566 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6566 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6566 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6603 = bvec4(_6517);\n        vec4 param_16 = vec4(_6603.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6603.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6603.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6603.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6614 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6517)\n        {\n            vec2 _9309 = sum;\n            _9309.y = _9309.y + _6614;\n            sum = _9309;\n        }\n        else\n        {\n            vec2 _9312 = sum;\n            _9312.x = _9312.x + _6614;\n            sum = _9312;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6638 = fa_light_base(param);\n    int param_1 = _6638;\n    int param_2 = _6638 + 1;\n    int param_3 = _6638 + 2;\n    int param_4 = _6638 + 4;\n    vec4 _6660 = fa_light_texel(param_4);\n    int param_5 = _6638 + 5;\n    vec4 _6665 = fa_light_texel(param_5);\n    int param_6 = _6638 + 6;\n    vec4 _6670 = fa_light_texel(param_6);\n    float _6671 = _6670.w;\n    vec3 _6676 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6678 = _6671 < 1.5;\n    bool _6685;\n    if (_6678)\n    {\n        _6685 = dot(normalize(fa_light_texel(param_3).xyz), _6676) >= 0.0;\n    }\n    else\n    {\n        _6685 = _6678;\n    }\n    if (_6685)\n    {\n        return vec3(0.0);\n    }\n    bool _6694 = (_6671 > 0.5) && _6678;\n    float _6698 = _6694 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6701 = _6660.xyz;\n    float _6703 = _6660.w;\n    vec3 _6709 = _6665.xyz;\n    float _6711 = _6665.w;\n    vec3 up = _6709 * (_6711 * _6698);\n    float _6717;\n    if (_6694)\n    {\n        _6717 = (3.1415927410125732421875 * _6703) * _6703;\n    }\n    else\n    {\n        _6717 = (4.0 * _6703) * _6711;\n    }\n    if (_6671 > 1.5)\n    {\n        vec3 _6743 = cross(_6701, -_6676);\n        vec3 perp = _6743;\n        float _6747 = dot(_6743, _6743);\n        vec3 _6750;\n        if (_6747 > 1.0000000133514319600180897396058e-10)\n        {\n            _6750 = perp * inversesqrt(_6747);\n        }\n        else\n        {\n            _6750 = _6709;\n        }\n        perp = _6750;\n        up = _6750 * _6711;\n    }\n    float _6771 = max(_6717, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6781 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6781;\n    vec3 param_10 = n;\n    vec3 param_11 = _6676;\n    vec3 param_12 = _6781;\n    vec3 param_13 = n;\n    vec3 param_14 = _6701 * (_6703 * _6698);\n    vec3 param_15 = _6781;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6812 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6812;\n    vec2 param_21 = _6812 + vec2(64.0, 0.0);\n    vec4 _6822 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6671;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6834 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6834.x) + (((f0 * _6822.x) + ((vec3(f90) - f0) * _6822.y)) * _6834.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6676, _6676)) + _6771) / _6771) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4916 = 1.0 / alpha;\n    return ((2.0 + _4916) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4916)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4951 = max(dot(L.nc, l), 0.0);\n    float _4957 = max(dot(L.nc, h), 0.0);\n    float _4966 = ((_4957 * _4957) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4966) * _4966)) * (0.5 / max(mix((2.0 * _4951) * L.coat_ndv, _4951 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4951)) * _4951;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _6871;\n    if (L.sheen_on)\n    {\n        _6871 = L.sheen_scale;\n    }\n    else\n    {\n        _6871 = 1.0;\n    }\n    vec3 result = base * (L.keep * _6871);\n    vec3 _6884 = normalize(l + v);\n    int param = li;\n    vec3 _6895 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _6904 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _6884), 0.0);\n        float param_3 = _6904;\n        float param_4 = ndv;\n        result += ((L.sheen * _6895) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6904)) * _6904) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _6884;\n        float param_8 = max(dot(v, _6884), 0.0);\n        result += (_6895 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4819 = tdh / at;\n    float _4823 = bdh / ab;\n    float _4835 = ((_4819 * _4819) + (_4823 * _4823)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4835) * _4835);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5015 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5094 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5094) * _5094);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5015);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5015));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4218 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4221 = _4218.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4221 * _4221, exp2((-9.27999973297119140625) * ndv)) * _4221) + _4218.y)) + _4218.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3526;\n    if (lv == 0)\n    {\n        _3526 = 0.0;\n    }\n    else\n    {\n        _3526 = res + 2.0;\n    }\n    float _3536;\n    if (lv == 0)\n    {\n        _3536 = 0.0;\n    }\n    else\n    {\n        _3536 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3526, _3536)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3582;\n    if (res > 64.5)\n    {\n        _3582 = 5.0;\n    }\n    else\n    {\n        _3582 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3597 = clamp(rough, 0.0, 1.0) * (_3582 - 1.0);\n    int _3604 = int(min(floor(_3597), _3582 - 2.0));\n    float _3609 = _3597 - float(_3604);\n    vec3 param = d;\n    vec2 _3613 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3604;\n    vec2 param_4 = _3613;\n    vec3 _3623 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3609 < 0.00200000009499490261077880859375)\n    {\n        return _3623;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3604 + 1;\n    vec2 param_8 = _3613;\n    return mix(_3623, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3609));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3696 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3703 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3710 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3716 = dot(bx.xyz, d);\n    float _3720 = dot(by.xyz, d);\n    float _3724 = dot(bz.xyz, d);\n    float _3730;\n    if (_3716 > 9.9999999747524270787835121154785e-07)\n    {\n        _3730 = (1.0 - _3696) / _3716;\n    }\n    else\n    {\n        float _3744;\n        if (_3716 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3744 = ((-1.0) - _3696) / _3716;\n        }\n        else\n        {\n            _3744 = 1000000015047466219876688855040.0;\n        }\n        _3730 = _3744;\n    }\n    float tx = _3730;\n    float _3761;\n    if (_3720 > 9.9999999747524270787835121154785e-07)\n    {\n        _3761 = (1.0 - _3703) / _3720;\n    }\n    else\n    {\n        float _3774;\n        if (_3720 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3774 = ((-1.0) - _3703) / _3720;\n        }\n        else\n        {\n            _3774 = 1000000015047466219876688855040.0;\n        }\n        _3761 = _3774;\n    }\n    float ty = _3761;\n    float _3790;\n    if (_3724 > 9.9999999747524270787835121154785e-07)\n    {\n        _3790 = (1.0 - _3710) / _3724;\n    }\n    else\n    {\n        float _3803;\n        if (_3724 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3803 = ((-1.0) - _3710) / _3724;\n        }\n        else\n        {\n            _3803 = 1000000015047466219876688855040.0;\n        }\n        _3790 = _3803;\n    }\n    float _3815 = tx;\n    float _3818 = (_3815 > 0.0) ? _3815 : 1000000015047466219876688855040.0;\n    tx = _3818;\n    float _3819 = ty;\n    float _3822 = (_3819 > 0.0) ? _3819 : 1000000015047466219876688855040.0;\n    ty = _3822;\n    float _3832 = min(_3818, min(_3822, (_3790 > 0.0) ? _3790 : 1000000015047466219876688855040.0));\n    if (_3832 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3848 = (fa_world_pos + (d * _3832)) - posw.xyz;\n    vec3 _3853;\n    if (dot(_3848, _3848) > 1.0000000133514319600180897396058e-10)\n    {\n        _3853 = normalize(_3848);\n    }\n    else\n    {\n        _3853 = d;\n    }\n    return _3853;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3899 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3899 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3927 = rough * rough;\n            float _3958 = 0.60000002384185791015625 * _3927;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3927)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3958, 0.0500000007450580596923828125 + _3958, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3927 * 0.60000002384185791015625));\n        }\n        outc = base * _3899;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4017 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4017 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4049 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4049 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4696;\n        if (L.aniso >= 0.0)\n        {\n            _4696 = L.b;\n        }\n        else\n        {\n            _4696 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4696, v), _4696), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4732 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4732.x) + (vec3(L.f90) * _4732.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4790 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4790.x) + _4790.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4260 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4260.x) + vec3(_4260.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5500 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5504 = fa_xm_origin(param_1);\n    vec2 _5510 = (uv * _5500) - vec2(0.5);\n    vec2 _5513 = fract(_5510);\n    vec2 _5516 = floor(_5510);\n    vec2 param_2 = _5500;\n    vec2 param_3 = _5504;\n    vec2 param_4 = _5516;\n    vec2 param_5 = _5500;\n    vec2 param_6 = _5504;\n    vec2 param_7 = _5516 + vec2(1.0, 0.0);\n    vec2 param_8 = _5500;\n    vec2 param_9 = _5504;\n    vec2 param_10 = _5516 + vec2(0.0, 1.0);\n    vec2 param_11 = _5500;\n    vec2 param_12 = _5504;\n    vec2 param_13 = _5516 + vec2(1.0);\n    vec3 _5558 = vec3(_5513.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5558), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5558), vec3(_5513.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5577 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5581 = clamp(lod, 0.0, _5577);\n    int _5585 = int(floor(_5581));\n    int param = _5585;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5595 = float(_5585);\n    float _5596 = _5581 - _5595;\n    bool _5598 = _5596 > 0.001000000047497451305389404296875;\n    bool _5605;\n    if (_5598)\n    {\n        _5605 = _5595 < _5577;\n    }\n    else\n    {\n        _5605 = _5598;\n    }\n    if (_5605)\n    {\n        int param_2 = _5585 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5596));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5631 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5631.x) + (vec3(f90) * _5631.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5659 = max(s.thickness, 0.0);\n    bool _5664 = _5659 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5664)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5659);\n    }\n    bool _5689 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5696;\n    if (!_5689)\n    {\n        _5696 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5696 = _5689;\n    }\n    if (_5696)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5664)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5659);\n    }\n    vec4 _5731 = vec4(world, 1.0);\n    float _5736 = dot(fa_mesh_fs_params[28], _5731);\n    vec2 uv = vec2(0.5);\n    if (_5736 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5754 = vec2(dot(fa_mesh_fs_params[26], _5731), dot(fa_mesh_fs_params[27], _5731)) / vec2(_5736);\n        float _5762;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5762 = (_5754.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5762 = 0.5 - (_5754.y * 0.5);\n        }\n        uv = vec2((_5754.x * 0.5) + 0.5, _5762);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3277 = int(fa_shadows[25].x + 0.5);\n    float _3287 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3292 = _3277 > 0;\n    bool _3301;\n    if (_3292)\n    {\n        int param = _3277 - 1;\n        _3301 = _3287 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3301 = _3292;\n    }\n    if (_3301)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3307 = _3277 > 1;\n        bool _3314;\n        if (_3307)\n        {\n            _3314 = _3287 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3314 = _3307;\n        }\n        if (_3314)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3320 = _3277 > 2;\n        bool _3327;\n        if (_3320)\n        {\n            _3327 = _3287 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3327 = _3320;\n        }\n        if (_3327)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3333 = _3277 > 3;\n        bool _3340;\n        if (_3333)\n        {\n            _3340 = _3287 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3340 = _3333;\n        }\n        if (_3340)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8741 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8741 = -_8741;\n    }\n    vec3 _8039 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8741, fa_world_tangent, fa_uv, fa_vertex_color, _8039, gl_FrontFacing);\n    Surface _8047 = fa_standard_surface(param_1);\n    vec3 _8772 = _8047.albedo;\n    float _8773 = _8047.alpha;\n    vec3 _8774 = _8047.normal;\n    float _8775 = _8047.metallic;\n    float _8776 = _8047.roughness;\n    float _8777 = _8047.occlusion;\n    vec3 _8778 = _8047.emission;\n    float _8779 = _8047.clearcoat;\n    float _8780 = _8047.clearcoat_roughness;\n    vec3 _8781 = _8047.sheen_color;\n    float _8782 = _8047.sheen_roughness;\n    float _8783 = _8047.anisotropy;\n    float _8784 = _8047.anisotropy_rotation;\n    float _8785 = _8047.specular;\n    float _8786 = _8047.ior;\n    vec3 _8787 = _8047.specular_color;\n    float _8788 = _8047.transmission;\n    float _8789 = _8047.thickness;\n    vec3 _8790 = _8047.attenuation_color;\n    float _8791 = _8047.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8741, fa_world_tangent, fa_uv, fa_vertex_color, _8039, gl_FrontFacing);\n    Surface param_3 = _8047;\n    surface(param_2, param_3);\n    _8772 = param_3.albedo;\n    _8773 = param_3.alpha;\n    _8774 = param_3.normal;\n    _8775 = param_3.metallic;\n    _8776 = param_3.roughness;\n    _8777 = param_3.occlusion;\n    _8778 = param_3.emission;\n    _8779 = param_3.clearcoat;\n    _8780 = param_3.clearcoat_roughness;\n    _8781 = param_3.sheen_color;\n    _8782 = param_3.sheen_roughness;\n    _8783 = param_3.anisotropy;\n    _8784 = param_3.anisotropy_rotation;\n    _8785 = param_3.specular;\n    _8786 = param_3.ior;\n    _8787 = param_3.specular_color;\n    _8788 = param_3.transmission;\n    _8789 = param_3.thickness;\n    _8790 = param_3.attenuation_color;\n    _8791 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8741;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8772 = param_6;\n    _8774 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8772;\n    }\n    else\n    {\n        vec3 _8087 = normalize(_8774);\n        float _8094 = clamp(_8775, 0.0, 1.0);\n        float _8098 = clamp(_8776, 0.0500000007450580596923828125, 1.0);\n        float _8102 = _8098 * _8098;\n        float _8106 = _8102 * _8102;\n        float _8111 = max(dot(_8087, _8039), 9.9999997473787516355514526367188e-05);\n        float _8117 = 1.0 - _8094;\n        float _8118 = clamp(_8788, 0.0, 1.0) * _8117;\n        vec3 _8127 = (_8772 * _8117) * (1.0 - _8118);\n        vec3 _8134 = mix(vec3(0.039999999105930328369140625), _8772, vec3(_8094));\n        vec3 f0 = _8134;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8741, fa_world_tangent, fa_uv, fa_vertex_color, _8039, gl_FrontFacing);\n        Surface param_9 = Surface(_8772, _8773, _8774, _8775, _8776, _8777, _8778, _8779, _8780, _8781, _8782, _8783, _8784, _8785, _8786, _8787, _8788, _8789, _8790, _8791);\n        vec3 param_10 = _8087;\n        vec3 param_11 = _8039;\n        float param_12 = _8094;\n        float param_13 = _8098;\n        vec3 param_14 = _8134;\n        FaLayers _8150 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8087;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8127) * _8777;\n        if (_8150.on)\n        {\n            lit *= _8150.base_scale;\n        }\n        int _8172 = fa_cl_ndir + fa_cl_local;\n        float _8237;\n        for (int ln = 0; ln < _8172; ln++)\n        {\n            int param_16 = ln;\n            int _8185 = fa_cl_light(param_16);\n            int param_17 = _8185;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8185;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8741;\n            LightSample _8201 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8209 = max(dot(_8087, _8201.direction), 0.0);\n            float _8215 = _8201.attenuation * _8201.shadow;\n            vec3 _8220 = normalize(_8201.direction + _8039);\n            float _8225 = max(dot(_8087, _8220), 0.0);\n            float _8230 = max(dot(_8039, _8220), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8150.on)\n                {\n                    _8237 = _8150.f90;\n                }\n                else\n                {\n                    _8237 = 1.0;\n                }\n                int param_21 = _8185;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8087;\n                vec3 param_24 = _8039;\n                vec3 param_25 = _8127;\n                vec3 param_26 = f0;\n                float param_27 = _8237;\n                float param_28 = _8098;\n                float param_29 = _8111;\n                float param_30 = _8215;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8150.on)\n                {\n                    FaLayers param_31 = _8150;\n                    vec3 param_32 = area;\n                    int param_33 = _8185;\n                    vec3 param_34 = _8087;\n                    vec3 param_35 = _8039;\n                    vec3 param_36 = _8201.direction;\n                    float param_37 = _8111;\n                    float param_38 = _8215;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8150.on)\n                {\n                    FaLayers param_39 = _8150;\n                    vec3 param_40 = _8127;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8087;\n                    vec3 param_43 = _8039;\n                    vec3 param_44 = _8201.direction;\n                    vec3 param_45 = _8220;\n                    float param_46 = _8209;\n                    float param_47 = _8111;\n                    float param_48 = _8225;\n                    float param_49 = _8230;\n                    float param_50 = _8102;\n                    float param_51 = _8106;\n                    int param_52 = _8185;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8215));\n                }\n                else\n                {\n                    float _8339 = ((_8225 * _8225) * (_8106 - 1.0)) + 1.0;\n                    int param_53 = _8185;\n                    lit += (((_8127 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8230, 5.0))) * (((_8106 / ((3.1415927410125732421875 * _8339) * _8339)) * (0.5 / max(mix((2.0 * _8209) * _8111, _8209 + _8111, _8102), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8209))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8209 * _8215));\n                }\n            }\n        }\n        if (_8150.on)\n        {\n            FaLayers param_54 = _8150;\n            vec3 param_55 = _8087;\n            vec3 param_56 = _8039;\n            vec3 param_57 = f0;\n            float param_58 = _8098;\n            float param_59 = _8777;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8087;\n            vec3 param_61 = _8039;\n            vec3 param_62 = f0;\n            float param_63 = _8098;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8777);\n        }\n        if (_8118 > 0.0)\n        {\n            float _8437;\n            if (_8150.on)\n            {\n                _8437 = _8150.f90;\n            }\n            else\n            {\n                _8437 = 1.0;\n            }\n            float _8445;\n            if (_8150.on)\n            {\n                _8445 = _8150.base_scale;\n            }\n            else\n            {\n                _8445 = 1.0;\n            }\n            Surface param_64 = Surface(_8772, _8773, _8774, _8775, _8776, _8777, _8778, _8779, _8780, _8781, _8782, _8783, _8784, _8785, _8786, _8787, _8788, _8789, _8790, _8791);\n            vec3 param_65 = _8087;\n            vec3 param_66 = _8039;\n            float param_67 = _8098;\n            vec3 param_68 = f0;\n            float param_69 = _8437;\n            float param_70 = _8445;\n            float param_71 = _8118;\n            float param_72 = fa_tr_blend;\n            vec3 _8469 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8469;\n        }\n        result = lit;\n    }\n    vec3 _8476 = result;\n    vec3 _8477 = _8476 + _8778;\n    result = _8477;\n    vec3 param_73 = _8477;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8486 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8493;\n    if (!_8486)\n    {\n        _8493 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8493 = _8486;\n    }\n    if (_8493)\n    {\n        vec3 _8502 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8508 = dot(_8502, fa_mesh_fs_params[9].xyz);\n        bool _8512 = fa_mesh_fs_params[9].w > 0.5;\n        float _8513;\n        if (_8512)\n        {\n            _8513 = _8508;\n        }\n        else\n        {\n            _8513 = length(_8502);\n        }\n        float _8525 = _8513 - fa_mesh_fs_params[8].x;\n        if (_8525 > 0.0)\n        {\n            float _8534 = fa_mesh_fs_params[7].w * _8525;\n            float tau = _8534 * _8534;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8550;\n                if (_8512)\n                {\n                    _8550 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8508);\n                }\n                else\n                {\n                    _8550 = fa_mesh_fs_params[0].y;\n                }\n                float _8571 = mix(_8550, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8513, 0.0, 1.0));\n                float _8575 = fa_world_pos.y - _8571;\n                float _8580 = _8571 - fa_mesh_fs_params[8].z;\n                float _8585 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8588 = _8580 <= 0.0;\n                bool _8589 = !_8588;\n                bool _8595;\n                if (_8589)\n                {\n                    _8595 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8595 = _8588;\n                }\n                float _8596;\n                if (_8595)\n                {\n                    _8596 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8596 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8580, 80.0));\n                }\n                bool _8623;\n                if (_8589)\n                {\n                    _8623 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8623 = _8588;\n                }\n                float _8624;\n                if (_8623)\n                {\n                    _8624 = fa_mesh_fs_params[8].y * _8580;\n                }\n                else\n                {\n                    _8624 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8580, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8649 = _8585 <= 0.0;\n                bool _8656;\n                if (!_8649)\n                {\n                    _8656 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8656 = _8649;\n                }\n                float _8657;\n                if (_8656)\n                {\n                    _8657 = fa_mesh_fs_params[8].y * _8585;\n                }\n                else\n                {\n                    _8657 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8585, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8684;\n                if (abs(_8575) < 0.001000000047497451305389404296875)\n                {\n                    _8684 = _8596;\n                }\n                else\n                {\n                    _8684 = (_8657 - _8624) / _8575;\n                }\n                tau += (_8525 * max(_8684, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8720 = 1.0 - fa_tr_blend;\n        result /= vec3(_8720);\n        _8773 *= _8720;\n    }\n    fa_frag_color = vec4(result, _8773);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_656",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2318",
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
            "inst_name": "_6973",
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _815 = base_t;\n    _815.x = _266.x;\n    _815.y = _266.y;\n    _815.z = _266.z;\n    base_t = _815;\n    vec4 _282 = (_815 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _770 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _823 = _319;\n        _823.x = _324.x;\n        _823.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _823;\n        _770 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _826 = mrt;\n    _826.x = _353.x;\n    _826.y = _353.y;\n    _826.z = _353.z;\n    mrt = _826;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _775 = fa_mesh_fs_params[20].x;\n    float _776 = fa_mesh_fs_params[20].y;\n    float _779 = fa_mesh_fs_params[20].z;\n    float _778 = fa_mesh_fs_params[21].w;\n    float _781 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _775 *= _395.y;\n            _776 *= _395.z;\n            _778 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _779 *= mrt.x;\n            _781 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _770, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _775, _776, fa_mesh_fs_params[21].xyz, _778, _779, fa_mesh_fs_params[20].w, _781, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _665 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _665 = -_665;\n    }\n    vec3 _577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _592 = normalize(param_2.normal);\n    vec3 _607 = normalize(vec3(dot(fa_pre_r0, _592), dot(fa_pre_r1, _592), dot(fa_pre_r2, _592)));\n    float _619 = _607.z;\n    vec2 e = _607.xy / vec2((abs(_607.x) + abs(_607.y)) + abs(_619));\n    if (_619 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _815 = base_t;\n    _815.x = _266.x;\n    _815.y = _266.y;\n    _815.z = _266.z;\n    base_t = _815;\n    vec4 _282 = (_815 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _770 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _823 = _319;\n        _823.x = _324.x;\n        _823.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _823;\n        _770 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _826 = mrt;\n    _826.x = _353.x;\n    _826.y = _353.y;\n    _826.z = _353.z;\n    mrt = _826;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _775 = fa_mesh_fs_params[20].x;\n    float _776 = fa_mesh_fs_params[20].y;\n    float _779 = fa_mesh_fs_params[20].z;\n    float _778 = fa_mesh_fs_params[21].w;\n    float _781 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _775 *= _395.y;\n            _776 *= _395.z;\n            _778 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _779 *= mrt.x;\n            _781 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _770, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _775, _776, fa_mesh_fs_params[21].xyz, _778, _779, fa_mesh_fs_params[20].w, _781, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _665 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _665 = -_665;\n    }\n    vec3 _577 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _577, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _592 = normalize(param_2.normal);\n    vec3 _607 = normalize(vec3(dot(fa_pre_r0, _592), dot(fa_pre_r1, _592), dot(fa_pre_r2, _592)));\n    float _619 = _607.z;\n    vec2 e = _607.xy / vec2((abs(_607.x) + abs(_607.y)) + abs(_619));\n    if (_619 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
