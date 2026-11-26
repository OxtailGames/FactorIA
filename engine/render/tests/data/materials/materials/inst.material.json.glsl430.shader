{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "d1200774cea097b39827c1b4e04c78590627c6e19a8743dd5b2416938bbf252b",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4531[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1594 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1601;\n    if (!_1594)\n    {\n        _1601 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1601 = _1594;\n    }\n    bool _1609;\n    if (!_1601)\n    {\n        _1609 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1609 = _1601;\n    }\n    bool _1616;\n    if (!_1609)\n    {\n        _1616 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1616 = _1609;\n    }\n    bool _1623;\n    if (!_1616)\n    {\n        _1623 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1623 = _1616;\n    }\n    if (_1623)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1633 = vec4(world_pos, 1.0);\n    float _1639 = dot(fa_mesh_fs_params[16], _1633);\n    if (!(_1639 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1661 = vec2(dot(fa_mesh_fs_params[14], _1633), dot(fa_mesh_fs_params[15], _1633)) / vec2(_1639);\n    int _1665 = int(fa_mesh_fs_params[18].x);\n    int _1669 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1669) + clamp(int(floor(((_1661.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1669 - 1)) * _1665)) + clamp(int(floor(((_1661.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1665 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1745 = fa_cluster_texel(param);\n    return ivec2(int(_1745.x), int(_1745.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5998 = fa_cluster_lookup(param);\n    fa_cl_slot = _5998.x;\n    fa_cl_local = _5998.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7187 = fa_linear_to_srgb(param);\n        c = _7187;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7195 = fa_srgb_to_linear(param_1);\n            c = _7195;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _538;\n    if (i.front_facing)\n    {\n        _538 = i.world_normal;\n    }\n    else\n    {\n        _538 = -i.world_normal;\n    }\n    vec3 _562 = normalize(i.world_tangent.xyz - (_538 * dot(_538, i.world_tangent.xyz)));\n    vec3 _589 = normalize(((_562 * m.x) + ((cross(_538, _562) * i.world_tangent.w) * m.y)) + (_538 * m.z));\n    vec3 _592;\n    if (i.front_facing)\n    {\n        _592 = _589;\n    }\n    else\n    {\n        _592 = -_589;\n    }\n    return _592;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7227 = fa_tex_fix(param_2, param_3);\n    vec4 _9508 = base_t;\n    _9508.x = _7227.x;\n    _9508.y = _7227.y;\n    _9508.z = _7227.z;\n    base_t = _9508;\n    vec4 _7241 = (_9508 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9273 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7275 = fa_tex_fix(param_6, param_7);\n        vec3 _7278 = (_7275 * 2.0) - vec3(1.0);\n        vec2 _7283 = _7278.xy * fa_mesh_fs_params[6].x;\n        vec3 _9516 = _7278;\n        _9516.x = _7283.x;\n        _9516.y = _7283.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9516;\n        _9273 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7313 = fa_tex_fix(param_12, param_13);\n    vec4 _9519 = mrt;\n    _9519.x = _7313.x;\n    _9519.y = _7313.y;\n    _9519.z = _7313.z;\n    mrt = _9519;\n    vec4 _7343 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7386 = fa_tex_fix(param_20, param_21);\n    float _9278 = fa_mesh_fs_params[20].x;\n    float _9279 = fa_mesh_fs_params[20].y;\n    float _9282 = fa_mesh_fs_params[20].z;\n    float _9281 = fa_mesh_fs_params[21].w;\n    float _9284 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9278 *= _7354.y;\n            _9279 *= _7354.z;\n            _9281 *= _7343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9282 *= mrt.x;\n            _9284 *= mrt.w;\n        }\n    }\n    return Surface(_7241.xyz, _7241.w, _9273, clamp(fa_mesh_fs_params[5].x * _7313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7386), _9278, _9279, fa_mesh_fs_params[21].xyz, _9281, _9282, fa_mesh_fs_params[20].w, _9284, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1825 = rect.zw - rect.xy;\n    vec2 _1829 = _1825 * atlas;\n    vec2 _1833 = ddx * _1829;\n    vec2 _1837 = ddy * _1829;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1825), clamp(0.5 * log2(max(max(dot(_1833, _1833), dot(_1837, _1837)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1870 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1877;\n    if (!_1870)\n    {\n        _1877 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1877 = _1870;\n    }\n    if (_1877)\n    {\n        return;\n    }\n    vec3 _1883 = dFdx(world_pos);\n    vec3 _1886 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1890 = fa_cluster_texel(param);\n    int _1894 = int(_1890.w);\n    if (_1894 < 1)\n    {\n        return;\n    }\n    int _1904 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1904;\n    vec4 _1908 = fa_light_texel(param_1);\n    vec2 _1911 = _1908.yz;\n    int _1915 = int(_1908.w);\n    int param_2 = _1904 + 1;\n    vec4 _1920 = fa_light_texel(param_2);\n    float _1921 = _1920.x;\n    int _1927 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1931 = int(_1890.z);\n    vec3 _2196;\n    for (int k = 0; k < _1894; k++)\n    {\n        int _1944 = _1931 + k;\n        int param_3 = _1915 + (_1944 >> 2);\n        int _1961 = (_1904 + 2) + (int(fa_light_texel(param_3)[_1944 & 3]) * 7);\n        int param_4 = _1961 + 6;\n        vec4 _1966 = fa_light_texel(param_4);\n        if (((int(_1966.w + 0.5) >> _1927) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1961;\n        vec4 _1981 = fa_light_texel(param_5);\n        int param_6 = _1961 + 1;\n        vec4 _1986 = fa_light_texel(param_6);\n        int param_7 = _1961 + 2;\n        vec4 _1991 = fa_light_texel(param_7);\n        vec3 _1994 = _1981.xyz;\n        float _1999 = dot(_1994, world_pos) + _1981.w;\n        vec3 _2001 = _1986.xyz;\n        float _2006 = dot(_2001, world_pos) + _1986.w;\n        vec3 _2008 = _1991.xyz;\n        float _2013 = dot(_2008, world_pos) + _1991.w;\n        bool _2018 = abs(_1999) > 0.5;\n        bool _2026;\n        if (!_2018)\n        {\n            _2026 = abs(_2006) > 0.5;\n        }\n        else\n        {\n            _2026 = _2018;\n        }\n        bool _2034;\n        if (!_2026)\n        {\n            _2034 = abs(_2013) > 0.5;\n        }\n        else\n        {\n            _2034 = _2026;\n        }\n        if (_2034)\n        {\n            continue;\n        }\n        float _2049 = clamp(dot(geo_normal, normalize(_2008)) * _1966.z, 0.0, 1.0);\n        if (_2049 <= 0.0)\n        {\n            continue;\n        }\n        float _2069 = (clamp((0.5 - abs(_2013)) * 10.0, 0.0, 1.0) * _2049) * _1966.x;\n        vec2 _2077 = vec2(_1999 + 0.5, 0.5 - _2006);\n        vec2 _2087 = vec2(dot(_1994, _1883), dot(_2001, _1883));\n        vec2 _2097 = vec2(dot(_1994, _1886), dot(_2001, _1886));\n        int param_8 = _1961 + 5;\n        vec4 _2102 = fa_light_texel(param_8);\n        int param_9 = _1961 + 3;\n        vec4 _2107 = fa_light_texel(param_9);\n        int param_10 = _1961 + 4;\n        vec4 _2112 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2102.xyz;\n        bool _2122 = _2107.z > _2107.x;\n        if (_2122)\n        {\n            vec4 param_11 = _2107;\n            vec2 param_12 = _2077;\n            vec2 param_13 = _1911;\n            vec2 param_14 = _2087;\n            vec2 param_15 = _2097;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1921 > 0.5) && (_1921 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2148 = fa_dc_to_linear(param_16);\n                vec4 _9361 = tx;\n                _9361.x = _2148.x;\n                _9361.y = _2148.y;\n                _9361.z = _2148.z;\n                tx = _9361;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2069 * tex_a) * _2102.w, 0.0, 1.0)));\n        if (_2112.z > _2112.x)\n        {\n            vec4 param_17 = _2112;\n            vec2 param_18 = _2077;\n            vec2 param_19 = _1911;\n            vec2 param_20 = _2087;\n            vec2 param_21 = _2097;\n            vec4 _2192 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1921 > 1.5)\n            {\n                vec3 param_22 = _2192.xyz;\n                vec3 _2202 = fa_dc_to_srgb(param_22);\n                _2196 = _2202;\n            }\n            else\n            {\n                _2196 = _2192.xyz;\n            }\n            vec3 _2211 = (_2196 * 2.0) - vec3(1.0);\n            vec2 _2216 = _2211.xy * _1966.y;\n            vec3 _2238 = (normalize(_1994) * _2216.x) + (normalize(_2001) * _2216.y);\n            vec3 _2241 = normalize(normal);\n            normal = normalize(mix(_2241, normalize((_2241 * max(_2211.z, 0.0500000007450580596923828125)) + (_2238 - (_2241 * dot(_2241, _2238)))), vec3(clamp(_2069 * (_2122 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4456 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4464 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4467 = int(_4456);\n    int _4470 = int(_4464);\n    float _4480 = _4464 - float(_4470);\n    int _4535 = (_4467 * 9) + _4470;\n    int _4555 = ((_4467 + 1) * 9) + _4470;\n    return mix(mix(_4531[_4535], _4531[_4535 + 1], _4480), mix(_4531[_4555], _4531[_4555 + 1], _4480), _4456 - float(_4467));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9196 = false;\n    float _9197 = 1.0;\n    float _9198 = 1.0;\n    float _9199 = 1.0;\n    float _9200 = 0.0;\n    float _9201 = 0.0;\n    float _9202 = 0.0;\n    float _9203 = 0.0;\n    float _9205 = 1.0;\n    bool _9206 = false;\n    vec3 _9207 = vec3(0.0);\n    float _9208 = 1.0;\n    float _9209 = 1.0;\n    float _9210 = 1.0;\n    float _9211 = 0.0;\n    float _9212 = 0.0;\n    vec3 _9213 = vec3(1.0, 0.0, 0.0);\n    vec3 _9214 = vec3(0.0, 0.0, 1.0);\n    float _9215 = 1.0;\n    float _9216 = 1.0;\n    float _4606 = clamp(s.specular, 0.0, 1.0);\n    float _4610 = clamp(s.ior, 1.0, 3.0);\n    bool _4615 = (_4606 != 1.0) || (_4610 != 1.5);\n    bool _4624;\n    if (!_4615)\n    {\n        _4624 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4624 = _4615;\n    }\n    if (_4624)\n    {\n        float _4632 = (_4610 - 1.0) / (_4610 + 1.0);\n        f0 = mix(min(vec3(_4632 * _4632) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4606, s.albedo, vec3(metallic));\n        _9197 = mix(_4606, 1.0, metallic);\n        _9196 = true;\n    }\n    float _4659 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4659 > 0.0)\n    {\n        float _4667 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9200 = _4659;\n        _9201 = _4667;\n        float _4674 = _4667 * _4667;\n        _9202 = _4674;\n        _9203 = _4674 * _4674;\n        float _4686 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9205 = _4686;\n        _9198 = 1.0 - (_4659 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4686, 0.0, 1.0), 5.0))));\n        _9196 = true;\n    }\n    vec3 _4705 = max(s.sheen_color, vec3(0.0));\n    float _4714 = max(_4705.x, max(_4705.y, _4705.z));\n    if (_4714 > 0.0)\n    {\n        float _4722 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9206 = true;\n        _9207 = _4705;\n        _9208 = _4722;\n        _9209 = _4722 * _4722;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4722;\n        float _4739 = fa_sheen_albedo(param, param_1);\n        _9211 = _4739;\n        _9210 = 1.0 - min(_4714 * _4739, 1.0);\n        _9196 = true;\n    }\n    _9199 = _9198 * _9210;\n    float _4758 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4758 != 0.0)\n    {\n        vec3 _4773 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4773;\n        if (dot(_4773, _4773) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4785 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4785.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4785.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4785.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4789 = t;\n        vec3 _4790 = normalize(_4789);\n        t = _4790;\n        vec3 _4815 = normalize((_4790 * cos(s.anisotropy_rotation)) + ((cross(n, _4790) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9213 = _4815;\n        _9214 = cross(n, _4815);\n        float _4825 = roughness * roughness;\n        float _4831 = mix(_4825, 1.0, _4758 * _4758);\n        bool _4833 = _4758 > 0.0;\n        _9215 = _4833 ? _4831 : _4825;\n        _9216 = _4833 ? _4825 : _4831;\n        _9212 = _4758;\n        _9196 = true;\n    }\n    return FaLayers(_9196, _9197, _9198, _9199, _9200, _9201, _9202, _9203, i.world_normal, _9205, _9206, _9207, _9208, _9209, _9210, _9211, _9212, _9213, _9214, _9215, _9216);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3625 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3625;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4237 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4242 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4237 > 0.0005000000237487256526947021484375)\n    {\n        if (_4242)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4237;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4237;\n        }\n    }\n    bool _4293 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4293)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4324 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4324)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4242 || _4293) || _4324)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3645 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3648 = _3645.x;\n    float _3650 = _3645.z;\n    vec2 e = vec2(_3648, _3650);\n    if (_3645.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3650)) * ((_3648 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3648)) * ((_3650 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7496 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7501 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7506 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7511 = fa_light_texel(param_3);\n    bool _7514 = _7511.z < 0.5;\n    bool _7522;\n    if (!_7514)\n    {\n        _7522 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7522 = _7514;\n    }\n    if (_7522)\n    {\n        return vec3(0.0);\n    }\n    float _7529 = max(_7496.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7532 = _7501.xyz;\n    vec3 _7536 = _7496.xyz;\n    vec3 _7540 = (fa_world_pos - _7536) / vec3(_7529);\n    vec3 _7549 = min(_7540 + vec3(0.5), (_7532 - vec3(0.5)) - _7540);\n    float _7558 = min(_7549.x, min(_7549.y, _7549.z));\n    if (!(_7558 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7573 = _7532 - vec3(1.0);\n    vec3 _7574 = clamp(_7540, vec3(0.0), _7573);\n    vec3 _7582 = min(floor(_7574), max(_7532 - vec3(2.0), vec3(0.0)));\n    vec3 _7586 = _7574 - _7582;\n    vec3 _7597 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7529));\n    int _7602 = int(_7506.y + 0.5);\n    float _7607 = 0.3257350027561187744140625 * n.y;\n    float _7611 = 0.3257350027561187744140625 * n.z;\n    float _7615 = 0.3257350027561187744140625 * n.x;\n    float _7622 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7629 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7638 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7645 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7658 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7665 = 8 + int(_7511.w);\n    float _7692;\n    float _7705;\n    float _7719;\n    for (int k = 0; k < _7665; k++)\n    {\n        float _7678 = float(k & 1);\n        float _7682 = float((k >> 1) & 1);\n        float _7686 = float((k >> 2) & 1);\n        if (_7678 > 0.5)\n        {\n            _7692 = _7586.x;\n        }\n        else\n        {\n            _7692 = 1.0 - _7586.x;\n        }\n        if (_7682 > 0.5)\n        {\n            _7705 = _7586.y;\n        }\n        else\n        {\n            _7705 = 1.0 - _7586.y;\n        }\n        if (_7686 > 0.5)\n        {\n            _7719 = _7586.z;\n        }\n        else\n        {\n            _7719 = 1.0 - _7586.z;\n        }\n        float _7729 = (_7692 * _7705) * _7719;\n        if (!(_7729 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7742 = min(_7582 + vec3(_7678, _7682, _7686), _7573);\n        int _7762 = int(((_7506.x + _7742.x) + (_7501.x * (_7742.y + (_7501.y * _7742.z)))) + 0.5);\n        vec2 _7777 = vec2(float(_7762 % _7602) * 10.0, 1024.0 + (float(_7762 / _7602) * 11.0));\n        vec2 param_4 = _7777 + vec2(9.5, 10.5);\n        vec4 _7785 = fa_gi_fetch(param_4);\n        bool _7788 = _7785.y < 0.5;\n        bool _7797;\n        if (!_7788)\n        {\n            _7797 = _7785.x > _7511.y;\n        }\n        else\n        {\n            _7797 = _7788;\n        }\n        if (_7797)\n        {\n            continue;\n        }\n        vec3 _7809 = _7597 - (_7536 + (_7742 * _7529));\n        float _7812 = length(_7809);\n        vec3 _7818 = _7809 / vec3(max(_7812, 9.9999997473787516355514526367188e-05));\n        float _7828 = max(9.9999997473787516355514526367188e-05, (dot(-_7818, n) + 1.0) * 0.5);\n        float w = _7729 * (_7828 * _7828);\n        vec3 param_5 = _7818;\n        vec2 param_6 = (_7777 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7847 = fa_gi_fetch(param_6);\n        float _7854 = _7812 / max(_7506.z, 9.9999997473787516355514526367188e-05);\n        float _7857 = _7847.x;\n        if (_7854 > _7857)\n        {\n            float _7870 = max(_7847.y - (_7857 * _7857), 0.0);\n            float _7875 = _7854 - _7857;\n            float _7884 = _7870 / max(_7870 + (_7875 * _7875), 9.9999999600419720025001879548654e-13);\n            w *= ((_7884 * _7884) * _7884);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7777 + vec2(0.5, 10.5);\n        vec2 param_8 = _7777 + vec2(1.5, 10.5);\n        vec2 param_9 = _7777 + vec2(2.5, 10.5);\n        vec2 param_10 = _7777 + vec2(3.5, 10.5);\n        vec2 param_11 = _7777 + vec2(4.5, 10.5);\n        vec2 param_12 = _7777 + vec2(5.5, 10.5);\n        vec2 param_13 = _7777 + vec2(6.5, 10.5);\n        vec2 param_14 = _7777 + vec2(7.5, 10.5);\n        vec2 param_15 = _7777 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7607)) + (fa_gi_fetch(param_9).xyz * _7611)) + (fa_gi_fetch(param_10).xyz * _7615)) + (fa_gi_fetch(param_11).xyz * _7622)) + (fa_gi_fetch(param_12).xyz * _7629)) + (fa_gi_fetch(param_13).xyz * _7638)) + (fa_gi_fetch(param_14).xyz * _7645)) + (fa_gi_fetch(param_15).xyz * _7658)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7558 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8009;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8009 = _7511.x;\n    }\n    else\n    {\n        _8009 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7506.w * _8009);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8033 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8038 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8043 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8043) && (k < 8); k++)\n    {\n        int param = _8038 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8033;\n        vec3 _8068 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8073 = param_3 * left;\n        acc += (_8068 * _8073);\n        left -= _8073;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8102 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8102;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5968;\n    if (fa_lm.z > 0.5)\n    {\n        _5968 = 0.0;\n    }\n    else\n    {\n        _5968 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5979 = _5968 < 1.0;\n    bool _5985;\n    if (_5979)\n    {\n        int param = li;\n        _5985 = fa_light_baked(param);\n    }\n    else\n    {\n        _5985 = _5979;\n    }\n    return _5985 ? _5968 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _843 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _856 = (c - (ru * hx)) - p;\n        vec3 _862 = ru * (2.0 * hx);\n        float _868 = max(dot(_862, _862), 9.9999999392252902907785028219223e-09);\n        float _872 = dot(_856, _862);\n        float t = clamp((-_872) / _868, 0.0, 1.0);\n        if (_843)\n        {\n            float _887 = dot(r, _862);\n            float _893 = _868 - (_887 * _887);\n            if (abs(_893) > (9.9999997473787516355514526367188e-06 * _868))\n            {\n                t = clamp(((dot(r, _856) * _887) - _872) / _893, 0.0, 1.0);\n            }\n        }\n        return (p + _856) + (_862 * t);\n    }\n    vec3 q = p;\n    float _925 = dot(r, axis);\n    bool _933;\n    if (_843)\n    {\n        _933 = abs(_925) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _933 = _843;\n    }\n    if (_933)\n    {\n        float _943 = dot(c - p, axis) / _925;\n        if (_943 > 0.0)\n        {\n            q = p + (r * _943);\n        }\n    }\n    vec3 _956 = q - c;\n    vec2 xy = vec2(dot(_956, ru), dot(_956, uu));\n    if (shape > 0.5)\n    {\n        float _971 = length(xy);\n        if (_971 > hx)\n        {\n            xy *= (hx / _971);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _604 = abs(d);\n    float _606 = _604.x;\n    float _608 = _604.y;\n    bool _609 = _606 >= _608;\n    bool _617;\n    if (_609)\n    {\n        _617 = _606 >= _604.z;\n    }\n    else\n    {\n        _617 = _609;\n    }\n    int _618;\n    if (_617)\n    {\n        _618 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _633;\n        if (_608 >= _604.z)\n        {\n            _633 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _633 = (d.z > 0.0) ? 4 : 5;\n        }\n        _618 = _633;\n    }\n    return _618;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _763 = dot(d, right);\n    float _767 = dot(d, up);\n    float _778;\n    if (((_763 * _763) + (_767 * _767)) > 1.0000000133514319600180897396058e-10)\n    {\n        _778 = atan(_767, _763) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _778 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_778 - floor(_778)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1009 = fa_light_base(param);\n    bool _1013 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1009;\n    vec4 _1017 = fa_light_texel(param_1);\n    int param_2 = _1009 + 1;\n    vec4 _1022 = fa_light_texel(param_2);\n    float _1025 = _1022.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1037 = _1013 && (_1025 > 2.5);\n    fa_light_is_area = _1037;\n    bool _1039 = _1025 < 0.5;\n    vec3 l;\n    if (_1039)\n    {\n        l = normalize(_1017.xyz);\n        if (_1013)\n        {\n            int param_3 = _1009 + 6;\n            vec4 _1053 = fa_light_texel(param_3);\n            if (_1053.z > 0.5)\n            {\n                int param_4 = _1009 + 4;\n                vec4 _1063 = fa_light_texel(param_4);\n                int param_5 = _1009 + 5;\n                vec4 _1068 = fa_light_texel(param_5);\n                vec2 param_6 = _1053.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1063.xyz) * _1063.w, (-dot(world_pos, _1068.xyz)) * _1068.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1098 = _1017.xyz;\n        vec3 _1100 = _1098 - world_pos;\n        vec3 to_light = _1100;\n        float _1103 = length(_1100);\n        float reach = _1103;\n        bool front = true;\n        if (_1037)\n        {\n            int param_8 = _1009 + 7;\n            reach = max(_1103 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1009 + 4;\n            vec4 _1127 = fa_light_texel(param_9);\n            int param_10 = _1009 + 5;\n            vec4 _1132 = fa_light_texel(param_10);\n            int param_11 = _1009 + 6;\n            vec4 _1137 = fa_light_texel(param_11);\n            float _1138 = _1137.w;\n            int param_12 = _1009 + 2;\n            vec3 _1145 = normalize(fa_light_texel(param_12).xyz);\n            bool _1147 = _1138 > 1.5;\n            bool _1155;\n            if (!_1147)\n            {\n                _1155 = dot(_1145, to_light) < 0.0;\n            }\n            else\n            {\n                _1155 = _1147;\n            }\n            front = _1155;\n            vec3 r = vec3(0.0);\n            vec3 _1164 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1168 = dot(n, n) > 0.5;\n            bool _1176;\n            if (_1168)\n            {\n                _1176 = dot(_1164, _1164) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1176 = _1168;\n            }\n            if (_1176)\n            {\n                r = reflect(-normalize(_1164), normalize(n));\n            }\n            vec3 param_13 = _1098;\n            vec3 param_14 = _1145;\n            vec3 param_15 = _1127.xyz;\n            vec3 param_16 = _1132.xyz;\n            float param_17 = _1127.w;\n            float param_18 = _1132.w;\n            float param_19 = _1138;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1212 = length(to_light);\n        dist = _1212;\n        l = to_light / vec3(max(_1212, 9.9999997473787516355514526367188e-05));\n        float _1226 = reach / max(_1017.w, 0.001000000047497451305389404296875);\n        float _1232 = clamp(1.0 - (_1226 * _1226), 0.0, 1.0);\n        float _1234;\n        if (front)\n        {\n            _1234 = _1232 * _1232;\n        }\n        else\n        {\n            _1234 = 0.0;\n        }\n        atten = _1234;\n        bool _1245 = _1025 < 2.5;\n        if ((_1025 > 1.5) && _1245)\n        {\n            int param_22 = _1009 + 2;\n            vec4 _1253 = fa_light_texel(param_22);\n            float _1263 = _1253.w;\n            int param_23 = _1009 + 3;\n            vec4 _1268 = fa_light_texel(param_23);\n            float _1269 = _1268.x;\n            float cos_inner = _1269;\n            if (_1269 > 1.5)\n            {\n                cos_inner = mix(_1263, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1263, cos_inner, dot(-l, normalize(_1253.xyz)));\n        }\n        if (_1013 && (_1025 < 1.5))\n        {\n            int param_24 = _1009 + 6;\n            vec4 _1293 = fa_light_texel(param_24);\n            if (_1293.z > 0.5)\n            {\n                vec3 _1301 = -to_light;\n                int param_25 = _1009 + 4;\n                int param_26 = _1009 + 5;\n                vec3 _1315 = fa_light_texel(param_25).xyz;\n                vec3 _1319 = fa_light_texel(param_26).xyz;\n                vec3 _1328 = vec3(dot(_1301, _1315), dot(_1301, _1319), dot(_1301, cross(_1315, _1319)));\n                vec3 param_27 = _1328;\n                int _1332 = fa_cube_face(param_27);\n                int param_28 = _1332;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1359 = vec2(dot(_1328, cross(param_29, param_30)), dot(_1328, param_30)) / vec2(max(dot(_1328, param_29), 9.9999997473787516355514526367188e-05));\n                int _1363 = _1332 / 3;\n                vec2 param_31 = _1293.xy + (vec2(float(_1332 - (_1363 * 3)), float(_1363)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1359.x), 0.5 - (0.5 * _1359.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1009 + 7;\n            vec4 _1393 = fa_light_texel(param_33);\n            if (_1393.z > 0.5)\n            {\n                int param_34 = _1009 + 2;\n                int param_35 = _1009 + 4;\n                int param_36 = _1009 + 5;\n                vec2 param_37 = _1393.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1013 && _1245)\n            {\n                int param_42 = _1009 + 6;\n                vec4 _1440 = fa_light_texel(param_42);\n                int param_43 = _1009 + 7;\n                vec4 _1445 = fa_light_texel(param_43);\n                bool _1448 = _1440.z > 0.5;\n                bool _1455;\n                if (!_1448)\n                {\n                    _1455 = _1445.z > 0.5;\n                }\n                else\n                {\n                    _1455 = _1448;\n                }\n                if (_1455)\n                {\n                    int param_44 = _1009 + 2;\n                    vec4 _1462 = fa_light_texel(param_44);\n                    vec3 _1466 = normalize(_1462.xyz);\n                    int param_45 = _1009 + 4;\n                    vec4 _1471 = fa_light_texel(param_45);\n                    int param_46 = _1009 + 5;\n                    vec4 _1476 = fa_light_texel(param_46);\n                    if (_1448)\n                    {\n                        vec3 _1484 = -to_light;\n                        float _1491 = _1462.w;\n                        float _1507 = 0.5 / max(dot(_1484, _1466) * (sqrt(max(1.0 - (_1491 * _1491), 0.0)) / max(_1491, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1440.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1484, _1471.xyz) * _1507), 0.5 - (dot(_1484, _1476.xyz) * _1507));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1445.z > 0.5)\n                    {\n                        vec2 param_49 = _1445.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1466;\n                        vec3 param_52 = _1471.xyz;\n                        vec3 param_53 = _1476.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9184 = _1022.xyz * atten;\n    if (_1013)\n    {\n        _9184 *= fa_light_tint;\n    }\n    int _1576;\n    if (_1039)\n    {\n        _1576 = 0;\n    }\n    else\n    {\n        _1576 = ((_1025 > 1.5) && (_1025 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9184, atten, 1.0, dist, _1576);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2308;\n    if (i == 0)\n    {\n        _2308 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2324;\n        if (i == 1)\n        {\n            _2324 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2332;\n            if (i == 2)\n            {\n                _2332 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2332 = fa_shadows[24].w;\n            }\n            _2324 = _2332;\n        }\n        _2308 = _2324;\n    }\n    return _2308;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2365 = fa_shadow_depth(param, param_1);\n    float _2369;\n    if (conv.x < 0.5)\n    {\n        _2369 = _2365;\n    }\n    else\n    {\n        _2369 = (conv.y * conv.z) / (conv.z - (_2365 * (conv.z - conv.y)));\n    }\n    return _2369;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2415 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2421 = vec2(cos(_2415), sin(_2415));\n    vec2 dir = _2421;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2430;\n        if (k < 0.0)\n        {\n            _2430 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2430 = k;\n        }\n        float _2449 = clamp((_2430 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2468 = sqrt((float(i) + 0.5) * 0.0625) * _2449;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2468));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2482 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2482 < (zr - (_2468 * plane)))\n            {\n                sum += _2482;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2510 = sum / cnt;\n        float _2520;\n        if (k < 0.0)\n        {\n            _2520 = (-k) / max(_2510, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2520 = k;\n        }\n        radius = clamp(((max(zr - _2510, 0.0) * unit) * _2520) / texel_m, 1.5, 16.0);\n        dir = _2421;\n    }\n    float lit = 0.0;\n    int _2546 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2546; i_1++)\n    {\n        float _2565 = sqrt((float(i_1) + 0.5) / float(_2546)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2565));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2565 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2546);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2611 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2616 = clamp(dot(n, l), 0.0, 1.0);\n    float _2622 = sqrt(1.0 - (_2616 * _2616));\n    float _2630 = min(_2622 / max(_2616, 0.20000000298023223876953125), 4.0);\n    float _2635;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2635 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2635 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2660 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2635 * _2622)), 1.0);\n    float _2667 = _2660.x;\n    bool _2670 = _2667 < fa_shadows[ci * 1 + 16].x;\n    bool _2679;\n    if (!_2670)\n    {\n        _2679 = _2667 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2679 = _2670;\n    }\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2660.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2660.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2704;\n    if (!_2697)\n    {\n        _2704 = _2660.z > 1.0;\n    }\n    else\n    {\n        _2704 = _2697;\n    }\n    if (_2704)\n    {\n        return -1.0;\n    }\n    float _2712;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2712 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2712 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2660.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2660.z - ((_2712 * (1.0 + (0.5 * _2630))) / _2611);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2611;\n    float param_5 = _2611 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2630, 3.0)) * 0.5) / _2611;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3090 = int(fa_shadows[25].x + 0.5);\n    if (_3090 < 1)\n    {\n        return 1.0;\n    }\n    float _3105 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3090 - 1;\n    if (_3105 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3117 = _3090 > 1;\n    bool _3124;\n    if (_3117)\n    {\n        _3124 = _3105 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3124 = _3117;\n    }\n    if (_3124)\n    {\n        ci = 1;\n    }\n    bool _3128 = _3090 > 2;\n    bool _3135;\n    if (_3128)\n    {\n        _3135 = _3105 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3135 = _3128;\n    }\n    if (_3135)\n    {\n        ci = 2;\n    }\n    bool _3139 = _3090 > 3;\n    bool _3146;\n    if (_3139)\n    {\n        _3146 = _3105 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3146 = _3139;\n    }\n    if (_3146)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3157 = min(_3090, 4);\n    float _3198;\n    for (int c = ci; c < _3157; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3177 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3177;\n            break;\n        }\n        if (_3177 < 0.0)\n        {\n            continue;\n        }\n        s = _3177;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3198 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3198 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3217 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3198, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3105 - (fa_shadow_split_at(param_7) - _3217)) / _3217, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3249;\n        if ((ci + 1) < _3090)\n        {\n            _3249 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3249 = 1.0;\n        }\n        s = mix(s, _3249, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3354 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3360;\n    if (_3354)\n    {\n        _3360 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3360 = _3354;\n    }\n    if (_3360)\n    {\n        float _3374 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3377 = fwidth(_3374);\n        vec4 _3387 = vec4(fa_world_pos, 1.0);\n        float _3393 = dot(fa_mesh_fs_params[28], _3387);\n        if (_3393 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3412 = vec2(dot(fa_mesh_fs_params[26], _3387), dot(fa_mesh_fs_params[27], _3387)) / vec2(_3393);\n            float _3417 = (_3412.x * 0.5) + 0.5;\n            float _3421;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3421 = (_3412.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3421 = 0.5 - (_3412.y * 0.5);\n            }\n            bool _3437 = _3417 >= 0.0;\n            bool _3443;\n            if (_3437)\n            {\n                _3443 = _3417 < 1.0;\n            }\n            else\n            {\n                _3443 = _3437;\n            }\n            bool _3449;\n            if (_3443)\n            {\n                _3449 = _3421 >= 0.0;\n            }\n            else\n            {\n                _3449 = _3443;\n            }\n            bool _3455;\n            if (_3449)\n            {\n                _3455 = _3421 < 1.0;\n            }\n            else\n            {\n                _3455 = _3449;\n            }\n            if (_3455)\n            {\n                vec4 _3481 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3417, _3421) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3484 = _3481.w > 0.5;\n                bool _3500;\n                if (_3484)\n                {\n                    _3500 = abs(_3374 - _3481.x) <= (((0.00200000009499490261077880859375 * _3374) + 0.00999999977648258209228515625) + min(1.5 * _3377, 0.100000001490116119384765625 * _3374));\n                }\n                else\n                {\n                    _3500 = _3484;\n                }\n                if (_3500)\n                {\n                    float _3506;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3506 = min(_3481.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3506 = _3481.y;\n                    }\n                    return _3506;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2770 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2777;\n    if (!_2770)\n    {\n        _2777 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2777 = _2770;\n    }\n    if (_2777)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2790 = fa_light_texel(param);\n    float _2791 = _2790.x;\n    if (_2791 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2800 = int(_2791 + 0.5);\n    int param_1 = _2800;\n    vec4 _2804 = fa_light_texel(param_1);\n    int param_2 = _2800 + 1;\n    vec4 _2809 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2812 = _2804.y;\n    if (_2812 > 0.0)\n    {\n        float _2829 = 1.0 - smoothstep(0.75 * _2812, _2812, length(world - fa_shadows[27].xyz));\n        fade = _2829;\n        if (_2829 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2804.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2853 = (_2800 + 2) + (face * 6);\n    int param_4 = _2853;\n    int param_5 = _2853 + 1;\n    int param_6 = _2853 + 3;\n    vec4 _2867 = fa_light_texel(param_6);\n    int param_7 = _2853 + 4;\n    vec4 _2872 = fa_light_texel(param_7);\n    int param_8 = _2853 + 5;\n    vec4 _2877 = fa_light_texel(param_8);\n    float _2889 = _2877.x * max(dot(_2867, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2894 = clamp(dot(n, l), 0.0, 1.0);\n    float _2917 = clamp(dot(n, _2867.xyz), -1.0, 1.0);\n    float _2936 = min(sqrt(1.0 - (_2917 * _2917)) / max(abs(dot(n, world - lpos)) / max(dot(_2867, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2939 = _2809.y;\n    float _2941;\n    if (_2939 > 0.0)\n    {\n        _2941 = _2939;\n    }\n    else\n    {\n        _2941 = 1.5 * _2889;\n    }\n    vec4 _2961 = vec4(world + (n * (_2941 * sqrt(1.0 - (_2894 * _2894)))), 1.0);\n    float _2965 = dot(_2867, _2961);\n    float _2968 = _2877.y;\n    if (_2965 < _2968)\n    {\n        return 1.0;\n    }\n    vec2 _2983 = vec2(dot(fa_light_texel(param_4), _2961), dot(fa_light_texel(param_5), _2961)) / vec2(_2965);\n    float _2985 = _2983.x;\n    bool _2988 = _2985 < _2872.x;\n    bool _2997;\n    if (!_2988)\n    {\n        _2997 = _2985 > _2872.z;\n    }\n    else\n    {\n        _2997 = _2988;\n    }\n    bool _3006;\n    if (!_2997)\n    {\n        _3006 = _2983.y < _2872.y;\n    }\n    else\n    {\n        _3006 = _2997;\n    }\n    bool _3015;\n    if (!_3006)\n    {\n        _3015 = _2983.y > _2872.w;\n    }\n    else\n    {\n        _3015 = _3006;\n    }\n    if (_3015)\n    {\n        return 1.0;\n    }\n    float _3021 = _2809.x;\n    float _3023;\n    if (_3021 > 0.0)\n    {\n        _3023 = _3021;\n    }\n    else\n    {\n        _3023 = 1.5 * _2889;\n    }\n    vec2 param_9 = _2983;\n    vec4 param_10 = _2872;\n    float param_11 = _2965 - (_3023 * (1.0 + (0.5 * _2936)));\n    float param_12 = _2889;\n    float param_13 = 1.0;\n    float param_14 = _2877.z * 0.25;\n    float param_15 = (_2889 * min(_2936, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2968, _2877.z);\n    int param_17 = int(_2804.z + 0.5);\n    float param_18 = _2804.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5349 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5356;\n    if (!_5349)\n    {\n        _5356 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5356 = _5349;\n    }\n    if (_5356)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5369 = fa_light_texel(param);\n    float _5370 = _5369.y;\n    float len = _5370;\n    if (_5370 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5382 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5391 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5382);\n    if (_5391 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5397 = len;\n    float _5400 = min(_5397, 0.89999997615814208984375 * dist);\n    len = _5400;\n    float _5405 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5382);\n    float _5410 = _5405 + (0.5 * _5400);\n    vec3 _5416 = world + (gn * _5405);\n    float _5418 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5479;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5433 = (float(k) + _5418) * 0.083333335816860198974609375;\n        vec3 _5441 = _5416 + (l * (_5433 * len));\n        vec4 _5447 = vec4(_5441, 1.0);\n        float _5452 = dot(fa_mesh_fs_params[28], _5447);\n        if (_5452 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5470 = vec2(dot(fa_mesh_fs_params[26], _5447), dot(fa_mesh_fs_params[27], _5447)) / vec2(_5452);\n        float _5474 = _5470.x * 0.5;\n        float _5475 = _5474 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5479 = (_5470.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5479 = 0.5 - (_5470.y * 0.5);\n        }\n        bool _5495 = _5475 < 0.0;\n        bool _5502;\n        if (!_5495)\n        {\n            _5502 = _5475 >= 1.0;\n        }\n        else\n        {\n            _5502 = _5495;\n        }\n        bool _5509;\n        if (!_5502)\n        {\n            _5509 = _5479 < 0.0;\n        }\n        else\n        {\n            _5509 = _5502;\n        }\n        bool _5516;\n        if (!_5509)\n        {\n            _5516 = _5479 >= 1.0;\n        }\n        else\n        {\n            _5516 = _5509;\n        }\n        if (_5516)\n        {\n            break;\n        }\n        vec4 _5540 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5475, _5479) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5540.w < 0.5)\n        {\n            continue;\n        }\n        float _5558 = (dot(fa_mesh_fs_params[29].xyz, _5441) + fa_mesh_fs_params[29].w) - _5540.x;\n        if ((_5558 > _5405) && (_5558 < _5410))\n        {\n            occ = max(occ, (1.0 - (_5433 * _5433)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5475, 0.5 - _5474), min(_5479, 1.0 - _5479))));\n        }\n    }\n    return 1.0 - (occ * _5391);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6024 = fa_baked_keep(param);\n    if (_6024 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6050 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9253 = _6050.color;\n    float _9254 = _6050.attenuation;\n    float _9255 = _6050.shadow;\n    bool _6053 = _6050.type == 0;\n    if (_6053 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6050.direction;\n        float _6064 = fa_shadow_factor(param_5, param_6);\n        _9255 = _6064;\n        _9253 *= _6064;\n    }\n    else\n    {\n        bool _6075 = _6050.type != 0;\n        bool _6081;\n        if (_6075)\n        {\n            _6081 = _9254 > 0.0;\n        }\n        else\n        {\n            _6081 = _6075;\n        }\n        if (_6081)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6050.direction;\n            float _6100 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9255 = _6100;\n            _9253 *= _6100;\n        }\n    }\n    bool _6110 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6116;\n    if (_6110)\n    {\n        _6116 = _9254 > 0.0;\n    }\n    else\n    {\n        _6116 = _6110;\n    }\n    if (_6116)\n    {\n        float _6123;\n        if (_6053)\n        {\n            _6123 = 1000000000.0;\n        }\n        else\n        {\n            _6123 = _6050._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6050.direction;\n        float param_18 = _6123;\n        float _6141 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9255 *= _6141;\n        _9253 *= _6141;\n    }\n    float _6154 = _9254;\n    float _6155 = _6154 * _6024;\n    _9254 = _6155;\n    vec3 _6159 = _9253;\n    vec3 _6160 = _6159 * _6024;\n    _9253 = _6160;\n    return LightSample(_6050.direction, _6160, _6155, _9255, _6050._distance, _6050.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6194 = v - (n * dot(v, n));\n    vec3 t = _6194;\n    float _6198 = dot(_6194, _6194);\n    float l2 = _6198;\n    if (_6198 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6208;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6208 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6208 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6208;\n        l2 = dot(_6208, _6208);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6595;\n    if ((j == 0) || (j == 7))\n    {\n        _6595 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6605;\n        if ((j == 3) || (j == 4))\n        {\n            _6605 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6605 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6595 = _6605;\n    }\n    float _6626;\n    if ((j == 1) || (j == 2))\n    {\n        _6626 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6635;\n        if ((j == 5) || (j == 6))\n        {\n            _6635 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6635 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6626 = _6635;\n    }\n    return (pc + (ex * _6595)) + (ey * _6626);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6243 = dot(a, a);\n    float _6247 = dot(b, b);\n    if ((_6243 < 1.0000000195414813782625560981111e-24) || (_6247 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6261 = a * inversesqrt(_6243);\n    vec3 _6266 = b * inversesqrt(_6247);\n    float _6270 = dot(_6261, _6266);\n    float _6273 = abs(_6270);\n    float g = (((((((((((0.0416471660137176513671875 * _6273) - 0.1924748718738555908203125) * _6273) + 0.4179156124591827392578125) * _6273) - 0.616057217121124267578125) * _6273) + 0.777722418308258056640625) * _6273) - 0.999542415142059326171875) * _6273) + 1.570791721343994140625;\n    if (_6270 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6270 * _6270), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6261, _6266) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6330 = a.z > 0.0;\n    bool _6334 = b.z > 0.0;\n    if (_6330 && _6334)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6330 != _6334)\n        {\n            vec3 _6369 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6369.z = 0.0;\n            if (_6330)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6369;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6369;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6369;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6369;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6418 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6444 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6470 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6496 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6418;\n    vec3 param_1 = _6444;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6444;\n    vec3 param_7 = _6470;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6470;\n    vec3 param_13 = _6496;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6496;\n    vec3 param_19 = _6418;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6664 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6682;\n    for (int k = 0; k < (2 * _6664); k++)\n    {\n        bool _6679 = k >= _6664;\n        if (_6679)\n        {\n            _6682 = k - _6664;\n        }\n        else\n        {\n            _6682 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6664 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6728 = 2 * _6682;\n            int param_4 = _6728 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6728 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6728 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6765 = bvec4(_6679);\n        vec4 param_16 = vec4(_6765.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6765.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6765.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6765.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6776 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6679)\n        {\n            vec2 _9491 = sum;\n            _9491.y = _9491.y + _6776;\n            sum = _9491;\n        }\n        else\n        {\n            vec2 _9494 = sum;\n            _9494.x = _9494.x + _6776;\n            sum = _9494;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6800 = fa_light_base(param);\n    int param_1 = _6800;\n    int param_2 = _6800 + 1;\n    int param_3 = _6800 + 2;\n    int param_4 = _6800 + 4;\n    vec4 _6822 = fa_light_texel(param_4);\n    int param_5 = _6800 + 5;\n    vec4 _6827 = fa_light_texel(param_5);\n    int param_6 = _6800 + 6;\n    vec4 _6832 = fa_light_texel(param_6);\n    float _6833 = _6832.w;\n    vec3 _6838 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6840 = _6833 < 1.5;\n    bool _6847;\n    if (_6840)\n    {\n        _6847 = dot(normalize(fa_light_texel(param_3).xyz), _6838) >= 0.0;\n    }\n    else\n    {\n        _6847 = _6840;\n    }\n    if (_6847)\n    {\n        return vec3(0.0);\n    }\n    bool _6856 = (_6833 > 0.5) && _6840;\n    float _6860 = _6856 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6863 = _6822.xyz;\n    float _6865 = _6822.w;\n    vec3 _6871 = _6827.xyz;\n    float _6873 = _6827.w;\n    vec3 up = _6871 * (_6873 * _6860);\n    float _6879;\n    if (_6856)\n    {\n        _6879 = (3.1415927410125732421875 * _6865) * _6865;\n    }\n    else\n    {\n        _6879 = (4.0 * _6865) * _6873;\n    }\n    if (_6833 > 1.5)\n    {\n        vec3 _6905 = cross(_6863, -_6838);\n        vec3 perp = _6905;\n        float _6909 = dot(_6905, _6905);\n        vec3 _6912;\n        if (_6909 > 1.0000000133514319600180897396058e-10)\n        {\n            _6912 = perp * inversesqrt(_6909);\n        }\n        else\n        {\n            _6912 = _6871;\n        }\n        perp = _6912;\n        up = _6912 * _6873;\n    }\n    float _6933 = max(_6879, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6943 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6943;\n    vec3 param_10 = n;\n    vec3 param_11 = _6838;\n    vec3 param_12 = _6943;\n    vec3 param_13 = n;\n    vec3 param_14 = _6863 * (_6865 * _6860);\n    vec3 param_15 = _6943;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6974 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6974;\n    vec2 param_21 = _6974 + vec2(64.0, 0.0);\n    vec4 _6984 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6833;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6996 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6996.x) + (((f0 * _6984.x) + ((vec3(f90) - f0) * _6984.y)) * _6996.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6838, _6838)) + _6933) / _6933) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5086 = 1.0 / alpha;\n    return ((2.0 + _5086) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5086)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5121 = max(dot(L.nc, l), 0.0);\n    float _5127 = max(dot(L.nc, h), 0.0);\n    float _5136 = ((_5127 * _5127) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5136) * _5136)) * (0.5 / max(mix((2.0 * _5121) * L.coat_ndv, _5121 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5121)) * _5121;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7033;\n    if (L.sheen_on)\n    {\n        _7033 = L.sheen_scale;\n    }\n    else\n    {\n        _7033 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7033);\n    vec3 _7046 = normalize(l + v);\n    int param = li;\n    vec3 _7057 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7066 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7046), 0.0);\n        float param_3 = _7066;\n        float param_4 = ndv;\n        result += ((L.sheen * _7057) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7066)) * _7066) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7046;\n        float param_8 = max(dot(v, _7046), 0.0);\n        result += (_7057 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4989 = tdh / at;\n    float _4993 = bdh / ab;\n    float _5005 = ((_4989 * _4989) + (_4993 * _4993)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5005) * _5005);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5185 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5264 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5264) * _5264);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5185);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5185));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4388 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4391 = _4388.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4391 * _4391, exp2((-9.27999973297119140625) * ndv)) * _4391) + _4388.y)) + _4388.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3697;\n    if (lv == 0)\n    {\n        _3697 = 0.0;\n    }\n    else\n    {\n        _3697 = res + 2.0;\n    }\n    float _3707;\n    if (lv == 0)\n    {\n        _3707 = 0.0;\n    }\n    else\n    {\n        _3707 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3697, _3707)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3753;\n    if (res > 64.5)\n    {\n        _3753 = 5.0;\n    }\n    else\n    {\n        _3753 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3768 = clamp(rough, 0.0, 1.0) * (_3753 - 1.0);\n    int _3775 = int(min(floor(_3768), _3753 - 2.0));\n    float _3780 = _3768 - float(_3775);\n    vec3 param = d;\n    vec2 _3784 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3775;\n    vec2 param_4 = _3784;\n    vec3 _3794 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3780 < 0.00200000009499490261077880859375)\n    {\n        return _3794;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3775 + 1;\n    vec2 param_8 = _3784;\n    return mix(_3794, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3780));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3866 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3873 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3880 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3886 = dot(bx.xyz, d);\n    float _3890 = dot(by.xyz, d);\n    float _3894 = dot(bz.xyz, d);\n    float _3900;\n    if (_3886 > 9.9999999747524270787835121154785e-07)\n    {\n        _3900 = (1.0 - _3866) / _3886;\n    }\n    else\n    {\n        float _3914;\n        if (_3886 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3914 = ((-1.0) - _3866) / _3886;\n        }\n        else\n        {\n            _3914 = 1000000015047466219876688855040.0;\n        }\n        _3900 = _3914;\n    }\n    float tx = _3900;\n    float _3931;\n    if (_3890 > 9.9999999747524270787835121154785e-07)\n    {\n        _3931 = (1.0 - _3873) / _3890;\n    }\n    else\n    {\n        float _3944;\n        if (_3890 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3944 = ((-1.0) - _3873) / _3890;\n        }\n        else\n        {\n            _3944 = 1000000015047466219876688855040.0;\n        }\n        _3931 = _3944;\n    }\n    float ty = _3931;\n    float _3960;\n    if (_3894 > 9.9999999747524270787835121154785e-07)\n    {\n        _3960 = (1.0 - _3880) / _3894;\n    }\n    else\n    {\n        float _3973;\n        if (_3894 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3973 = ((-1.0) - _3880) / _3894;\n        }\n        else\n        {\n            _3973 = 1000000015047466219876688855040.0;\n        }\n        _3960 = _3973;\n    }\n    float _3985 = tx;\n    float _3988 = (_3985 > 0.0) ? _3985 : 1000000015047466219876688855040.0;\n    tx = _3988;\n    float _3989 = ty;\n    float _3992 = (_3989 > 0.0) ? _3989 : 1000000015047466219876688855040.0;\n    ty = _3992;\n    float _4002 = min(_3988, min(_3992, (_3960 > 0.0) ? _3960 : 1000000015047466219876688855040.0));\n    if (_4002 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4018 = (fa_world_pos + (d * _4002)) - posw.xyz;\n    vec3 _4023;\n    if (dot(_4018, _4018) > 1.0000000133514319600180897396058e-10)\n    {\n        _4023 = normalize(_4018);\n    }\n    else\n    {\n        _4023 = d;\n    }\n    return _4023;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4069 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4069 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4097 = rough * rough;\n            float _4128 = 0.60000002384185791015625 * _4097;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4097)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4128, 0.0500000007450580596923828125 + _4128, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4097 * 0.60000002384185791015625));\n        }\n        outc = base * _4069;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4187 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4187 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4219 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4219 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4866;\n        if (L.aniso >= 0.0)\n        {\n            _4866 = L.b;\n        }\n        else\n        {\n            _4866 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4866, v), _4866), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4902 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4902.x) + (vec3(L.f90) * _4902.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4960 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4960.x) + _4960.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4430 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4430.x) + vec3(_4430.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5662 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5666 = fa_xm_origin(param_1);\n    vec2 _5672 = (uv * _5662) - vec2(0.5);\n    vec2 _5675 = fract(_5672);\n    vec2 _5678 = floor(_5672);\n    vec2 param_2 = _5662;\n    vec2 param_3 = _5666;\n    vec2 param_4 = _5678;\n    vec2 param_5 = _5662;\n    vec2 param_6 = _5666;\n    vec2 param_7 = _5678 + vec2(1.0, 0.0);\n    vec2 param_8 = _5662;\n    vec2 param_9 = _5666;\n    vec2 param_10 = _5678 + vec2(0.0, 1.0);\n    vec2 param_11 = _5662;\n    vec2 param_12 = _5666;\n    vec2 param_13 = _5678 + vec2(1.0);\n    vec3 _5720 = vec3(_5675.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5720), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5720), vec3(_5675.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5739 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5743 = clamp(lod, 0.0, _5739);\n    int _5747 = int(floor(_5743));\n    int param = _5747;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5757 = float(_5747);\n    float _5758 = _5743 - _5757;\n    bool _5760 = _5758 > 0.001000000047497451305389404296875;\n    bool _5767;\n    if (_5760)\n    {\n        _5767 = _5757 < _5739;\n    }\n    else\n    {\n        _5767 = _5760;\n    }\n    if (_5767)\n    {\n        int param_2 = _5747 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5758));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5793 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5793.x) + (vec3(f90) * _5793.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5821 = max(s.thickness, 0.0);\n    bool _5826 = _5821 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5826)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5821);\n    }\n    bool _5851 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5858;\n    if (!_5851)\n    {\n        _5858 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5858 = _5851;\n    }\n    if (_5858)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5826)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5821);\n    }\n    vec4 _5893 = vec4(world, 1.0);\n    float _5898 = dot(fa_mesh_fs_params[28], _5893);\n    vec2 uv = vec2(0.5);\n    if (_5898 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5916 = vec2(dot(fa_mesh_fs_params[26], _5893), dot(fa_mesh_fs_params[27], _5893)) / vec2(_5898);\n        float _5924;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5924 = (_5916.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5924 = 0.5 - (_5916.y * 0.5);\n        }\n        uv = vec2((_5916.x * 0.5) + 0.5, _5924);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3277 = int(fa_shadows[25].x + 0.5);\n    float _3287 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3292 = _3277 > 0;\n    bool _3301;\n    if (_3292)\n    {\n        int param = _3277 - 1;\n        _3301 = _3287 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3301 = _3292;\n    }\n    if (_3301)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3307 = _3277 > 1;\n        bool _3314;\n        if (_3307)\n        {\n            _3314 = _3287 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3314 = _3307;\n        }\n        if (_3314)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3320 = _3277 > 2;\n        bool _3327;\n        if (_3320)\n        {\n            _3327 = _3287 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3327 = _3320;\n        }\n        if (_3327)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3333 = _3277 > 3;\n        bool _3340;\n        if (_3333)\n        {\n            _3340 = _3287 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3340 = _3333;\n        }\n        if (_3340)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8912 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8912 = -_8912;\n    }\n    vec3 _8210 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8912, fa_world_tangent, fa_uv, fa_vertex_color, _8210, gl_FrontFacing);\n    Surface _8218 = fa_standard_surface(param_1);\n    vec3 _8943 = _8218.albedo;\n    float _8944 = _8218.alpha;\n    vec3 _8945 = _8218.normal;\n    float _8946 = _8218.metallic;\n    float _8947 = _8218.roughness;\n    float _8948 = _8218.occlusion;\n    vec3 _8949 = _8218.emission;\n    float _8950 = _8218.clearcoat;\n    float _8951 = _8218.clearcoat_roughness;\n    vec3 _8952 = _8218.sheen_color;\n    float _8953 = _8218.sheen_roughness;\n    float _8954 = _8218.anisotropy;\n    float _8955 = _8218.anisotropy_rotation;\n    float _8956 = _8218.specular;\n    float _8957 = _8218.ior;\n    vec3 _8958 = _8218.specular_color;\n    float _8959 = _8218.transmission;\n    float _8960 = _8218.thickness;\n    vec3 _8961 = _8218.attenuation_color;\n    float _8962 = _8218.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8912, fa_world_tangent, fa_uv, fa_vertex_color, _8210, gl_FrontFacing);\n    Surface param_3 = _8218;\n    surface(param_2, param_3);\n    _8943 = param_3.albedo;\n    _8944 = param_3.alpha;\n    _8945 = param_3.normal;\n    _8946 = param_3.metallic;\n    _8947 = param_3.roughness;\n    _8948 = param_3.occlusion;\n    _8949 = param_3.emission;\n    _8950 = param_3.clearcoat;\n    _8951 = param_3.clearcoat_roughness;\n    _8952 = param_3.sheen_color;\n    _8953 = param_3.sheen_roughness;\n    _8954 = param_3.anisotropy;\n    _8955 = param_3.anisotropy_rotation;\n    _8956 = param_3.specular;\n    _8957 = param_3.ior;\n    _8958 = param_3.specular_color;\n    _8959 = param_3.transmission;\n    _8960 = param_3.thickness;\n    _8961 = param_3.attenuation_color;\n    _8962 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8912;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8943 = param_6;\n    _8945 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8943;\n    }\n    else\n    {\n        vec3 _8258 = normalize(_8945);\n        float _8265 = clamp(_8946, 0.0, 1.0);\n        float _8269 = clamp(_8947, 0.0500000007450580596923828125, 1.0);\n        float _8273 = _8269 * _8269;\n        float _8277 = _8273 * _8273;\n        float _8282 = max(dot(_8258, _8210), 9.9999997473787516355514526367188e-05);\n        float _8288 = 1.0 - _8265;\n        float _8289 = clamp(_8959, 0.0, 1.0) * _8288;\n        vec3 _8298 = (_8943 * _8288) * (1.0 - _8289);\n        vec3 _8305 = mix(vec3(0.039999999105930328369140625), _8943, vec3(_8265));\n        vec3 f0 = _8305;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8912, fa_world_tangent, fa_uv, fa_vertex_color, _8210, gl_FrontFacing);\n        Surface param_9 = Surface(_8943, _8944, _8945, _8946, _8947, _8948, _8949, _8950, _8951, _8952, _8953, _8954, _8955, _8956, _8957, _8958, _8959, _8960, _8961, _8962);\n        vec3 param_10 = _8258;\n        vec3 param_11 = _8210;\n        float param_12 = _8265;\n        float param_13 = _8269;\n        vec3 param_14 = _8305;\n        FaLayers _8321 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8258;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8298) * _8948;\n        if (_8321.on)\n        {\n            lit *= _8321.base_scale;\n        }\n        int _8343 = fa_cl_ndir + fa_cl_local;\n        float _8408;\n        for (int ln = 0; ln < _8343; ln++)\n        {\n            int param_16 = ln;\n            int _8356 = fa_cl_light(param_16);\n            int param_17 = _8356;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8356;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8912;\n            LightSample _8372 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8380 = max(dot(_8258, _8372.direction), 0.0);\n            float _8386 = _8372.attenuation * _8372.shadow;\n            vec3 _8391 = normalize(_8372.direction + _8210);\n            float _8396 = max(dot(_8258, _8391), 0.0);\n            float _8401 = max(dot(_8210, _8391), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8321.on)\n                {\n                    _8408 = _8321.f90;\n                }\n                else\n                {\n                    _8408 = 1.0;\n                }\n                int param_21 = _8356;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8258;\n                vec3 param_24 = _8210;\n                vec3 param_25 = _8298;\n                vec3 param_26 = f0;\n                float param_27 = _8408;\n                float param_28 = _8269;\n                float param_29 = _8282;\n                float param_30 = _8386;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8321.on)\n                {\n                    FaLayers param_31 = _8321;\n                    vec3 param_32 = area;\n                    int param_33 = _8356;\n                    vec3 param_34 = _8258;\n                    vec3 param_35 = _8210;\n                    vec3 param_36 = _8372.direction;\n                    float param_37 = _8282;\n                    float param_38 = _8386;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8321.on)\n                {\n                    FaLayers param_39 = _8321;\n                    vec3 param_40 = _8298;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8258;\n                    vec3 param_43 = _8210;\n                    vec3 param_44 = _8372.direction;\n                    vec3 param_45 = _8391;\n                    float param_46 = _8380;\n                    float param_47 = _8282;\n                    float param_48 = _8396;\n                    float param_49 = _8401;\n                    float param_50 = _8273;\n                    float param_51 = _8277;\n                    int param_52 = _8356;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8386));\n                }\n                else\n                {\n                    float _8510 = ((_8396 * _8396) * (_8277 - 1.0)) + 1.0;\n                    int param_53 = _8356;\n                    lit += (((_8298 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8401, 5.0))) * (((_8277 / ((3.1415927410125732421875 * _8510) * _8510)) * (0.5 / max(mix((2.0 * _8380) * _8282, _8380 + _8282, _8273), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8380))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8380 * _8386));\n                }\n            }\n        }\n        if (_8321.on)\n        {\n            FaLayers param_54 = _8321;\n            vec3 param_55 = _8258;\n            vec3 param_56 = _8210;\n            vec3 param_57 = f0;\n            float param_58 = _8269;\n            float param_59 = _8948;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8258;\n            vec3 param_61 = _8210;\n            vec3 param_62 = f0;\n            float param_63 = _8269;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8948);\n        }\n        if (_8289 > 0.0)\n        {\n            float _8608;\n            if (_8321.on)\n            {\n                _8608 = _8321.f90;\n            }\n            else\n            {\n                _8608 = 1.0;\n            }\n            float _8616;\n            if (_8321.on)\n            {\n                _8616 = _8321.base_scale;\n            }\n            else\n            {\n                _8616 = 1.0;\n            }\n            Surface param_64 = Surface(_8943, _8944, _8945, _8946, _8947, _8948, _8949, _8950, _8951, _8952, _8953, _8954, _8955, _8956, _8957, _8958, _8959, _8960, _8961, _8962);\n            vec3 param_65 = _8258;\n            vec3 param_66 = _8210;\n            float param_67 = _8269;\n            vec3 param_68 = f0;\n            float param_69 = _8608;\n            float param_70 = _8616;\n            float param_71 = _8289;\n            float param_72 = fa_tr_blend;\n            vec3 _8640 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8640;\n        }\n        result = lit;\n    }\n    vec3 _8647 = result;\n    vec3 _8648 = _8647 + _8949;\n    result = _8648;\n    vec3 param_73 = _8648;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8657 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8664;\n    if (!_8657)\n    {\n        _8664 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8664 = _8657;\n    }\n    if (_8664)\n    {\n        vec3 _8673 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8679 = dot(_8673, fa_mesh_fs_params[9].xyz);\n        bool _8683 = fa_mesh_fs_params[9].w > 0.5;\n        float _8684;\n        if (_8683)\n        {\n            _8684 = _8679;\n        }\n        else\n        {\n            _8684 = length(_8673);\n        }\n        float _8696 = _8684 - fa_mesh_fs_params[8].x;\n        if (_8696 > 0.0)\n        {\n            float _8705 = fa_mesh_fs_params[7].w * _8696;\n            float tau = _8705 * _8705;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8721;\n                if (_8683)\n                {\n                    _8721 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8679);\n                }\n                else\n                {\n                    _8721 = fa_mesh_fs_params[0].y;\n                }\n                float _8742 = mix(_8721, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8684, 0.0, 1.0));\n                float _8746 = fa_world_pos.y - _8742;\n                float _8751 = _8742 - fa_mesh_fs_params[8].z;\n                float _8756 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8759 = _8751 <= 0.0;\n                bool _8760 = !_8759;\n                bool _8766;\n                if (_8760)\n                {\n                    _8766 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8766 = _8759;\n                }\n                float _8767;\n                if (_8766)\n                {\n                    _8767 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8767 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8751, 80.0));\n                }\n                bool _8794;\n                if (_8760)\n                {\n                    _8794 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8794 = _8759;\n                }\n                float _8795;\n                if (_8794)\n                {\n                    _8795 = fa_mesh_fs_params[8].y * _8751;\n                }\n                else\n                {\n                    _8795 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8751, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8820 = _8756 <= 0.0;\n                bool _8827;\n                if (!_8820)\n                {\n                    _8827 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8827 = _8820;\n                }\n                float _8828;\n                if (_8827)\n                {\n                    _8828 = fa_mesh_fs_params[8].y * _8756;\n                }\n                else\n                {\n                    _8828 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8756, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8855;\n                if (abs(_8746) < 0.001000000047497451305389404296875)\n                {\n                    _8855 = _8767;\n                }\n                else\n                {\n                    _8855 = (_8828 - _8795) / _8746;\n                }\n                tau += (_8696 * max(_8855, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8891 = 1.0 - fa_tr_blend;\n        result /= vec3(_8891);\n        _8944 *= _8891;\n    }\n    fa_frag_color = vec4(result, _8944);\n}\n\n",
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
            "inst_name": "_7135",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4531[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1594 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1601;\n    if (!_1594)\n    {\n        _1601 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1601 = _1594;\n    }\n    bool _1609;\n    if (!_1601)\n    {\n        _1609 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1609 = _1601;\n    }\n    bool _1616;\n    if (!_1609)\n    {\n        _1616 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1616 = _1609;\n    }\n    bool _1623;\n    if (!_1616)\n    {\n        _1623 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1623 = _1616;\n    }\n    if (_1623)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1633 = vec4(world_pos, 1.0);\n    float _1639 = dot(fa_mesh_fs_params[16], _1633);\n    if (!(_1639 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1661 = vec2(dot(fa_mesh_fs_params[14], _1633), dot(fa_mesh_fs_params[15], _1633)) / vec2(_1639);\n    int _1665 = int(fa_mesh_fs_params[18].x);\n    int _1669 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1669) + clamp(int(floor(((_1661.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1669 - 1)) * _1665)) + clamp(int(floor(((_1661.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1665 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1745 = fa_cluster_texel(param);\n    return ivec2(int(_1745.x), int(_1745.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5998 = fa_cluster_lookup(param);\n    fa_cl_slot = _5998.x;\n    fa_cl_local = _5998.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7187 = fa_linear_to_srgb(param);\n        c = _7187;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7195 = fa_srgb_to_linear(param_1);\n            c = _7195;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _538;\n    if (i.front_facing)\n    {\n        _538 = i.world_normal;\n    }\n    else\n    {\n        _538 = -i.world_normal;\n    }\n    vec3 _562 = normalize(i.world_tangent.xyz - (_538 * dot(_538, i.world_tangent.xyz)));\n    vec3 _589 = normalize(((_562 * m.x) + ((cross(_538, _562) * i.world_tangent.w) * m.y)) + (_538 * m.z));\n    vec3 _592;\n    if (i.front_facing)\n    {\n        _592 = _589;\n    }\n    else\n    {\n        _592 = -_589;\n    }\n    return _592;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7227 = fa_tex_fix(param_2, param_3);\n    vec4 _9508 = base_t;\n    _9508.x = _7227.x;\n    _9508.y = _7227.y;\n    _9508.z = _7227.z;\n    base_t = _9508;\n    vec4 _7241 = (_9508 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9273 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7275 = fa_tex_fix(param_6, param_7);\n        vec3 _7278 = (_7275 * 2.0) - vec3(1.0);\n        vec2 _7283 = _7278.xy * fa_mesh_fs_params[6].x;\n        vec3 _9516 = _7278;\n        _9516.x = _7283.x;\n        _9516.y = _7283.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9516;\n        _9273 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7313 = fa_tex_fix(param_12, param_13);\n    vec4 _9519 = mrt;\n    _9519.x = _7313.x;\n    _9519.y = _7313.y;\n    _9519.z = _7313.z;\n    mrt = _9519;\n    vec4 _7343 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7386 = fa_tex_fix(param_20, param_21);\n    float _9278 = fa_mesh_fs_params[20].x;\n    float _9279 = fa_mesh_fs_params[20].y;\n    float _9282 = fa_mesh_fs_params[20].z;\n    float _9281 = fa_mesh_fs_params[21].w;\n    float _9284 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9278 *= _7354.y;\n            _9279 *= _7354.z;\n            _9281 *= _7343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9282 *= mrt.x;\n            _9284 *= mrt.w;\n        }\n    }\n    return Surface(_7241.xyz, _7241.w, _9273, clamp(fa_mesh_fs_params[5].x * _7313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7386), _9278, _9279, fa_mesh_fs_params[21].xyz, _9281, _9282, fa_mesh_fs_params[20].w, _9284, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1825 = rect.zw - rect.xy;\n    vec2 _1829 = _1825 * atlas;\n    vec2 _1833 = ddx * _1829;\n    vec2 _1837 = ddy * _1829;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1825), clamp(0.5 * log2(max(max(dot(_1833, _1833), dot(_1837, _1837)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1870 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1877;\n    if (!_1870)\n    {\n        _1877 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1877 = _1870;\n    }\n    if (_1877)\n    {\n        return;\n    }\n    vec3 _1883 = dFdx(world_pos);\n    vec3 _1886 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1890 = fa_cluster_texel(param);\n    int _1894 = int(_1890.w);\n    if (_1894 < 1)\n    {\n        return;\n    }\n    int _1904 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1904;\n    vec4 _1908 = fa_light_texel(param_1);\n    vec2 _1911 = _1908.yz;\n    int _1915 = int(_1908.w);\n    int param_2 = _1904 + 1;\n    vec4 _1920 = fa_light_texel(param_2);\n    float _1921 = _1920.x;\n    int _1927 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1931 = int(_1890.z);\n    vec3 _2196;\n    for (int k = 0; k < _1894; k++)\n    {\n        int _1944 = _1931 + k;\n        int param_3 = _1915 + (_1944 >> 2);\n        int _1961 = (_1904 + 2) + (int(fa_light_texel(param_3)[_1944 & 3]) * 7);\n        int param_4 = _1961 + 6;\n        vec4 _1966 = fa_light_texel(param_4);\n        if (((int(_1966.w + 0.5) >> _1927) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1961;\n        vec4 _1981 = fa_light_texel(param_5);\n        int param_6 = _1961 + 1;\n        vec4 _1986 = fa_light_texel(param_6);\n        int param_7 = _1961 + 2;\n        vec4 _1991 = fa_light_texel(param_7);\n        vec3 _1994 = _1981.xyz;\n        float _1999 = dot(_1994, world_pos) + _1981.w;\n        vec3 _2001 = _1986.xyz;\n        float _2006 = dot(_2001, world_pos) + _1986.w;\n        vec3 _2008 = _1991.xyz;\n        float _2013 = dot(_2008, world_pos) + _1991.w;\n        bool _2018 = abs(_1999) > 0.5;\n        bool _2026;\n        if (!_2018)\n        {\n            _2026 = abs(_2006) > 0.5;\n        }\n        else\n        {\n            _2026 = _2018;\n        }\n        bool _2034;\n        if (!_2026)\n        {\n            _2034 = abs(_2013) > 0.5;\n        }\n        else\n        {\n            _2034 = _2026;\n        }\n        if (_2034)\n        {\n            continue;\n        }\n        float _2049 = clamp(dot(geo_normal, normalize(_2008)) * _1966.z, 0.0, 1.0);\n        if (_2049 <= 0.0)\n        {\n            continue;\n        }\n        float _2069 = (clamp((0.5 - abs(_2013)) * 10.0, 0.0, 1.0) * _2049) * _1966.x;\n        vec2 _2077 = vec2(_1999 + 0.5, 0.5 - _2006);\n        vec2 _2087 = vec2(dot(_1994, _1883), dot(_2001, _1883));\n        vec2 _2097 = vec2(dot(_1994, _1886), dot(_2001, _1886));\n        int param_8 = _1961 + 5;\n        vec4 _2102 = fa_light_texel(param_8);\n        int param_9 = _1961 + 3;\n        vec4 _2107 = fa_light_texel(param_9);\n        int param_10 = _1961 + 4;\n        vec4 _2112 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2102.xyz;\n        bool _2122 = _2107.z > _2107.x;\n        if (_2122)\n        {\n            vec4 param_11 = _2107;\n            vec2 param_12 = _2077;\n            vec2 param_13 = _1911;\n            vec2 param_14 = _2087;\n            vec2 param_15 = _2097;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1921 > 0.5) && (_1921 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2148 = fa_dc_to_linear(param_16);\n                vec4 _9361 = tx;\n                _9361.x = _2148.x;\n                _9361.y = _2148.y;\n                _9361.z = _2148.z;\n                tx = _9361;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2069 * tex_a) * _2102.w, 0.0, 1.0)));\n        if (_2112.z > _2112.x)\n        {\n            vec4 param_17 = _2112;\n            vec2 param_18 = _2077;\n            vec2 param_19 = _1911;\n            vec2 param_20 = _2087;\n            vec2 param_21 = _2097;\n            vec4 _2192 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1921 > 1.5)\n            {\n                vec3 param_22 = _2192.xyz;\n                vec3 _2202 = fa_dc_to_srgb(param_22);\n                _2196 = _2202;\n            }\n            else\n            {\n                _2196 = _2192.xyz;\n            }\n            vec3 _2211 = (_2196 * 2.0) - vec3(1.0);\n            vec2 _2216 = _2211.xy * _1966.y;\n            vec3 _2238 = (normalize(_1994) * _2216.x) + (normalize(_2001) * _2216.y);\n            vec3 _2241 = normalize(normal);\n            normal = normalize(mix(_2241, normalize((_2241 * max(_2211.z, 0.0500000007450580596923828125)) + (_2238 - (_2241 * dot(_2241, _2238)))), vec3(clamp(_2069 * (_2122 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4456 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4464 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4467 = int(_4456);\n    int _4470 = int(_4464);\n    float _4480 = _4464 - float(_4470);\n    int _4535 = (_4467 * 9) + _4470;\n    int _4555 = ((_4467 + 1) * 9) + _4470;\n    return mix(mix(_4531[_4535], _4531[_4535 + 1], _4480), mix(_4531[_4555], _4531[_4555 + 1], _4480), _4456 - float(_4467));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9196 = false;\n    float _9197 = 1.0;\n    float _9198 = 1.0;\n    float _9199 = 1.0;\n    float _9200 = 0.0;\n    float _9201 = 0.0;\n    float _9202 = 0.0;\n    float _9203 = 0.0;\n    float _9205 = 1.0;\n    bool _9206 = false;\n    vec3 _9207 = vec3(0.0);\n    float _9208 = 1.0;\n    float _9209 = 1.0;\n    float _9210 = 1.0;\n    float _9211 = 0.0;\n    float _9212 = 0.0;\n    vec3 _9213 = vec3(1.0, 0.0, 0.0);\n    vec3 _9214 = vec3(0.0, 0.0, 1.0);\n    float _9215 = 1.0;\n    float _9216 = 1.0;\n    float _4606 = clamp(s.specular, 0.0, 1.0);\n    float _4610 = clamp(s.ior, 1.0, 3.0);\n    bool _4615 = (_4606 != 1.0) || (_4610 != 1.5);\n    bool _4624;\n    if (!_4615)\n    {\n        _4624 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4624 = _4615;\n    }\n    if (_4624)\n    {\n        float _4632 = (_4610 - 1.0) / (_4610 + 1.0);\n        f0 = mix(min(vec3(_4632 * _4632) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4606, s.albedo, vec3(metallic));\n        _9197 = mix(_4606, 1.0, metallic);\n        _9196 = true;\n    }\n    float _4659 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4659 > 0.0)\n    {\n        float _4667 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9200 = _4659;\n        _9201 = _4667;\n        float _4674 = _4667 * _4667;\n        _9202 = _4674;\n        _9203 = _4674 * _4674;\n        float _4686 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9205 = _4686;\n        _9198 = 1.0 - (_4659 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4686, 0.0, 1.0), 5.0))));\n        _9196 = true;\n    }\n    vec3 _4705 = max(s.sheen_color, vec3(0.0));\n    float _4714 = max(_4705.x, max(_4705.y, _4705.z));\n    if (_4714 > 0.0)\n    {\n        float _4722 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9206 = true;\n        _9207 = _4705;\n        _9208 = _4722;\n        _9209 = _4722 * _4722;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4722;\n        float _4739 = fa_sheen_albedo(param, param_1);\n        _9211 = _4739;\n        _9210 = 1.0 - min(_4714 * _4739, 1.0);\n        _9196 = true;\n    }\n    _9199 = _9198 * _9210;\n    float _4758 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4758 != 0.0)\n    {\n        vec3 _4773 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4773;\n        if (dot(_4773, _4773) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4785 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4785.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4785.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4785.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4789 = t;\n        vec3 _4790 = normalize(_4789);\n        t = _4790;\n        vec3 _4815 = normalize((_4790 * cos(s.anisotropy_rotation)) + ((cross(n, _4790) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9213 = _4815;\n        _9214 = cross(n, _4815);\n        float _4825 = roughness * roughness;\n        float _4831 = mix(_4825, 1.0, _4758 * _4758);\n        bool _4833 = _4758 > 0.0;\n        _9215 = _4833 ? _4831 : _4825;\n        _9216 = _4833 ? _4825 : _4831;\n        _9212 = _4758;\n        _9196 = true;\n    }\n    return FaLayers(_9196, _9197, _9198, _9199, _9200, _9201, _9202, _9203, i.world_normal, _9205, _9206, _9207, _9208, _9209, _9210, _9211, _9212, _9213, _9214, _9215, _9216);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3625 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3625;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4237 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4242 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4237 > 0.0005000000237487256526947021484375)\n    {\n        if (_4242)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4237;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4237;\n        }\n    }\n    bool _4293 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4293)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4324 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4324)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4242 || _4293) || _4324)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3645 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3648 = _3645.x;\n    float _3650 = _3645.z;\n    vec2 e = vec2(_3648, _3650);\n    if (_3645.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3650)) * ((_3648 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3648)) * ((_3650 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7496 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7501 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7506 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7511 = fa_light_texel(param_3);\n    bool _7514 = _7511.z < 0.5;\n    bool _7522;\n    if (!_7514)\n    {\n        _7522 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7522 = _7514;\n    }\n    if (_7522)\n    {\n        return vec3(0.0);\n    }\n    float _7529 = max(_7496.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7532 = _7501.xyz;\n    vec3 _7536 = _7496.xyz;\n    vec3 _7540 = (fa_world_pos - _7536) / vec3(_7529);\n    vec3 _7549 = min(_7540 + vec3(0.5), (_7532 - vec3(0.5)) - _7540);\n    float _7558 = min(_7549.x, min(_7549.y, _7549.z));\n    if (!(_7558 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7573 = _7532 - vec3(1.0);\n    vec3 _7574 = clamp(_7540, vec3(0.0), _7573);\n    vec3 _7582 = min(floor(_7574), max(_7532 - vec3(2.0), vec3(0.0)));\n    vec3 _7586 = _7574 - _7582;\n    vec3 _7597 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7529));\n    int _7602 = int(_7506.y + 0.5);\n    float _7607 = 0.3257350027561187744140625 * n.y;\n    float _7611 = 0.3257350027561187744140625 * n.z;\n    float _7615 = 0.3257350027561187744140625 * n.x;\n    float _7622 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7629 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7638 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7645 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7658 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7665 = 8 + int(_7511.w);\n    float _7692;\n    float _7705;\n    float _7719;\n    for (int k = 0; k < _7665; k++)\n    {\n        float _7678 = float(k & 1);\n        float _7682 = float((k >> 1) & 1);\n        float _7686 = float((k >> 2) & 1);\n        if (_7678 > 0.5)\n        {\n            _7692 = _7586.x;\n        }\n        else\n        {\n            _7692 = 1.0 - _7586.x;\n        }\n        if (_7682 > 0.5)\n        {\n            _7705 = _7586.y;\n        }\n        else\n        {\n            _7705 = 1.0 - _7586.y;\n        }\n        if (_7686 > 0.5)\n        {\n            _7719 = _7586.z;\n        }\n        else\n        {\n            _7719 = 1.0 - _7586.z;\n        }\n        float _7729 = (_7692 * _7705) * _7719;\n        if (!(_7729 > 0.0))\n        {\n            continue;\n        }\n        vec3 _7742 = min(_7582 + vec3(_7678, _7682, _7686), _7573);\n        int _7762 = int(((_7506.x + _7742.x) + (_7501.x * (_7742.y + (_7501.y * _7742.z)))) + 0.5);\n        vec2 _7777 = vec2(float(_7762 % _7602) * 10.0, 1024.0 + (float(_7762 / _7602) * 11.0));\n        vec2 param_4 = _7777 + vec2(9.5, 10.5);\n        vec4 _7785 = fa_gi_fetch(param_4);\n        bool _7788 = _7785.y < 0.5;\n        bool _7797;\n        if (!_7788)\n        {\n            _7797 = _7785.x > _7511.y;\n        }\n        else\n        {\n            _7797 = _7788;\n        }\n        if (_7797)\n        {\n            continue;\n        }\n        vec3 _7809 = _7597 - (_7536 + (_7742 * _7529));\n        float _7812 = length(_7809);\n        vec3 _7818 = _7809 / vec3(max(_7812, 9.9999997473787516355514526367188e-05));\n        float _7828 = max(9.9999997473787516355514526367188e-05, (dot(-_7818, n) + 1.0) * 0.5);\n        float w = _7729 * (_7828 * _7828);\n        vec3 param_5 = _7818;\n        vec2 param_6 = (_7777 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _7847 = fa_gi_fetch(param_6);\n        float _7854 = _7812 / max(_7506.z, 9.9999997473787516355514526367188e-05);\n        float _7857 = _7847.x;\n        if (_7854 > _7857)\n        {\n            float _7870 = max(_7847.y - (_7857 * _7857), 0.0);\n            float _7875 = _7854 - _7857;\n            float _7884 = _7870 / max(_7870 + (_7875 * _7875), 9.9999999600419720025001879548654e-13);\n            w *= ((_7884 * _7884) * _7884);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _7777 + vec2(0.5, 10.5);\n        vec2 param_8 = _7777 + vec2(1.5, 10.5);\n        vec2 param_9 = _7777 + vec2(2.5, 10.5);\n        vec2 param_10 = _7777 + vec2(3.5, 10.5);\n        vec2 param_11 = _7777 + vec2(4.5, 10.5);\n        vec2 param_12 = _7777 + vec2(5.5, 10.5);\n        vec2 param_13 = _7777 + vec2(6.5, 10.5);\n        vec2 param_14 = _7777 + vec2(7.5, 10.5);\n        vec2 param_15 = _7777 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7607)) + (fa_gi_fetch(param_9).xyz * _7611)) + (fa_gi_fetch(param_10).xyz * _7615)) + (fa_gi_fetch(param_11).xyz * _7622)) + (fa_gi_fetch(param_12).xyz * _7629)) + (fa_gi_fetch(param_13).xyz * _7638)) + (fa_gi_fetch(param_14).xyz * _7645)) + (fa_gi_fetch(param_15).xyz * _7658)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7558 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8009;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8009 = _7511.x;\n    }\n    else\n    {\n        _8009 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7506.w * _8009);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8033 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8038 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8043 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8043) && (k < 8); k++)\n    {\n        int param = _8038 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8033;\n        vec3 _8068 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8073 = param_3 * left;\n        acc += (_8068 * _8073);\n        left -= _8073;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8102 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8102;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5968;\n    if (fa_lm.z > 0.5)\n    {\n        _5968 = 0.0;\n    }\n    else\n    {\n        _5968 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5979 = _5968 < 1.0;\n    bool _5985;\n    if (_5979)\n    {\n        int param = li;\n        _5985 = fa_light_baked(param);\n    }\n    else\n    {\n        _5985 = _5979;\n    }\n    return _5985 ? _5968 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _843 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _856 = (c - (ru * hx)) - p;\n        vec3 _862 = ru * (2.0 * hx);\n        float _868 = max(dot(_862, _862), 9.9999999392252902907785028219223e-09);\n        float _872 = dot(_856, _862);\n        float t = clamp((-_872) / _868, 0.0, 1.0);\n        if (_843)\n        {\n            float _887 = dot(r, _862);\n            float _893 = _868 - (_887 * _887);\n            if (abs(_893) > (9.9999997473787516355514526367188e-06 * _868))\n            {\n                t = clamp(((dot(r, _856) * _887) - _872) / _893, 0.0, 1.0);\n            }\n        }\n        return (p + _856) + (_862 * t);\n    }\n    vec3 q = p;\n    float _925 = dot(r, axis);\n    bool _933;\n    if (_843)\n    {\n        _933 = abs(_925) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _933 = _843;\n    }\n    if (_933)\n    {\n        float _943 = dot(c - p, axis) / _925;\n        if (_943 > 0.0)\n        {\n            q = p + (r * _943);\n        }\n    }\n    vec3 _956 = q - c;\n    vec2 xy = vec2(dot(_956, ru), dot(_956, uu));\n    if (shape > 0.5)\n    {\n        float _971 = length(xy);\n        if (_971 > hx)\n        {\n            xy *= (hx / _971);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _604 = abs(d);\n    float _606 = _604.x;\n    float _608 = _604.y;\n    bool _609 = _606 >= _608;\n    bool _617;\n    if (_609)\n    {\n        _617 = _606 >= _604.z;\n    }\n    else\n    {\n        _617 = _609;\n    }\n    int _618;\n    if (_617)\n    {\n        _618 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _633;\n        if (_608 >= _604.z)\n        {\n            _633 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _633 = (d.z > 0.0) ? 4 : 5;\n        }\n        _618 = _633;\n    }\n    return _618;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _763 = dot(d, right);\n    float _767 = dot(d, up);\n    float _778;\n    if (((_763 * _763) + (_767 * _767)) > 1.0000000133514319600180897396058e-10)\n    {\n        _778 = atan(_767, _763) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _778 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_778 - floor(_778)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1009 = fa_light_base(param);\n    bool _1013 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1009;\n    vec4 _1017 = fa_light_texel(param_1);\n    int param_2 = _1009 + 1;\n    vec4 _1022 = fa_light_texel(param_2);\n    float _1025 = _1022.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1037 = _1013 && (_1025 > 2.5);\n    fa_light_is_area = _1037;\n    bool _1039 = _1025 < 0.5;\n    vec3 l;\n    if (_1039)\n    {\n        l = normalize(_1017.xyz);\n        if (_1013)\n        {\n            int param_3 = _1009 + 6;\n            vec4 _1053 = fa_light_texel(param_3);\n            if (_1053.z > 0.5)\n            {\n                int param_4 = _1009 + 4;\n                vec4 _1063 = fa_light_texel(param_4);\n                int param_5 = _1009 + 5;\n                vec4 _1068 = fa_light_texel(param_5);\n                vec2 param_6 = _1053.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1063.xyz) * _1063.w, (-dot(world_pos, _1068.xyz)) * _1068.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1098 = _1017.xyz;\n        vec3 _1100 = _1098 - world_pos;\n        vec3 to_light = _1100;\n        float _1103 = length(_1100);\n        float reach = _1103;\n        bool front = true;\n        if (_1037)\n        {\n            int param_8 = _1009 + 7;\n            reach = max(_1103 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1009 + 4;\n            vec4 _1127 = fa_light_texel(param_9);\n            int param_10 = _1009 + 5;\n            vec4 _1132 = fa_light_texel(param_10);\n            int param_11 = _1009 + 6;\n            vec4 _1137 = fa_light_texel(param_11);\n            float _1138 = _1137.w;\n            int param_12 = _1009 + 2;\n            vec3 _1145 = normalize(fa_light_texel(param_12).xyz);\n            bool _1147 = _1138 > 1.5;\n            bool _1155;\n            if (!_1147)\n            {\n                _1155 = dot(_1145, to_light) < 0.0;\n            }\n            else\n            {\n                _1155 = _1147;\n            }\n            front = _1155;\n            vec3 r = vec3(0.0);\n            vec3 _1164 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1168 = dot(n, n) > 0.5;\n            bool _1176;\n            if (_1168)\n            {\n                _1176 = dot(_1164, _1164) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1176 = _1168;\n            }\n            if (_1176)\n            {\n                r = reflect(-normalize(_1164), normalize(n));\n            }\n            vec3 param_13 = _1098;\n            vec3 param_14 = _1145;\n            vec3 param_15 = _1127.xyz;\n            vec3 param_16 = _1132.xyz;\n            float param_17 = _1127.w;\n            float param_18 = _1132.w;\n            float param_19 = _1138;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1212 = length(to_light);\n        dist = _1212;\n        l = to_light / vec3(max(_1212, 9.9999997473787516355514526367188e-05));\n        float _1226 = reach / max(_1017.w, 0.001000000047497451305389404296875);\n        float _1232 = clamp(1.0 - (_1226 * _1226), 0.0, 1.0);\n        float _1234;\n        if (front)\n        {\n            _1234 = _1232 * _1232;\n        }\n        else\n        {\n            _1234 = 0.0;\n        }\n        atten = _1234;\n        bool _1245 = _1025 < 2.5;\n        if ((_1025 > 1.5) && _1245)\n        {\n            int param_22 = _1009 + 2;\n            vec4 _1253 = fa_light_texel(param_22);\n            float _1263 = _1253.w;\n            int param_23 = _1009 + 3;\n            vec4 _1268 = fa_light_texel(param_23);\n            float _1269 = _1268.x;\n            float cos_inner = _1269;\n            if (_1269 > 1.5)\n            {\n                cos_inner = mix(_1263, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1263, cos_inner, dot(-l, normalize(_1253.xyz)));\n        }\n        if (_1013 && (_1025 < 1.5))\n        {\n            int param_24 = _1009 + 6;\n            vec4 _1293 = fa_light_texel(param_24);\n            if (_1293.z > 0.5)\n            {\n                vec3 _1301 = -to_light;\n                int param_25 = _1009 + 4;\n                int param_26 = _1009 + 5;\n                vec3 _1315 = fa_light_texel(param_25).xyz;\n                vec3 _1319 = fa_light_texel(param_26).xyz;\n                vec3 _1328 = vec3(dot(_1301, _1315), dot(_1301, _1319), dot(_1301, cross(_1315, _1319)));\n                vec3 param_27 = _1328;\n                int _1332 = fa_cube_face(param_27);\n                int param_28 = _1332;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1359 = vec2(dot(_1328, cross(param_29, param_30)), dot(_1328, param_30)) / vec2(max(dot(_1328, param_29), 9.9999997473787516355514526367188e-05));\n                int _1363 = _1332 / 3;\n                vec2 param_31 = _1293.xy + (vec2(float(_1332 - (_1363 * 3)), float(_1363)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1359.x), 0.5 - (0.5 * _1359.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1009 + 7;\n            vec4 _1393 = fa_light_texel(param_33);\n            if (_1393.z > 0.5)\n            {\n                int param_34 = _1009 + 2;\n                int param_35 = _1009 + 4;\n                int param_36 = _1009 + 5;\n                vec2 param_37 = _1393.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1013 && _1245)\n            {\n                int param_42 = _1009 + 6;\n                vec4 _1440 = fa_light_texel(param_42);\n                int param_43 = _1009 + 7;\n                vec4 _1445 = fa_light_texel(param_43);\n                bool _1448 = _1440.z > 0.5;\n                bool _1455;\n                if (!_1448)\n                {\n                    _1455 = _1445.z > 0.5;\n                }\n                else\n                {\n                    _1455 = _1448;\n                }\n                if (_1455)\n                {\n                    int param_44 = _1009 + 2;\n                    vec4 _1462 = fa_light_texel(param_44);\n                    vec3 _1466 = normalize(_1462.xyz);\n                    int param_45 = _1009 + 4;\n                    vec4 _1471 = fa_light_texel(param_45);\n                    int param_46 = _1009 + 5;\n                    vec4 _1476 = fa_light_texel(param_46);\n                    if (_1448)\n                    {\n                        vec3 _1484 = -to_light;\n                        float _1491 = _1462.w;\n                        float _1507 = 0.5 / max(dot(_1484, _1466) * (sqrt(max(1.0 - (_1491 * _1491), 0.0)) / max(_1491, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1440.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1484, _1471.xyz) * _1507), 0.5 - (dot(_1484, _1476.xyz) * _1507));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1445.z > 0.5)\n                    {\n                        vec2 param_49 = _1445.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1466;\n                        vec3 param_52 = _1471.xyz;\n                        vec3 param_53 = _1476.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9184 = _1022.xyz * atten;\n    if (_1013)\n    {\n        _9184 *= fa_light_tint;\n    }\n    int _1576;\n    if (_1039)\n    {\n        _1576 = 0;\n    }\n    else\n    {\n        _1576 = ((_1025 > 1.5) && (_1025 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9184, atten, 1.0, dist, _1576);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2308;\n    if (i == 0)\n    {\n        _2308 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2324;\n        if (i == 1)\n        {\n            _2324 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2332;\n            if (i == 2)\n            {\n                _2332 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2332 = fa_shadows[24].w;\n            }\n            _2324 = _2332;\n        }\n        _2308 = _2324;\n    }\n    return _2308;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2365 = fa_shadow_depth(param, param_1);\n    float _2369;\n    if (conv.x < 0.5)\n    {\n        _2369 = _2365;\n    }\n    else\n    {\n        _2369 = (conv.y * conv.z) / (conv.z - (_2365 * (conv.z - conv.y)));\n    }\n    return _2369;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2415 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2421 = vec2(cos(_2415), sin(_2415));\n    vec2 dir = _2421;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2430;\n        if (k < 0.0)\n        {\n            _2430 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2430 = k;\n        }\n        float _2449 = clamp((_2430 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2468 = sqrt((float(i) + 0.5) * 0.0625) * _2449;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2468));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2482 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2482 < (zr - (_2468 * plane)))\n            {\n                sum += _2482;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2510 = sum / cnt;\n        float _2520;\n        if (k < 0.0)\n        {\n            _2520 = (-k) / max(_2510, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2520 = k;\n        }\n        radius = clamp(((max(zr - _2510, 0.0) * unit) * _2520) / texel_m, 1.5, 16.0);\n        dir = _2421;\n    }\n    float lit = 0.0;\n    int _2546 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2546; i_1++)\n    {\n        float _2565 = sqrt((float(i_1) + 0.5) / float(_2546)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2565));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2565 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2546);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2611 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2616 = clamp(dot(n, l), 0.0, 1.0);\n    float _2622 = sqrt(1.0 - (_2616 * _2616));\n    float _2630 = min(_2622 / max(_2616, 0.20000000298023223876953125), 4.0);\n    float _2635;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2635 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2635 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2660 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2635 * _2622)), 1.0);\n    float _2667 = _2660.x;\n    bool _2670 = _2667 < fa_shadows[ci * 1 + 16].x;\n    bool _2679;\n    if (!_2670)\n    {\n        _2679 = _2667 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2679 = _2670;\n    }\n    bool _2688;\n    if (!_2679)\n    {\n        _2688 = _2660.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2688 = _2679;\n    }\n    bool _2697;\n    if (!_2688)\n    {\n        _2697 = _2660.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2697 = _2688;\n    }\n    bool _2704;\n    if (!_2697)\n    {\n        _2704 = _2660.z > 1.0;\n    }\n    else\n    {\n        _2704 = _2697;\n    }\n    if (_2704)\n    {\n        return -1.0;\n    }\n    float _2712;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2712 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2712 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2660.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2660.z - ((_2712 * (1.0 + (0.5 * _2630))) / _2611);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2611;\n    float param_5 = _2611 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2630, 3.0)) * 0.5) / _2611;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3090 = int(fa_shadows[25].x + 0.5);\n    if (_3090 < 1)\n    {\n        return 1.0;\n    }\n    float _3105 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3090 - 1;\n    if (_3105 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3117 = _3090 > 1;\n    bool _3124;\n    if (_3117)\n    {\n        _3124 = _3105 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3124 = _3117;\n    }\n    if (_3124)\n    {\n        ci = 1;\n    }\n    bool _3128 = _3090 > 2;\n    bool _3135;\n    if (_3128)\n    {\n        _3135 = _3105 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3135 = _3128;\n    }\n    if (_3135)\n    {\n        ci = 2;\n    }\n    bool _3139 = _3090 > 3;\n    bool _3146;\n    if (_3139)\n    {\n        _3146 = _3105 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3146 = _3139;\n    }\n    if (_3146)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3157 = min(_3090, 4);\n    float _3198;\n    for (int c = ci; c < _3157; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3177 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3177;\n            break;\n        }\n        if (_3177 < 0.0)\n        {\n            continue;\n        }\n        s = _3177;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3198 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3198 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3217 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3198, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3105 - (fa_shadow_split_at(param_7) - _3217)) / _3217, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3249;\n        if ((ci + 1) < _3090)\n        {\n            _3249 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3249 = 1.0;\n        }\n        s = mix(s, _3249, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3354 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3360;\n    if (_3354)\n    {\n        _3360 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3360 = _3354;\n    }\n    if (_3360)\n    {\n        float _3374 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3377 = fwidth(_3374);\n        vec4 _3387 = vec4(fa_world_pos, 1.0);\n        float _3393 = dot(fa_mesh_fs_params[28], _3387);\n        if (_3393 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3412 = vec2(dot(fa_mesh_fs_params[26], _3387), dot(fa_mesh_fs_params[27], _3387)) / vec2(_3393);\n            float _3417 = (_3412.x * 0.5) + 0.5;\n            float _3421;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3421 = (_3412.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3421 = 0.5 - (_3412.y * 0.5);\n            }\n            bool _3437 = _3417 >= 0.0;\n            bool _3443;\n            if (_3437)\n            {\n                _3443 = _3417 < 1.0;\n            }\n            else\n            {\n                _3443 = _3437;\n            }\n            bool _3449;\n            if (_3443)\n            {\n                _3449 = _3421 >= 0.0;\n            }\n            else\n            {\n                _3449 = _3443;\n            }\n            bool _3455;\n            if (_3449)\n            {\n                _3455 = _3421 < 1.0;\n            }\n            else\n            {\n                _3455 = _3449;\n            }\n            if (_3455)\n            {\n                vec4 _3481 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3417, _3421) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3484 = _3481.w > 0.5;\n                bool _3500;\n                if (_3484)\n                {\n                    _3500 = abs(_3374 - _3481.x) <= (((0.00200000009499490261077880859375 * _3374) + 0.00999999977648258209228515625) + min(1.5 * _3377, 0.100000001490116119384765625 * _3374));\n                }\n                else\n                {\n                    _3500 = _3484;\n                }\n                if (_3500)\n                {\n                    float _3506;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3506 = min(_3481.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3506 = _3481.y;\n                    }\n                    return _3506;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2770 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2777;\n    if (!_2770)\n    {\n        _2777 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2777 = _2770;\n    }\n    if (_2777)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2790 = fa_light_texel(param);\n    float _2791 = _2790.x;\n    if (_2791 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2800 = int(_2791 + 0.5);\n    int param_1 = _2800;\n    vec4 _2804 = fa_light_texel(param_1);\n    int param_2 = _2800 + 1;\n    vec4 _2809 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2812 = _2804.y;\n    if (_2812 > 0.0)\n    {\n        float _2829 = 1.0 - smoothstep(0.75 * _2812, _2812, length(world - fa_shadows[27].xyz));\n        fade = _2829;\n        if (_2829 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2804.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2853 = (_2800 + 2) + (face * 6);\n    int param_4 = _2853;\n    int param_5 = _2853 + 1;\n    int param_6 = _2853 + 3;\n    vec4 _2867 = fa_light_texel(param_6);\n    int param_7 = _2853 + 4;\n    vec4 _2872 = fa_light_texel(param_7);\n    int param_8 = _2853 + 5;\n    vec4 _2877 = fa_light_texel(param_8);\n    float _2889 = _2877.x * max(dot(_2867, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2894 = clamp(dot(n, l), 0.0, 1.0);\n    float _2917 = clamp(dot(n, _2867.xyz), -1.0, 1.0);\n    float _2936 = min(sqrt(1.0 - (_2917 * _2917)) / max(abs(dot(n, world - lpos)) / max(dot(_2867, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2939 = _2809.y;\n    float _2941;\n    if (_2939 > 0.0)\n    {\n        _2941 = _2939;\n    }\n    else\n    {\n        _2941 = 1.5 * _2889;\n    }\n    vec4 _2961 = vec4(world + (n * (_2941 * sqrt(1.0 - (_2894 * _2894)))), 1.0);\n    float _2965 = dot(_2867, _2961);\n    float _2968 = _2877.y;\n    if (_2965 < _2968)\n    {\n        return 1.0;\n    }\n    vec2 _2983 = vec2(dot(fa_light_texel(param_4), _2961), dot(fa_light_texel(param_5), _2961)) / vec2(_2965);\n    float _2985 = _2983.x;\n    bool _2988 = _2985 < _2872.x;\n    bool _2997;\n    if (!_2988)\n    {\n        _2997 = _2985 > _2872.z;\n    }\n    else\n    {\n        _2997 = _2988;\n    }\n    bool _3006;\n    if (!_2997)\n    {\n        _3006 = _2983.y < _2872.y;\n    }\n    else\n    {\n        _3006 = _2997;\n    }\n    bool _3015;\n    if (!_3006)\n    {\n        _3015 = _2983.y > _2872.w;\n    }\n    else\n    {\n        _3015 = _3006;\n    }\n    if (_3015)\n    {\n        return 1.0;\n    }\n    float _3021 = _2809.x;\n    float _3023;\n    if (_3021 > 0.0)\n    {\n        _3023 = _3021;\n    }\n    else\n    {\n        _3023 = 1.5 * _2889;\n    }\n    vec2 param_9 = _2983;\n    vec4 param_10 = _2872;\n    float param_11 = _2965 - (_3023 * (1.0 + (0.5 * _2936)));\n    float param_12 = _2889;\n    float param_13 = 1.0;\n    float param_14 = _2877.z * 0.25;\n    float param_15 = (_2889 * min(_2936, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2968, _2877.z);\n    int param_17 = int(_2804.z + 0.5);\n    float param_18 = _2804.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5349 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5356;\n    if (!_5349)\n    {\n        _5356 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5356 = _5349;\n    }\n    if (_5356)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5369 = fa_light_texel(param);\n    float _5370 = _5369.y;\n    float len = _5370;\n    if (_5370 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5382 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5391 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5382);\n    if (_5391 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5397 = len;\n    float _5400 = min(_5397, 0.89999997615814208984375 * dist);\n    len = _5400;\n    float _5405 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5382);\n    float _5410 = _5405 + (0.5 * _5400);\n    vec3 _5416 = world + (gn * _5405);\n    float _5418 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5479;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5433 = (float(k) + _5418) * 0.083333335816860198974609375;\n        vec3 _5441 = _5416 + (l * (_5433 * len));\n        vec4 _5447 = vec4(_5441, 1.0);\n        float _5452 = dot(fa_mesh_fs_params[28], _5447);\n        if (_5452 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5470 = vec2(dot(fa_mesh_fs_params[26], _5447), dot(fa_mesh_fs_params[27], _5447)) / vec2(_5452);\n        float _5474 = _5470.x * 0.5;\n        float _5475 = _5474 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5479 = (_5470.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5479 = 0.5 - (_5470.y * 0.5);\n        }\n        bool _5495 = _5475 < 0.0;\n        bool _5502;\n        if (!_5495)\n        {\n            _5502 = _5475 >= 1.0;\n        }\n        else\n        {\n            _5502 = _5495;\n        }\n        bool _5509;\n        if (!_5502)\n        {\n            _5509 = _5479 < 0.0;\n        }\n        else\n        {\n            _5509 = _5502;\n        }\n        bool _5516;\n        if (!_5509)\n        {\n            _5516 = _5479 >= 1.0;\n        }\n        else\n        {\n            _5516 = _5509;\n        }\n        if (_5516)\n        {\n            break;\n        }\n        vec4 _5540 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5475, _5479) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5540.w < 0.5)\n        {\n            continue;\n        }\n        float _5558 = (dot(fa_mesh_fs_params[29].xyz, _5441) + fa_mesh_fs_params[29].w) - _5540.x;\n        if ((_5558 > _5405) && (_5558 < _5410))\n        {\n            occ = max(occ, (1.0 - (_5433 * _5433)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5475, 0.5 - _5474), min(_5479, 1.0 - _5479))));\n        }\n    }\n    return 1.0 - (occ * _5391);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6024 = fa_baked_keep(param);\n    if (_6024 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6050 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9253 = _6050.color;\n    float _9254 = _6050.attenuation;\n    float _9255 = _6050.shadow;\n    bool _6053 = _6050.type == 0;\n    if (_6053 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6050.direction;\n        float _6064 = fa_shadow_factor(param_5, param_6);\n        _9255 = _6064;\n        _9253 *= _6064;\n    }\n    else\n    {\n        bool _6075 = _6050.type != 0;\n        bool _6081;\n        if (_6075)\n        {\n            _6081 = _9254 > 0.0;\n        }\n        else\n        {\n            _6081 = _6075;\n        }\n        if (_6081)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6050.direction;\n            float _6100 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _9255 = _6100;\n            _9253 *= _6100;\n        }\n    }\n    bool _6110 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6116;\n    if (_6110)\n    {\n        _6116 = _9254 > 0.0;\n    }\n    else\n    {\n        _6116 = _6110;\n    }\n    if (_6116)\n    {\n        float _6123;\n        if (_6053)\n        {\n            _6123 = 1000000000.0;\n        }\n        else\n        {\n            _6123 = _6050._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6050.direction;\n        float param_18 = _6123;\n        float _6141 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9255 *= _6141;\n        _9253 *= _6141;\n    }\n    float _6154 = _9254;\n    float _6155 = _6154 * _6024;\n    _9254 = _6155;\n    vec3 _6159 = _9253;\n    vec3 _6160 = _6159 * _6024;\n    _9253 = _6160;\n    return LightSample(_6050.direction, _6160, _6155, _9255, _6050._distance, _6050.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6194 = v - (n * dot(v, n));\n    vec3 t = _6194;\n    float _6198 = dot(_6194, _6194);\n    float l2 = _6198;\n    if (_6198 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6208;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6208 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6208 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6208;\n        l2 = dot(_6208, _6208);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6595;\n    if ((j == 0) || (j == 7))\n    {\n        _6595 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6605;\n        if ((j == 3) || (j == 4))\n        {\n            _6605 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6605 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6595 = _6605;\n    }\n    float _6626;\n    if ((j == 1) || (j == 2))\n    {\n        _6626 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6635;\n        if ((j == 5) || (j == 6))\n        {\n            _6635 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6635 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6626 = _6635;\n    }\n    return (pc + (ex * _6595)) + (ey * _6626);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6243 = dot(a, a);\n    float _6247 = dot(b, b);\n    if ((_6243 < 1.0000000195414813782625560981111e-24) || (_6247 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6261 = a * inversesqrt(_6243);\n    vec3 _6266 = b * inversesqrt(_6247);\n    float _6270 = dot(_6261, _6266);\n    float _6273 = abs(_6270);\n    float g = (((((((((((0.0416471660137176513671875 * _6273) - 0.1924748718738555908203125) * _6273) + 0.4179156124591827392578125) * _6273) - 0.616057217121124267578125) * _6273) + 0.777722418308258056640625) * _6273) - 0.999542415142059326171875) * _6273) + 1.570791721343994140625;\n    if (_6270 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6270 * _6270), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6261, _6266) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6330 = a.z > 0.0;\n    bool _6334 = b.z > 0.0;\n    if (_6330 && _6334)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6330 != _6334)\n        {\n            vec3 _6369 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6369.z = 0.0;\n            if (_6330)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6369;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6369;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6369;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6369;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6418 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6444 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6470 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6496 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6418;\n    vec3 param_1 = _6444;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6444;\n    vec3 param_7 = _6470;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6470;\n    vec3 param_13 = _6496;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6496;\n    vec3 param_19 = _6418;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6664 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6682;\n    for (int k = 0; k < (2 * _6664); k++)\n    {\n        bool _6679 = k >= _6664;\n        if (_6679)\n        {\n            _6682 = k - _6664;\n        }\n        else\n        {\n            _6682 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6664 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _6728 = 2 * _6682;\n            int param_4 = _6728 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _6728 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _6728 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _6765 = bvec4(_6679);\n        vec4 param_16 = vec4(_6765.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _6765.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _6765.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _6765.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _6776 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6679)\n        {\n            vec2 _9491 = sum;\n            _9491.y = _9491.y + _6776;\n            sum = _9491;\n        }\n        else\n        {\n            vec2 _9494 = sum;\n            _9494.x = _9494.x + _6776;\n            sum = _9494;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6800 = fa_light_base(param);\n    int param_1 = _6800;\n    int param_2 = _6800 + 1;\n    int param_3 = _6800 + 2;\n    int param_4 = _6800 + 4;\n    vec4 _6822 = fa_light_texel(param_4);\n    int param_5 = _6800 + 5;\n    vec4 _6827 = fa_light_texel(param_5);\n    int param_6 = _6800 + 6;\n    vec4 _6832 = fa_light_texel(param_6);\n    float _6833 = _6832.w;\n    vec3 _6838 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6840 = _6833 < 1.5;\n    bool _6847;\n    if (_6840)\n    {\n        _6847 = dot(normalize(fa_light_texel(param_3).xyz), _6838) >= 0.0;\n    }\n    else\n    {\n        _6847 = _6840;\n    }\n    if (_6847)\n    {\n        return vec3(0.0);\n    }\n    bool _6856 = (_6833 > 0.5) && _6840;\n    float _6860 = _6856 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6863 = _6822.xyz;\n    float _6865 = _6822.w;\n    vec3 _6871 = _6827.xyz;\n    float _6873 = _6827.w;\n    vec3 up = _6871 * (_6873 * _6860);\n    float _6879;\n    if (_6856)\n    {\n        _6879 = (3.1415927410125732421875 * _6865) * _6865;\n    }\n    else\n    {\n        _6879 = (4.0 * _6865) * _6873;\n    }\n    if (_6833 > 1.5)\n    {\n        vec3 _6905 = cross(_6863, -_6838);\n        vec3 perp = _6905;\n        float _6909 = dot(_6905, _6905);\n        vec3 _6912;\n        if (_6909 > 1.0000000133514319600180897396058e-10)\n        {\n            _6912 = perp * inversesqrt(_6909);\n        }\n        else\n        {\n            _6912 = _6871;\n        }\n        perp = _6912;\n        up = _6912 * _6873;\n    }\n    float _6933 = max(_6879, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6943 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6943;\n    vec3 param_10 = n;\n    vec3 param_11 = _6838;\n    vec3 param_12 = _6943;\n    vec3 param_13 = n;\n    vec3 param_14 = _6863 * (_6865 * _6860);\n    vec3 param_15 = _6943;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _6974 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _6974;\n    vec2 param_21 = _6974 + vec2(64.0, 0.0);\n    vec4 _6984 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _6833;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _6996 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _6996.x) + (((f0 * _6984.x) + ((vec3(f90) - f0) * _6984.y)) * _6996.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6838, _6838)) + _6933) / _6933) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5086 = 1.0 / alpha;\n    return ((2.0 + _5086) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5086)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5121 = max(dot(L.nc, l), 0.0);\n    float _5127 = max(dot(L.nc, h), 0.0);\n    float _5136 = ((_5127 * _5127) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5136) * _5136)) * (0.5 / max(mix((2.0 * _5121) * L.coat_ndv, _5121 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5121)) * _5121;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7033;\n    if (L.sheen_on)\n    {\n        _7033 = L.sheen_scale;\n    }\n    else\n    {\n        _7033 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7033);\n    vec3 _7046 = normalize(l + v);\n    int param = li;\n    vec3 _7057 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7066 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7046), 0.0);\n        float param_3 = _7066;\n        float param_4 = ndv;\n        result += ((L.sheen * _7057) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7066)) * _7066) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7046;\n        float param_8 = max(dot(v, _7046), 0.0);\n        result += (_7057 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4989 = tdh / at;\n    float _4993 = bdh / ab;\n    float _5005 = ((_4989 * _4989) + (_4993 * _4993)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5005) * _5005);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5185 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5264 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5264) * _5264);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5185);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5185));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4388 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4391 = _4388.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4391 * _4391, exp2((-9.27999973297119140625) * ndv)) * _4391) + _4388.y)) + _4388.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3697;\n    if (lv == 0)\n    {\n        _3697 = 0.0;\n    }\n    else\n    {\n        _3697 = res + 2.0;\n    }\n    float _3707;\n    if (lv == 0)\n    {\n        _3707 = 0.0;\n    }\n    else\n    {\n        _3707 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3697, _3707)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3753;\n    if (res > 64.5)\n    {\n        _3753 = 5.0;\n    }\n    else\n    {\n        _3753 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3768 = clamp(rough, 0.0, 1.0) * (_3753 - 1.0);\n    int _3775 = int(min(floor(_3768), _3753 - 2.0));\n    float _3780 = _3768 - float(_3775);\n    vec3 param = d;\n    vec2 _3784 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3775;\n    vec2 param_4 = _3784;\n    vec3 _3794 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3780 < 0.00200000009499490261077880859375)\n    {\n        return _3794;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3775 + 1;\n    vec2 param_8 = _3784;\n    return mix(_3794, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3780));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3866 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3873 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3880 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3886 = dot(bx.xyz, d);\n    float _3890 = dot(by.xyz, d);\n    float _3894 = dot(bz.xyz, d);\n    float _3900;\n    if (_3886 > 9.9999999747524270787835121154785e-07)\n    {\n        _3900 = (1.0 - _3866) / _3886;\n    }\n    else\n    {\n        float _3914;\n        if (_3886 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3914 = ((-1.0) - _3866) / _3886;\n        }\n        else\n        {\n            _3914 = 1000000015047466219876688855040.0;\n        }\n        _3900 = _3914;\n    }\n    float tx = _3900;\n    float _3931;\n    if (_3890 > 9.9999999747524270787835121154785e-07)\n    {\n        _3931 = (1.0 - _3873) / _3890;\n    }\n    else\n    {\n        float _3944;\n        if (_3890 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3944 = ((-1.0) - _3873) / _3890;\n        }\n        else\n        {\n            _3944 = 1000000015047466219876688855040.0;\n        }\n        _3931 = _3944;\n    }\n    float ty = _3931;\n    float _3960;\n    if (_3894 > 9.9999999747524270787835121154785e-07)\n    {\n        _3960 = (1.0 - _3880) / _3894;\n    }\n    else\n    {\n        float _3973;\n        if (_3894 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3973 = ((-1.0) - _3880) / _3894;\n        }\n        else\n        {\n            _3973 = 1000000015047466219876688855040.0;\n        }\n        _3960 = _3973;\n    }\n    float _3985 = tx;\n    float _3988 = (_3985 > 0.0) ? _3985 : 1000000015047466219876688855040.0;\n    tx = _3988;\n    float _3989 = ty;\n    float _3992 = (_3989 > 0.0) ? _3989 : 1000000015047466219876688855040.0;\n    ty = _3992;\n    float _4002 = min(_3988, min(_3992, (_3960 > 0.0) ? _3960 : 1000000015047466219876688855040.0));\n    if (_4002 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4018 = (fa_world_pos + (d * _4002)) - posw.xyz;\n    vec3 _4023;\n    if (dot(_4018, _4018) > 1.0000000133514319600180897396058e-10)\n    {\n        _4023 = normalize(_4018);\n    }\n    else\n    {\n        _4023 = d;\n    }\n    return _4023;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4069 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4069 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4097 = rough * rough;\n            float _4128 = 0.60000002384185791015625 * _4097;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4097)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4128, 0.0500000007450580596923828125 + _4128, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4097 * 0.60000002384185791015625));\n        }\n        outc = base * _4069;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4187 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4187 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4219 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4219 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4866;\n        if (L.aniso >= 0.0)\n        {\n            _4866 = L.b;\n        }\n        else\n        {\n            _4866 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4866, v), _4866), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4902 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4902.x) + (vec3(L.f90) * _4902.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4960 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4960.x) + _4960.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4430 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4430.x) + vec3(_4430.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5662 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5666 = fa_xm_origin(param_1);\n    vec2 _5672 = (uv * _5662) - vec2(0.5);\n    vec2 _5675 = fract(_5672);\n    vec2 _5678 = floor(_5672);\n    vec2 param_2 = _5662;\n    vec2 param_3 = _5666;\n    vec2 param_4 = _5678;\n    vec2 param_5 = _5662;\n    vec2 param_6 = _5666;\n    vec2 param_7 = _5678 + vec2(1.0, 0.0);\n    vec2 param_8 = _5662;\n    vec2 param_9 = _5666;\n    vec2 param_10 = _5678 + vec2(0.0, 1.0);\n    vec2 param_11 = _5662;\n    vec2 param_12 = _5666;\n    vec2 param_13 = _5678 + vec2(1.0);\n    vec3 _5720 = vec3(_5675.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _5720), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _5720), vec3(_5675.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _5739 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _5743 = clamp(lod, 0.0, _5739);\n    int _5747 = int(floor(_5743));\n    int param = _5747;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _5757 = float(_5747);\n    float _5758 = _5743 - _5757;\n    bool _5760 = _5758 > 0.001000000047497451305389404296875;\n    bool _5767;\n    if (_5760)\n    {\n        _5767 = _5757 < _5739;\n    }\n    else\n    {\n        _5767 = _5760;\n    }\n    if (_5767)\n    {\n        int param_2 = _5747 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_5758));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5793 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _5793.x) + (vec3(f90) * _5793.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _5821 = max(s.thickness, 0.0);\n    bool _5826 = _5821 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _5826)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _5821);\n    }\n    bool _5851 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5858;\n    if (!_5851)\n    {\n        _5858 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5858 = _5851;\n    }\n    if (_5858)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_5826)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _5821);\n    }\n    vec4 _5893 = vec4(world, 1.0);\n    float _5898 = dot(fa_mesh_fs_params[28], _5893);\n    vec2 uv = vec2(0.5);\n    if (_5898 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5916 = vec2(dot(fa_mesh_fs_params[26], _5893), dot(fa_mesh_fs_params[27], _5893)) / vec2(_5898);\n        float _5924;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5924 = (_5916.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5924 = 0.5 - (_5916.y * 0.5);\n        }\n        uv = vec2((_5916.x * 0.5) + 0.5, _5924);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3277 = int(fa_shadows[25].x + 0.5);\n    float _3287 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3292 = _3277 > 0;\n    bool _3301;\n    if (_3292)\n    {\n        int param = _3277 - 1;\n        _3301 = _3287 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3301 = _3292;\n    }\n    if (_3301)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3307 = _3277 > 1;\n        bool _3314;\n        if (_3307)\n        {\n            _3314 = _3287 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3314 = _3307;\n        }\n        if (_3314)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3320 = _3277 > 2;\n        bool _3327;\n        if (_3320)\n        {\n            _3327 = _3287 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3327 = _3320;\n        }\n        if (_3327)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3333 = _3277 > 3;\n        bool _3340;\n        if (_3333)\n        {\n            _3340 = _3287 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3340 = _3333;\n        }\n        if (_3340)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _8912 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _8912 = -_8912;\n    }\n    vec3 _8210 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _8912, fa_world_tangent, fa_uv, fa_vertex_color, _8210, gl_FrontFacing);\n    Surface _8218 = fa_standard_surface(param_1);\n    vec3 _8943 = _8218.albedo;\n    float _8944 = _8218.alpha;\n    vec3 _8945 = _8218.normal;\n    float _8946 = _8218.metallic;\n    float _8947 = _8218.roughness;\n    float _8948 = _8218.occlusion;\n    vec3 _8949 = _8218.emission;\n    float _8950 = _8218.clearcoat;\n    float _8951 = _8218.clearcoat_roughness;\n    vec3 _8952 = _8218.sheen_color;\n    float _8953 = _8218.sheen_roughness;\n    float _8954 = _8218.anisotropy;\n    float _8955 = _8218.anisotropy_rotation;\n    float _8956 = _8218.specular;\n    float _8957 = _8218.ior;\n    vec3 _8958 = _8218.specular_color;\n    float _8959 = _8218.transmission;\n    float _8960 = _8218.thickness;\n    vec3 _8961 = _8218.attenuation_color;\n    float _8962 = _8218.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _8912, fa_world_tangent, fa_uv, fa_vertex_color, _8210, gl_FrontFacing);\n    Surface param_3 = _8218;\n    surface(param_2, param_3);\n    _8943 = param_3.albedo;\n    _8944 = param_3.alpha;\n    _8945 = param_3.normal;\n    _8946 = param_3.metallic;\n    _8947 = param_3.roughness;\n    _8948 = param_3.occlusion;\n    _8949 = param_3.emission;\n    _8950 = param_3.clearcoat;\n    _8951 = param_3.clearcoat_roughness;\n    _8952 = param_3.sheen_color;\n    _8953 = param_3.sheen_roughness;\n    _8954 = param_3.anisotropy;\n    _8955 = param_3.anisotropy_rotation;\n    _8956 = param_3.specular;\n    _8957 = param_3.ior;\n    _8958 = param_3.specular_color;\n    _8959 = param_3.transmission;\n    _8960 = param_3.thickness;\n    _8961 = param_3.attenuation_color;\n    _8962 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _8912;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _8943 = param_6;\n    _8945 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _8943;\n    }\n    else\n    {\n        vec3 _8258 = normalize(_8945);\n        float _8265 = clamp(_8946, 0.0, 1.0);\n        float _8269 = clamp(_8947, 0.0500000007450580596923828125, 1.0);\n        float _8273 = _8269 * _8269;\n        float _8277 = _8273 * _8273;\n        float _8282 = max(dot(_8258, _8210), 9.9999997473787516355514526367188e-05);\n        float _8288 = 1.0 - _8265;\n        float _8289 = clamp(_8959, 0.0, 1.0) * _8288;\n        vec3 _8298 = (_8943 * _8288) * (1.0 - _8289);\n        vec3 _8305 = mix(vec3(0.039999999105930328369140625), _8943, vec3(_8265));\n        vec3 f0 = _8305;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _8912, fa_world_tangent, fa_uv, fa_vertex_color, _8210, gl_FrontFacing);\n        Surface param_9 = Surface(_8943, _8944, _8945, _8946, _8947, _8948, _8949, _8950, _8951, _8952, _8953, _8954, _8955, _8956, _8957, _8958, _8959, _8960, _8961, _8962);\n        vec3 param_10 = _8258;\n        vec3 param_11 = _8210;\n        float param_12 = _8265;\n        float param_13 = _8269;\n        vec3 param_14 = _8305;\n        FaLayers _8321 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8258;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8298) * _8948;\n        if (_8321.on)\n        {\n            lit *= _8321.base_scale;\n        }\n        int _8343 = fa_cl_ndir + fa_cl_local;\n        float _8408;\n        for (int ln = 0; ln < _8343; ln++)\n        {\n            int param_16 = ln;\n            int _8356 = fa_cl_light(param_16);\n            int param_17 = _8356;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8356;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _8912;\n            LightSample _8372 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8380 = max(dot(_8258, _8372.direction), 0.0);\n            float _8386 = _8372.attenuation * _8372.shadow;\n            vec3 _8391 = normalize(_8372.direction + _8210);\n            float _8396 = max(dot(_8258, _8391), 0.0);\n            float _8401 = max(dot(_8210, _8391), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8321.on)\n                {\n                    _8408 = _8321.f90;\n                }\n                else\n                {\n                    _8408 = 1.0;\n                }\n                int param_21 = _8356;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8258;\n                vec3 param_24 = _8210;\n                vec3 param_25 = _8298;\n                vec3 param_26 = f0;\n                float param_27 = _8408;\n                float param_28 = _8269;\n                float param_29 = _8282;\n                float param_30 = _8386;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8321.on)\n                {\n                    FaLayers param_31 = _8321;\n                    vec3 param_32 = area;\n                    int param_33 = _8356;\n                    vec3 param_34 = _8258;\n                    vec3 param_35 = _8210;\n                    vec3 param_36 = _8372.direction;\n                    float param_37 = _8282;\n                    float param_38 = _8386;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8321.on)\n                {\n                    FaLayers param_39 = _8321;\n                    vec3 param_40 = _8298;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8258;\n                    vec3 param_43 = _8210;\n                    vec3 param_44 = _8372.direction;\n                    vec3 param_45 = _8391;\n                    float param_46 = _8380;\n                    float param_47 = _8282;\n                    float param_48 = _8396;\n                    float param_49 = _8401;\n                    float param_50 = _8273;\n                    float param_51 = _8277;\n                    int param_52 = _8356;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8386));\n                }\n                else\n                {\n                    float _8510 = ((_8396 * _8396) * (_8277 - 1.0)) + 1.0;\n                    int param_53 = _8356;\n                    lit += (((_8298 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8401, 5.0))) * (((_8277 / ((3.1415927410125732421875 * _8510) * _8510)) * (0.5 / max(mix((2.0 * _8380) * _8282, _8380 + _8282, _8273), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8380))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8380 * _8386));\n                }\n            }\n        }\n        if (_8321.on)\n        {\n            FaLayers param_54 = _8321;\n            vec3 param_55 = _8258;\n            vec3 param_56 = _8210;\n            vec3 param_57 = f0;\n            float param_58 = _8269;\n            float param_59 = _8948;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8258;\n            vec3 param_61 = _8210;\n            vec3 param_62 = f0;\n            float param_63 = _8269;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _8948);\n        }\n        if (_8289 > 0.0)\n        {\n            float _8608;\n            if (_8321.on)\n            {\n                _8608 = _8321.f90;\n            }\n            else\n            {\n                _8608 = 1.0;\n            }\n            float _8616;\n            if (_8321.on)\n            {\n                _8616 = _8321.base_scale;\n            }\n            else\n            {\n                _8616 = 1.0;\n            }\n            Surface param_64 = Surface(_8943, _8944, _8945, _8946, _8947, _8948, _8949, _8950, _8951, _8952, _8953, _8954, _8955, _8956, _8957, _8958, _8959, _8960, _8961, _8962);\n            vec3 param_65 = _8258;\n            vec3 param_66 = _8210;\n            float param_67 = _8269;\n            vec3 param_68 = f0;\n            float param_69 = _8608;\n            float param_70 = _8616;\n            float param_71 = _8289;\n            float param_72 = fa_tr_blend;\n            vec3 _8640 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8640;\n        }\n        result = lit;\n    }\n    vec3 _8647 = result;\n    vec3 _8648 = _8647 + _8949;\n    result = _8648;\n    vec3 param_73 = _8648;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8657 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8664;\n    if (!_8657)\n    {\n        _8664 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8664 = _8657;\n    }\n    if (_8664)\n    {\n        vec3 _8673 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8679 = dot(_8673, fa_mesh_fs_params[9].xyz);\n        bool _8683 = fa_mesh_fs_params[9].w > 0.5;\n        float _8684;\n        if (_8683)\n        {\n            _8684 = _8679;\n        }\n        else\n        {\n            _8684 = length(_8673);\n        }\n        float _8696 = _8684 - fa_mesh_fs_params[8].x;\n        if (_8696 > 0.0)\n        {\n            float _8705 = fa_mesh_fs_params[7].w * _8696;\n            float tau = _8705 * _8705;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _8721;\n                if (_8683)\n                {\n                    _8721 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8679);\n                }\n                else\n                {\n                    _8721 = fa_mesh_fs_params[0].y;\n                }\n                float _8742 = mix(_8721, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8684, 0.0, 1.0));\n                float _8746 = fa_world_pos.y - _8742;\n                float _8751 = _8742 - fa_mesh_fs_params[8].z;\n                float _8756 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _8759 = _8751 <= 0.0;\n                bool _8760 = !_8759;\n                bool _8766;\n                if (_8760)\n                {\n                    _8766 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8766 = _8759;\n                }\n                float _8767;\n                if (_8766)\n                {\n                    _8767 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _8767 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _8751, 80.0));\n                }\n                bool _8794;\n                if (_8760)\n                {\n                    _8794 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8794 = _8759;\n                }\n                float _8795;\n                if (_8794)\n                {\n                    _8795 = fa_mesh_fs_params[8].y * _8751;\n                }\n                else\n                {\n                    _8795 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8751, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _8820 = _8756 <= 0.0;\n                bool _8827;\n                if (!_8820)\n                {\n                    _8827 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _8827 = _8820;\n                }\n                float _8828;\n                if (_8827)\n                {\n                    _8828 = fa_mesh_fs_params[8].y * _8756;\n                }\n                else\n                {\n                    _8828 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _8756, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _8855;\n                if (abs(_8746) < 0.001000000047497451305389404296875)\n                {\n                    _8855 = _8767;\n                }\n                else\n                {\n                    _8855 = (_8828 - _8795) / _8746;\n                }\n                tau += (_8696 * max(_8855, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _8891 = 1.0 - fa_tr_blend;\n        result /= vec3(_8891);\n        _8944 *= _8891;\n    }\n    fa_frag_color = vec4(result, _8944);\n}\n\n",
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
            "inst_name": "_7135",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nlayout(location = 11) in vec3 fa_vel_cur;\nlayout(location = 12) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _269 = fa_tex_fix(param_2, param_3);\n    vec4 _876 = base_t;\n    _876.x = _269.x;\n    _876.y = _269.y;\n    _876.z = _269.z;\n    base_t = _876;\n    vec4 _285 = (_876 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _831 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _320 = fa_tex_fix(param_6, param_7);\n        vec3 _324 = (_320 * 2.0) - vec3(1.0);\n        vec2 _329 = _324.xy * fa_mesh_fs_params[6].x;\n        vec3 _884 = _324;\n        _884.x = _329.x;\n        _884.y = _329.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _884;\n        _831 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _360 = fa_tex_fix(param_12, param_13);\n    vec4 _887 = mrt;\n    _887.x = _360.x;\n    _887.y = _360.y;\n    _887.z = _360.z;\n    mrt = _887;\n    vec4 _392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _404 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _436 = fa_tex_fix(param_20, param_21);\n    float _836 = fa_mesh_fs_params[20].x;\n    float _837 = fa_mesh_fs_params[20].y;\n    float _840 = fa_mesh_fs_params[20].z;\n    float _839 = fa_mesh_fs_params[21].w;\n    float _842 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _836 *= _404.y;\n            _837 *= _404.z;\n            _839 *= _392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _840 *= mrt.x;\n            _842 *= mrt.w;\n        }\n    }\n    return Surface(_285.xyz, _285.w, _831, clamp(fa_mesh_fs_params[5].x * _360.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _360.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_404.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _436), _836, _837, fa_mesh_fs_params[21].xyz, _839, _840, fa_mesh_fs_params[20].w, _842, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _726 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _726 = -_726;\n    }\n    vec3 _587 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _602 = normalize(param_2.normal);\n    vec3 _617 = normalize(vec3(dot(fa_pre_r0, _602), dot(fa_pre_r1, _602), dot(fa_pre_r2, _602)));\n    float _629 = _617.z;\n    vec2 e = _617.xy / vec2((abs(_617.x) + abs(_617.y)) + abs(_629));\n    if (_629 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _673 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _680;\n    if (_673)\n    {\n        _680 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _680 = _673;\n    }\n    if (_680)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_254",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) out vec3 fa_vel_cur;\nlayout(location = 12) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 13) in vec4 fa_prev_r0;\nlayout(location = 14) in vec4 fa_prev_r1;\nlayout(location = 15) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _225 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_225 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_225 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_225 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _137 = cross(model[1].xyz, model[2].xyz);\n    float _141 = (dot(model[0].xyz, _137) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_137 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _141, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _141), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _353 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _353;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _353 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _353 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _496;\n    if (has_prev)\n    {\n        _496 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _496 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _519 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _526 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_519 * _526).z;\n    fa_pre_r0 = vec3(_519[0].x, _519[1].x, _519[2].x);\n    fa_pre_r1 = vec3(_519[0].y, _519[1].y, _519[2].y);\n    fa_pre_r2 = vec3(_519[0].z, _519[1].z, _519[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _526;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_496)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _526).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nlayout(location = 11) in vec3 fa_vel_cur;\nlayout(location = 12) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _269 = fa_tex_fix(param_2, param_3);\n    vec4 _876 = base_t;\n    _876.x = _269.x;\n    _876.y = _269.y;\n    _876.z = _269.z;\n    base_t = _876;\n    vec4 _285 = (_876 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _831 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _320 = fa_tex_fix(param_6, param_7);\n        vec3 _324 = (_320 * 2.0) - vec3(1.0);\n        vec2 _329 = _324.xy * fa_mesh_fs_params[6].x;\n        vec3 _884 = _324;\n        _884.x = _329.x;\n        _884.y = _329.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _884;\n        _831 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _360 = fa_tex_fix(param_12, param_13);\n    vec4 _887 = mrt;\n    _887.x = _360.x;\n    _887.y = _360.y;\n    _887.z = _360.z;\n    mrt = _887;\n    vec4 _392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _404 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _436 = fa_tex_fix(param_20, param_21);\n    float _836 = fa_mesh_fs_params[20].x;\n    float _837 = fa_mesh_fs_params[20].y;\n    float _840 = fa_mesh_fs_params[20].z;\n    float _839 = fa_mesh_fs_params[21].w;\n    float _842 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _836 *= _404.y;\n            _837 *= _404.z;\n            _839 *= _392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _840 *= mrt.x;\n            _842 *= mrt.w;\n        }\n    }\n    return Surface(_285.xyz, _285.w, _831, clamp(fa_mesh_fs_params[5].x * _360.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _360.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_404.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _436), _836, _837, fa_mesh_fs_params[21].xyz, _839, _840, fa_mesh_fs_params[20].w, _842, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _726 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _726 = -_726;\n    }\n    vec3 _587 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _602 = normalize(param_2.normal);\n    vec3 _617 = normalize(vec3(dot(fa_pre_r0, _602), dot(fa_pre_r1, _602), dot(fa_pre_r2, _602)));\n    float _629 = _617.z;\n    vec2 e = _617.xy / vec2((abs(_617.x) + abs(_617.y)) + abs(_629));\n    if (_629 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _673 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _680;\n    if (_673)\n    {\n        _680 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _680 = _673;\n    }\n    if (_680)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_254",
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
