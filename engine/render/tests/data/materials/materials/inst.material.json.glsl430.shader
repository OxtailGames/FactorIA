{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1622[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _497 = fa_mesh_fs_params[19].x < 0.0;\n    bool _504;\n    if (!_497)\n    {\n        _504 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _504 = _497;\n    }\n    bool _512;\n    if (!_504)\n    {\n        _512 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _512 = _504;\n    }\n    bool _519;\n    if (!_512)\n    {\n        _519 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _519 = _512;\n    }\n    bool _526;\n    if (!_519)\n    {\n        _526 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _526 = _519;\n    }\n    if (_526)\n    {\n        return ivec2(0);\n    }\n    vec4 _536 = vec4(world_pos, 1.0);\n    float _543 = dot(fa_mesh_fs_params[16], _536);\n    if (!(_543 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _565 = vec2(dot(fa_mesh_fs_params[14], _536), dot(fa_mesh_fs_params[15], _536)) / vec2(_543);\n    int _569 = int(fa_mesh_fs_params[18].x);\n    int _573 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _573) + clamp(int(floor(((_565.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _573 - 1)) * _569)) + clamp(int(floor(((_565.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _569 - 1);\n    vec4 _644 = fa_light_texel(param);\n    return ivec2(int(_644.x), int(_644.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2441 = fa_cluster_lookup(param);\n    fa_cl_slot = _2441.x;\n    fa_cl_local = _2441.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2599 = fa_linear_to_srgb(param);\n        c = _2599;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2607 = fa_srgb_to_linear(param_1);\n            c = _2607;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _247;\n    if (i.front_facing)\n    {\n        _247 = i.world_normal;\n    }\n    else\n    {\n        _247 = -i.world_normal;\n    }\n    vec3 _271 = normalize(i.world_tangent.xyz - (_247 * dot(_247, i.world_tangent.xyz)));\n    vec3 _299 = normalize(((_271 * m.x) + ((cross(_247, _271) * i.world_tangent.w) * m.y)) + (_247 * m.z));\n    vec3 _302;\n    if (i.front_facing)\n    {\n        _302 = _299;\n    }\n    else\n    {\n        _302 = -_299;\n    }\n    return _302;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2638 = fa_tex_fix(param_2, param_3);\n    vec4 _3853 = base_t;\n    _3853.x = _2638.x;\n    _3853.y = _2638.y;\n    _3853.z = _2638.z;\n    base_t = _3853;\n    vec4 _2652 = (_3853 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3787 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2684 = fa_tex_fix(param_6, param_7);\n        vec3 _2687 = (_2684 * 2.0) - vec3(1.0);\n        vec2 _2692 = _2687.xy * fa_mesh_fs_params[6].x;\n        vec3 _3861 = _2687;\n        _3861.x = _2692.x;\n        _3861.y = _2692.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3861;\n        _3787 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2721 = fa_tex_fix(param_12, param_13);\n    vec4 _3864 = mrt;\n    _3864.x = _2721.x;\n    _3864.y = _2721.y;\n    _3864.z = _2721.z;\n    mrt = _3864;\n    vec4 _2749 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2749.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2761 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2791 = fa_tex_fix(param_20, param_21);\n    float _3792 = fa_mesh_fs_params[20].x;\n    float _3793 = fa_mesh_fs_params[20].y;\n    float _3796 = fa_mesh_fs_params[20].z;\n    float _3795 = fa_mesh_fs_params[21].w;\n    float _3798 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3792 *= _2761.y;\n            _3793 *= _2761.z;\n            _3795 *= _2749.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3796 *= mrt.x;\n            _3798 *= mrt.w;\n        }\n    }\n    return Surface(_2652.xyz, _2652.w, _3787, clamp(fa_mesh_fs_params[5].x * _2721.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2721.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2761.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2791), _3792, _3793, fa_mesh_fs_params[21].xyz, _3795, _3796, fa_mesh_fs_params[20].w, _3798, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1547 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1555 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1558 = int(_1547);\n    int _1561 = int(_1555);\n    float _1571 = _1555 - float(_1561);\n    int _1627 = (_1558 * 9) + _1561;\n    int _1647 = ((_1558 + 1) * 9) + _1561;\n    return mix(mix(_1622[_1627], _1622[_1627 + 1], _1571), mix(_1622[_1647], _1622[_1647 + 1], _1571), _1547 - float(_1558));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3710 = false;\n    float _3711 = 1.0;\n    float _3712 = 1.0;\n    float _3713 = 1.0;\n    float _3714 = 0.0;\n    float _3715 = 0.0;\n    float _3716 = 0.0;\n    float _3717 = 0.0;\n    float _3719 = 1.0;\n    bool _3720 = false;\n    vec3 _3721 = vec3(0.0);\n    float _3722 = 1.0;\n    float _3723 = 1.0;\n    float _3724 = 1.0;\n    float _3725 = 0.0;\n    float _3726 = 0.0;\n    vec3 _3727 = vec3(1.0, 0.0, 0.0);\n    vec3 _3728 = vec3(0.0, 0.0, 1.0);\n    float _3729 = 1.0;\n    float _3730 = 1.0;\n    float _1702 = clamp(s.specular, 0.0, 1.0);\n    float _1706 = clamp(s.ior, 1.0, 3.0);\n    bool _1711 = (_1702 != 1.0) || (_1706 != 1.5);\n    bool _1721;\n    if (!_1711)\n    {\n        _1721 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1721 = _1711;\n    }\n    if (_1721)\n    {\n        float _1729 = (_1706 - 1.0) / (_1706 + 1.0);\n        f0 = mix(min(vec3(_1729 * _1729) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1702, s.albedo, vec3(metallic));\n        _3711 = mix(_1702, 1.0, metallic);\n        _3710 = true;\n    }\n    float _1757 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1757 > 0.0)\n    {\n        float _1765 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3714 = _1757;\n        _3715 = _1765;\n        float _1772 = _1765 * _1765;\n        _3716 = _1772;\n        _3717 = _1772 * _1772;\n        float _1784 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3719 = _1784;\n        _3712 = 1.0 - (_1757 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1784, 0.0, 1.0), 5.0))));\n        _3710 = true;\n    }\n    vec3 _1804 = max(s.sheen_color, vec3(0.0));\n    float _1813 = max(_1804.x, max(_1804.y, _1804.z));\n    if (_1813 > 0.0)\n    {\n        float _1821 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3720 = true;\n        _3721 = _1804;\n        _3722 = _1821;\n        _3723 = _1821 * _1821;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1821;\n        float _1838 = fa_sheen_albedo(param, param_1);\n        _3725 = _1838;\n        _3724 = 1.0 - min(_1813 * _1838, 1.0);\n        _3710 = true;\n    }\n    _3713 = _3712 * _3724;\n    float _1857 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1857 != 0.0)\n    {\n        vec3 _1872 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1872;\n        if (dot(_1872, _1872) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1886 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1886.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1886.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1886.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1890 = t;\n        vec3 _1891 = normalize(_1890);\n        t = _1891;\n        vec3 _1916 = normalize((_1891 * cos(s.anisotropy_rotation)) + ((cross(n, _1891) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3727 = _1916;\n        _3728 = cross(n, _1916);\n        float _1926 = roughness * roughness;\n        float _1932 = mix(_1926, 1.0, _1857 * _1857);\n        bool _1934 = _1857 > 0.0;\n        _3729 = _1934 ? _1932 : _1926;\n        _3730 = _1934 ? _1926 : _1932;\n        _3726 = _1857;\n        _3710 = true;\n    }\n    return FaLayers(_3710, _3711, _3712, _3713, _3714, _3715, _3716, _3717, i.world_normal, _3719, _3720, _3721, _3722, _3723, _3724, _3725, _3726, _3727, _3728, _3729, _3730);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _366 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _372 = fa_light_texel(param_1);\n    float _375 = _372.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _381 = _375 < 0.5;\n    vec3 l;\n    if (_381)\n    {\n        l = normalize(_366.xyz);\n    }\n    else\n    {\n        vec3 _393 = _366.xyz - world_pos;\n        float _395 = length(_393);\n        dist = _395;\n        l = _393 / vec3(max(_395, 9.9999997473787516355514526367188e-05));\n        float _410 = _395 / max(_366.w, 0.001000000047497451305389404296875);\n        float _416 = clamp(1.0 - (_410 * _410), 0.0, 1.0);\n        atten = _416 * _416;\n        if (_375 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _430 = fa_light_texel(param_2);\n            float _440 = _430.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _446 = fa_light_texel(param_3);\n            float _447 = _446.x;\n            float cos_inner = _447;\n            if (_447 > 1.5)\n            {\n                cos_inner = mix(_440, 1.0, 0.25);\n            }\n            atten *= smoothstep(_440, cos_inner, dot(-l, normalize(_430.xyz)));\n        }\n    }\n    int _478;\n    if (_381)\n    {\n        _478 = 0;\n    }\n    else\n    {\n        _478 = (_375 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _372.xyz * atten, atten, 1.0, dist, _478);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _718;\n    if (i == 0)\n    {\n        _718 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _734;\n        if (i == 1)\n        {\n            _734 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _742;\n            if (i == 2)\n            {\n                _742 = fa_shadows[24].z;\n            }\n            else\n            {\n                _742 = fa_shadows[24].w;\n            }\n            _734 = _742;\n        }\n        _718 = _734;\n    }\n    return _718;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _706 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_706), sin(_706)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _780 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _785 = clamp(dot(n, l), 0.0, 1.0);\n    float _791 = sqrt(1.0 - (_785 * _785));\n    float _799 = min(_791 / max(_785, 0.20000000298023223876953125), 4.0);\n    float _804;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _804 = fa_shadows[26].y;\n    }\n    else\n    {\n        _804 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _829 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_804 * _791)), 1.0);\n    float _836 = _829.x;\n    bool _839 = _836 < fa_shadows[ci * 1 + 16].x;\n    bool _848;\n    if (!_839)\n    {\n        _848 = _836 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _848 = _839;\n    }\n    bool _857;\n    if (!_848)\n    {\n        _857 = _829.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _857 = _848;\n    }\n    bool _866;\n    if (!_857)\n    {\n        _866 = _829.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _866 = _857;\n    }\n    bool _873;\n    if (!_866)\n    {\n        _873 = _829.z > 1.0;\n    }\n    else\n    {\n        _873 = _866;\n    }\n    if (_873)\n    {\n        return -1.0;\n    }\n    float _882;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _882 = fa_shadows[26].x;\n    }\n    else\n    {\n        _882 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _901 = _829.z - ((_882 * (1.0 + (0.5 * _799))) / _780);\n    float _910 = ((fa_shadows[ci * 1 + 20].x * min(_799, 3.0)) * 0.5) / _780;\n    int _919 = int(fa_shadows[25].z + 0.5);\n    if (_919 == 1)\n    {\n        vec2 param = _829.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _930 = fa_shadow_depth(param, param_1);\n        return float(_901 <= _930);\n    }\n    float _937 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _940 = _919 == 2;\n    if (_940)\n    {\n        float _954 = clamp(((fa_shadows[25].w * _780) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _937;\n            vec2 _973 = fa_shadow_vogel(param_2, param_3, param_4) * _954;\n            vec2 param_5 = _829.xy + (_973 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _984 = fa_shadow_depth(param_5, param_6);\n            if (_984 < (_901 - (length(_973) * _910)))\n            {\n                sum += _984;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_901 - (sum / cnt), 0.0) * _780) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1028 = _940 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1028; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1028;\n        float param_9 = _937;\n        vec2 _1047 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _829.xy + (_1047 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1058 = fa_shadow_depth(param_10, param_11);\n        lit += float((_901 - (length(_1047) * _910)) <= _1058);\n    }\n    return lit / float(_1028);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1088 = int(fa_shadows[25].x + 0.5);\n    if (_1088 < 1)\n    {\n        return 1.0;\n    }\n    float _1104 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1088 - 1;\n    if (_1104 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1116 = _1088 > 1;\n    bool _1123;\n    if (_1116)\n    {\n        _1123 = _1104 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1123 = _1116;\n    }\n    if (_1123)\n    {\n        ci = 1;\n    }\n    bool _1127 = _1088 > 2;\n    bool _1134;\n    if (_1127)\n    {\n        _1134 = _1104 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1134 = _1127;\n    }\n    if (_1134)\n    {\n        ci = 2;\n    }\n    bool _1138 = _1088 > 3;\n    bool _1145;\n    if (_1138)\n    {\n        _1145 = _1104 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1145 = _1138;\n    }\n    if (_1145)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1088)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1171 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1171;\n        if (_1171 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1196;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1196 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1196 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1215 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1196, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1226 = clamp((_1104 - (fa_shadow_split_at(param_7) - _1215)) / _1215, 0.0, 1.0);\n        if (_1226 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1088)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1247 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1247;\n                if (_1247 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1226);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2468 = fa_lm.z > 0.5;\n    bool _2474;\n    if (_2468)\n    {\n        int param = li;\n        _2474 = fa_light_baked(param);\n    }\n    else\n    {\n        _2474 = _2468;\n    }\n    if (_2474)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2496 = fa_light_sample(param_2, param_3);\n    vec3 _3772 = _2496.direction;\n    vec3 _3767 = _2496.color;\n    float _3769 = _2496.shadow;\n    int _3777 = _2496.type;\n    if ((_3777 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3772;\n        float _2510 = fa_shadow_factor(param_4, param_5);\n        _3769 = _2510;\n        _3767 *= _2510;\n    }\n    return LightSample(_3772, _3767, _2496.attenuation, _3769, _2496._distance, _3777);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2084 = tdh / at;\n    float _2088 = bdh / ab;\n    float _2100 = ((_2084 * _2084) + (_2088 * _2088)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2100) * _2100);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2181 = 1.0 / alpha;\n    return ((2.0 + _2181) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2181)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2214 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2293 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2293) * _2293);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2214);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2214));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2366 = max(dot(L.nc, l), 0.0);\n        float _2372 = max(dot(L.nc, h), 0.0);\n        float _2381 = ((_2372 * _2372) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2381) * _2381)) * (0.5 / max(mix((2.0 * _2366) * L.coat_ndv, _2366 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2366)) * _2366);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1479 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1482 = _1479.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1482 * _1482, exp2((-9.27999973297119140625) * ndv)) * _1482) + _1479.y)) + _1479.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1384 = rough * rough;\n    float _1414 = 0.60000002384185791015625 * _1384;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1384)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1414, 0.0500000007450580596923828125 + _1414, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1384 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1967;\n        if (L.aniso >= 0.0)\n        {\n            _1967 = L.b;\n        }\n        else\n        {\n            _1967 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1967, v), _1967), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2000 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2000.x) + (vec3(L.f90) * _2000.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2055 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2055.x) + _2055.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1521 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1521.x) + vec3(_1521.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1271 = int(fa_shadows[25].x + 0.5);\n    float _1281 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1286 = _1271 > 0;\n    bool _1295;\n    if (_1286)\n    {\n        int param = _1271 - 1;\n        _1295 = _1281 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1295 = _1286;\n    }\n    if (_1295)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1302 = _1271 > 1;\n        bool _1309;\n        if (_1302)\n        {\n            _1309 = _1281 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1309 = _1302;\n        }\n        if (_1309)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1315 = _1271 > 2;\n        bool _1322;\n        if (_1315)\n        {\n            _1322 = _1281 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1322 = _1315;\n        }\n        if (_1322)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1328 = _1271 > 3;\n        bool _1335;\n        if (_1328)\n        {\n            _1335 = _1281 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1335 = _1328;\n        }\n        if (_1335)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3489 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3489 = -_3489;\n    }\n    vec3 _2931 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3489, fa_world_tangent, fa_uv, fa_vertex_color, _2931, gl_FrontFacing);\n    Surface _2939 = fa_standard_surface(param_1);\n    vec3 _3520 = _2939.albedo;\n    float _3521 = _2939.alpha;\n    vec3 _3522 = _2939.normal;\n    float _3523 = _2939.metallic;\n    float _3524 = _2939.roughness;\n    float _3525 = _2939.occlusion;\n    vec3 _3526 = _2939.emission;\n    float _3527 = _2939.clearcoat;\n    float _3528 = _2939.clearcoat_roughness;\n    vec3 _3529 = _2939.sheen_color;\n    float _3530 = _2939.sheen_roughness;\n    float _3531 = _2939.anisotropy;\n    float _3532 = _2939.anisotropy_rotation;\n    float _3533 = _2939.specular;\n    float _3534 = _2939.ior;\n    vec3 _3535 = _2939.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3489, fa_world_tangent, fa_uv, fa_vertex_color, _2931, gl_FrontFacing);\n    Surface param_3 = _2939;\n    surface(param_2, param_3);\n    _3520 = param_3.albedo;\n    _3521 = param_3.alpha;\n    _3522 = param_3.normal;\n    _3523 = param_3.metallic;\n    _3524 = param_3.roughness;\n    _3525 = param_3.occlusion;\n    _3526 = param_3.emission;\n    _3527 = param_3.clearcoat;\n    _3528 = param_3.clearcoat_roughness;\n    _3529 = param_3.sheen_color;\n    _3530 = param_3.sheen_roughness;\n    _3531 = param_3.anisotropy;\n    _3532 = param_3.anisotropy_rotation;\n    _3533 = param_3.specular;\n    _3534 = param_3.ior;\n    _3535 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3520;\n    }\n    else\n    {\n        vec3 _2961 = normalize(_3522);\n        float _2968 = clamp(_3523, 0.0, 1.0);\n        float _2972 = clamp(_3524, 0.0500000007450580596923828125, 1.0);\n        float _2976 = _2972 * _2972;\n        float _2980 = _2976 * _2976;\n        float _2985 = max(dot(_2961, _2931), 9.9999997473787516355514526367188e-05);\n        vec3 _2991 = _3520 * (1.0 - _2968);\n        vec3 _2998 = mix(vec3(0.039999999105930328369140625), _3520, vec3(_2968));\n        vec3 f0 = _2998;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3489, fa_world_tangent, fa_uv, fa_vertex_color, _2931, gl_FrontFacing);\n        Surface param_5 = Surface(_3520, _3521, _3522, _3523, _3524, _3525, _3526, _3527, _3528, _3529, _3530, _3531, _3532, _3533, _3534, _3535);\n        vec3 param_6 = _2961;\n        vec3 param_7 = _2931;\n        float param_8 = _2968;\n        float param_9 = _2972;\n        vec3 param_10 = _2998;\n        FaLayers _3014 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _2961;\n        vec3 lit = (fa_indirect_diffuse(param_11) * _2991) * _3525;\n        if (_3014.on)\n        {\n            lit *= _3014.base_scale;\n        }\n        int _3036 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3036; ln++)\n        {\n            int param_12 = ln;\n            int _3049 = fa_cl_light(param_12);\n            bool _3052 = fa_lm.z > 0.5;\n            bool _3058;\n            if (_3052)\n            {\n                int param_13 = _3049;\n                _3058 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3058 = _3052;\n            }\n            if (_3058)\n            {\n                continue;\n            }\n            int param_14 = _3049;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3489;\n            LightSample _3070 = fa_light_shadowed(param_14, param_15, param_16);\n            vec3 _3694 = _3070.direction;\n            float _3078 = max(dot(_2961, _3694), 0.0);\n            float _3084 = _3070.attenuation * _3070.shadow;\n            vec3 _3089 = normalize(_3694 + _2931);\n            float _3094 = max(dot(_2961, _3089), 0.0);\n            float _3099 = max(dot(_2931, _3089), 0.0);\n            if (_3014.on)\n            {\n                FaLayers param_17 = _3014;\n                vec3 param_18 = _2991;\n                vec3 param_19 = f0;\n                vec3 param_20 = _2961;\n                vec3 param_21 = _2931;\n                vec3 param_22 = _3694;\n                vec3 param_23 = _3089;\n                float param_24 = _3078;\n                float param_25 = _2985;\n                float param_26 = _3094;\n                float param_27 = _3099;\n                float param_28 = _2976;\n                float param_29 = _2980;\n                int param_30 = _3049;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3084));\n            }\n            else\n            {\n                float _3147 = ((_3094 * _3094) * (_2980 - 1.0)) + 1.0;\n                int param_31 = _3049;\n                lit += (((_2991 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3099, 5.0))) * (((_2980 / ((3.1415927410125732421875 * _3147) * _3147)) * (0.5 / max(mix((2.0 * _3078) * _2985, _3078 + _2985, _2976), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3078))) * fa_light_rgb(param_31)) * (_3078 * _3084));\n            }\n        }\n        if (_3014.on)\n        {\n            FaLayers param_32 = _3014;\n            vec3 param_33 = _2961;\n            vec3 param_34 = _2931;\n            vec3 param_35 = f0;\n            float param_36 = _2972;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3525);\n        }\n        else\n        {\n            vec3 param_37 = _2961;\n            vec3 param_38 = _2931;\n            vec3 param_39 = f0;\n            float param_40 = _2972;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3525);\n        }\n        result = lit;\n    }\n    vec3 _3240 = result;\n    vec3 _3241 = _3240 + _3526;\n    result = _3241;\n    vec3 param_41 = _3241;\n    vec3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3250 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3257;\n    if (!_3250)\n    {\n        _3257 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3257 = _3250;\n    }\n    if (_3257)\n    {\n        vec3 _3266 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3272 = dot(_3266, fa_mesh_fs_params[9].xyz);\n        bool _3276 = fa_mesh_fs_params[9].w > 0.5;\n        float _3277;\n        if (_3276)\n        {\n            _3277 = _3272;\n        }\n        else\n        {\n            _3277 = length(_3266);\n        }\n        float _3289 = _3277 - fa_mesh_fs_params[8].x;\n        if (_3289 > 0.0)\n        {\n            float _3298 = fa_mesh_fs_params[7].w * _3289;\n            float tau = _3298 * _3298;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3314;\n                if (_3276)\n                {\n                    _3314 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3272);\n                }\n                else\n                {\n                    _3314 = fa_mesh_fs_params[0].y;\n                }\n                float _3335 = mix(_3314, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3277, 0.0, 1.0));\n                float _3339 = fa_world_pos.y - _3335;\n                float _3344 = _3335 - fa_mesh_fs_params[8].z;\n                float _3349 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3352 = _3344 <= 0.0;\n                bool _3353 = !_3352;\n                bool _3359;\n                if (_3353)\n                {\n                    _3359 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3359 = _3352;\n                }\n                float _3360;\n                if (_3359)\n                {\n                    _3360 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3360 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3344, 80.0));\n                }\n                bool _3387;\n                if (_3353)\n                {\n                    _3387 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3387 = _3352;\n                }\n                float _3388;\n                if (_3387)\n                {\n                    _3388 = fa_mesh_fs_params[8].y * _3344;\n                }\n                else\n                {\n                    _3388 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3344, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3413 = _3349 <= 0.0;\n                bool _3420;\n                if (!_3413)\n                {\n                    _3420 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3420 = _3413;\n                }\n                float _3421;\n                if (_3420)\n                {\n                    _3421 = fa_mesh_fs_params[8].y * _3349;\n                }\n                else\n                {\n                    _3421 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3349, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3448;\n                if (abs(_3339) < 0.001000000047497451305389404296875)\n                {\n                    _3448 = _3360;\n                }\n                else\n                {\n                    _3448 = (_3421 - _3388) / _3339;\n                }\n                tau += (_3289 * max(_3448, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3521);\n}\n\n",
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
            "inst_name": "_492",
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
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_728",
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
            "inst_name": "_2535",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1622[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _497 = fa_mesh_fs_params[19].x < 0.0;\n    bool _504;\n    if (!_497)\n    {\n        _504 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _504 = _497;\n    }\n    bool _512;\n    if (!_504)\n    {\n        _512 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _512 = _504;\n    }\n    bool _519;\n    if (!_512)\n    {\n        _519 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _519 = _512;\n    }\n    bool _526;\n    if (!_519)\n    {\n        _526 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _526 = _519;\n    }\n    if (_526)\n    {\n        return ivec2(0);\n    }\n    vec4 _536 = vec4(world_pos, 1.0);\n    float _543 = dot(fa_mesh_fs_params[16], _536);\n    if (!(_543 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _565 = vec2(dot(fa_mesh_fs_params[14], _536), dot(fa_mesh_fs_params[15], _536)) / vec2(_543);\n    int _569 = int(fa_mesh_fs_params[18].x);\n    int _573 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _573) + clamp(int(floor(((_565.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _573 - 1)) * _569)) + clamp(int(floor(((_565.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _569 - 1);\n    vec4 _644 = fa_light_texel(param);\n    return ivec2(int(_644.x), int(_644.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2441 = fa_cluster_lookup(param);\n    fa_cl_slot = _2441.x;\n    fa_cl_local = _2441.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2599 = fa_linear_to_srgb(param);\n        c = _2599;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2607 = fa_srgb_to_linear(param_1);\n            c = _2607;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _247;\n    if (i.front_facing)\n    {\n        _247 = i.world_normal;\n    }\n    else\n    {\n        _247 = -i.world_normal;\n    }\n    vec3 _271 = normalize(i.world_tangent.xyz - (_247 * dot(_247, i.world_tangent.xyz)));\n    vec3 _299 = normalize(((_271 * m.x) + ((cross(_247, _271) * i.world_tangent.w) * m.y)) + (_247 * m.z));\n    vec3 _302;\n    if (i.front_facing)\n    {\n        _302 = _299;\n    }\n    else\n    {\n        _302 = -_299;\n    }\n    return _302;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2638 = fa_tex_fix(param_2, param_3);\n    vec4 _3853 = base_t;\n    _3853.x = _2638.x;\n    _3853.y = _2638.y;\n    _3853.z = _2638.z;\n    base_t = _3853;\n    vec4 _2652 = (_3853 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3787 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2684 = fa_tex_fix(param_6, param_7);\n        vec3 _2687 = (_2684 * 2.0) - vec3(1.0);\n        vec2 _2692 = _2687.xy * fa_mesh_fs_params[6].x;\n        vec3 _3861 = _2687;\n        _3861.x = _2692.x;\n        _3861.y = _2692.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3861;\n        _3787 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2721 = fa_tex_fix(param_12, param_13);\n    vec4 _3864 = mrt;\n    _3864.x = _2721.x;\n    _3864.y = _2721.y;\n    _3864.z = _2721.z;\n    mrt = _3864;\n    vec4 _2749 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2749.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2761 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2791 = fa_tex_fix(param_20, param_21);\n    float _3792 = fa_mesh_fs_params[20].x;\n    float _3793 = fa_mesh_fs_params[20].y;\n    float _3796 = fa_mesh_fs_params[20].z;\n    float _3795 = fa_mesh_fs_params[21].w;\n    float _3798 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3792 *= _2761.y;\n            _3793 *= _2761.z;\n            _3795 *= _2749.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3796 *= mrt.x;\n            _3798 *= mrt.w;\n        }\n    }\n    return Surface(_2652.xyz, _2652.w, _3787, clamp(fa_mesh_fs_params[5].x * _2721.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2721.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2761.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2791), _3792, _3793, fa_mesh_fs_params[21].xyz, _3795, _3796, fa_mesh_fs_params[20].w, _3798, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1547 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1555 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1558 = int(_1547);\n    int _1561 = int(_1555);\n    float _1571 = _1555 - float(_1561);\n    int _1627 = (_1558 * 9) + _1561;\n    int _1647 = ((_1558 + 1) * 9) + _1561;\n    return mix(mix(_1622[_1627], _1622[_1627 + 1], _1571), mix(_1622[_1647], _1622[_1647 + 1], _1571), _1547 - float(_1558));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3710 = false;\n    float _3711 = 1.0;\n    float _3712 = 1.0;\n    float _3713 = 1.0;\n    float _3714 = 0.0;\n    float _3715 = 0.0;\n    float _3716 = 0.0;\n    float _3717 = 0.0;\n    float _3719 = 1.0;\n    bool _3720 = false;\n    vec3 _3721 = vec3(0.0);\n    float _3722 = 1.0;\n    float _3723 = 1.0;\n    float _3724 = 1.0;\n    float _3725 = 0.0;\n    float _3726 = 0.0;\n    vec3 _3727 = vec3(1.0, 0.0, 0.0);\n    vec3 _3728 = vec3(0.0, 0.0, 1.0);\n    float _3729 = 1.0;\n    float _3730 = 1.0;\n    float _1702 = clamp(s.specular, 0.0, 1.0);\n    float _1706 = clamp(s.ior, 1.0, 3.0);\n    bool _1711 = (_1702 != 1.0) || (_1706 != 1.5);\n    bool _1721;\n    if (!_1711)\n    {\n        _1721 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1721 = _1711;\n    }\n    if (_1721)\n    {\n        float _1729 = (_1706 - 1.0) / (_1706 + 1.0);\n        f0 = mix(min(vec3(_1729 * _1729) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1702, s.albedo, vec3(metallic));\n        _3711 = mix(_1702, 1.0, metallic);\n        _3710 = true;\n    }\n    float _1757 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1757 > 0.0)\n    {\n        float _1765 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3714 = _1757;\n        _3715 = _1765;\n        float _1772 = _1765 * _1765;\n        _3716 = _1772;\n        _3717 = _1772 * _1772;\n        float _1784 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3719 = _1784;\n        _3712 = 1.0 - (_1757 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1784, 0.0, 1.0), 5.0))));\n        _3710 = true;\n    }\n    vec3 _1804 = max(s.sheen_color, vec3(0.0));\n    float _1813 = max(_1804.x, max(_1804.y, _1804.z));\n    if (_1813 > 0.0)\n    {\n        float _1821 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3720 = true;\n        _3721 = _1804;\n        _3722 = _1821;\n        _3723 = _1821 * _1821;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1821;\n        float _1838 = fa_sheen_albedo(param, param_1);\n        _3725 = _1838;\n        _3724 = 1.0 - min(_1813 * _1838, 1.0);\n        _3710 = true;\n    }\n    _3713 = _3712 * _3724;\n    float _1857 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1857 != 0.0)\n    {\n        vec3 _1872 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1872;\n        if (dot(_1872, _1872) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1886 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1886.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1886.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1886.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1890 = t;\n        vec3 _1891 = normalize(_1890);\n        t = _1891;\n        vec3 _1916 = normalize((_1891 * cos(s.anisotropy_rotation)) + ((cross(n, _1891) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3727 = _1916;\n        _3728 = cross(n, _1916);\n        float _1926 = roughness * roughness;\n        float _1932 = mix(_1926, 1.0, _1857 * _1857);\n        bool _1934 = _1857 > 0.0;\n        _3729 = _1934 ? _1932 : _1926;\n        _3730 = _1934 ? _1926 : _1932;\n        _3726 = _1857;\n        _3710 = true;\n    }\n    return FaLayers(_3710, _3711, _3712, _3713, _3714, _3715, _3716, _3717, i.world_normal, _3719, _3720, _3721, _3722, _3723, _3724, _3725, _3726, _3727, _3728, _3729, _3730);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _366 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _372 = fa_light_texel(param_1);\n    float _375 = _372.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _381 = _375 < 0.5;\n    vec3 l;\n    if (_381)\n    {\n        l = normalize(_366.xyz);\n    }\n    else\n    {\n        vec3 _393 = _366.xyz - world_pos;\n        float _395 = length(_393);\n        dist = _395;\n        l = _393 / vec3(max(_395, 9.9999997473787516355514526367188e-05));\n        float _410 = _395 / max(_366.w, 0.001000000047497451305389404296875);\n        float _416 = clamp(1.0 - (_410 * _410), 0.0, 1.0);\n        atten = _416 * _416;\n        if (_375 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _430 = fa_light_texel(param_2);\n            float _440 = _430.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _446 = fa_light_texel(param_3);\n            float _447 = _446.x;\n            float cos_inner = _447;\n            if (_447 > 1.5)\n            {\n                cos_inner = mix(_440, 1.0, 0.25);\n            }\n            atten *= smoothstep(_440, cos_inner, dot(-l, normalize(_430.xyz)));\n        }\n    }\n    int _478;\n    if (_381)\n    {\n        _478 = 0;\n    }\n    else\n    {\n        _478 = (_375 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _372.xyz * atten, atten, 1.0, dist, _478);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _718;\n    if (i == 0)\n    {\n        _718 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _734;\n        if (i == 1)\n        {\n            _734 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _742;\n            if (i == 2)\n            {\n                _742 = fa_shadows[24].z;\n            }\n            else\n            {\n                _742 = fa_shadows[24].w;\n            }\n            _734 = _742;\n        }\n        _718 = _734;\n    }\n    return _718;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _706 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_706), sin(_706)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _780 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _785 = clamp(dot(n, l), 0.0, 1.0);\n    float _791 = sqrt(1.0 - (_785 * _785));\n    float _799 = min(_791 / max(_785, 0.20000000298023223876953125), 4.0);\n    float _804;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _804 = fa_shadows[26].y;\n    }\n    else\n    {\n        _804 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _829 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_804 * _791)), 1.0);\n    float _836 = _829.x;\n    bool _839 = _836 < fa_shadows[ci * 1 + 16].x;\n    bool _848;\n    if (!_839)\n    {\n        _848 = _836 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _848 = _839;\n    }\n    bool _857;\n    if (!_848)\n    {\n        _857 = _829.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _857 = _848;\n    }\n    bool _866;\n    if (!_857)\n    {\n        _866 = _829.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _866 = _857;\n    }\n    bool _873;\n    if (!_866)\n    {\n        _873 = _829.z > 1.0;\n    }\n    else\n    {\n        _873 = _866;\n    }\n    if (_873)\n    {\n        return -1.0;\n    }\n    float _882;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _882 = fa_shadows[26].x;\n    }\n    else\n    {\n        _882 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _901 = _829.z - ((_882 * (1.0 + (0.5 * _799))) / _780);\n    float _910 = ((fa_shadows[ci * 1 + 20].x * min(_799, 3.0)) * 0.5) / _780;\n    int _919 = int(fa_shadows[25].z + 0.5);\n    if (_919 == 1)\n    {\n        vec2 param = _829.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _930 = fa_shadow_depth(param, param_1);\n        return float(_901 <= _930);\n    }\n    float _937 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _940 = _919 == 2;\n    if (_940)\n    {\n        float _954 = clamp(((fa_shadows[25].w * _780) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _937;\n            vec2 _973 = fa_shadow_vogel(param_2, param_3, param_4) * _954;\n            vec2 param_5 = _829.xy + (_973 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _984 = fa_shadow_depth(param_5, param_6);\n            if (_984 < (_901 - (length(_973) * _910)))\n            {\n                sum += _984;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_901 - (sum / cnt), 0.0) * _780) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1028 = _940 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1028; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1028;\n        float param_9 = _937;\n        vec2 _1047 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _829.xy + (_1047 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1058 = fa_shadow_depth(param_10, param_11);\n        lit += float((_901 - (length(_1047) * _910)) <= _1058);\n    }\n    return lit / float(_1028);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1088 = int(fa_shadows[25].x + 0.5);\n    if (_1088 < 1)\n    {\n        return 1.0;\n    }\n    float _1104 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1088 - 1;\n    if (_1104 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1116 = _1088 > 1;\n    bool _1123;\n    if (_1116)\n    {\n        _1123 = _1104 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1123 = _1116;\n    }\n    if (_1123)\n    {\n        ci = 1;\n    }\n    bool _1127 = _1088 > 2;\n    bool _1134;\n    if (_1127)\n    {\n        _1134 = _1104 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1134 = _1127;\n    }\n    if (_1134)\n    {\n        ci = 2;\n    }\n    bool _1138 = _1088 > 3;\n    bool _1145;\n    if (_1138)\n    {\n        _1145 = _1104 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1145 = _1138;\n    }\n    if (_1145)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1088)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1171 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1171;\n        if (_1171 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1196;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1196 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1196 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1215 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1196, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1226 = clamp((_1104 - (fa_shadow_split_at(param_7) - _1215)) / _1215, 0.0, 1.0);\n        if (_1226 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1088)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1247 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1247;\n                if (_1247 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1226);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2468 = fa_lm.z > 0.5;\n    bool _2474;\n    if (_2468)\n    {\n        int param = li;\n        _2474 = fa_light_baked(param);\n    }\n    else\n    {\n        _2474 = _2468;\n    }\n    if (_2474)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2496 = fa_light_sample(param_2, param_3);\n    vec3 _3772 = _2496.direction;\n    vec3 _3767 = _2496.color;\n    float _3769 = _2496.shadow;\n    int _3777 = _2496.type;\n    if ((_3777 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3772;\n        float _2510 = fa_shadow_factor(param_4, param_5);\n        _3769 = _2510;\n        _3767 *= _2510;\n    }\n    return LightSample(_3772, _3767, _2496.attenuation, _3769, _2496._distance, _3777);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2084 = tdh / at;\n    float _2088 = bdh / ab;\n    float _2100 = ((_2084 * _2084) + (_2088 * _2088)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2100) * _2100);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2181 = 1.0 / alpha;\n    return ((2.0 + _2181) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2181)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2214 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2293 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2293) * _2293);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2214);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2214));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2366 = max(dot(L.nc, l), 0.0);\n        float _2372 = max(dot(L.nc, h), 0.0);\n        float _2381 = ((_2372 * _2372) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2381) * _2381)) * (0.5 / max(mix((2.0 * _2366) * L.coat_ndv, _2366 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2366)) * _2366);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1479 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1482 = _1479.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1482 * _1482, exp2((-9.27999973297119140625) * ndv)) * _1482) + _1479.y)) + _1479.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1384 = rough * rough;\n    float _1414 = 0.60000002384185791015625 * _1384;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1384)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1414, 0.0500000007450580596923828125 + _1414, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1384 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1967;\n        if (L.aniso >= 0.0)\n        {\n            _1967 = L.b;\n        }\n        else\n        {\n            _1967 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1967, v), _1967), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2000 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2000.x) + (vec3(L.f90) * _2000.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2055 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2055.x) + _2055.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1521 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1521.x) + vec3(_1521.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1271 = int(fa_shadows[25].x + 0.5);\n    float _1281 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1286 = _1271 > 0;\n    bool _1295;\n    if (_1286)\n    {\n        int param = _1271 - 1;\n        _1295 = _1281 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1295 = _1286;\n    }\n    if (_1295)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1302 = _1271 > 1;\n        bool _1309;\n        if (_1302)\n        {\n            _1309 = _1281 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1309 = _1302;\n        }\n        if (_1309)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1315 = _1271 > 2;\n        bool _1322;\n        if (_1315)\n        {\n            _1322 = _1281 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1322 = _1315;\n        }\n        if (_1322)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1328 = _1271 > 3;\n        bool _1335;\n        if (_1328)\n        {\n            _1335 = _1281 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1335 = _1328;\n        }\n        if (_1335)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3489 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3489 = -_3489;\n    }\n    vec3 _2931 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3489, fa_world_tangent, fa_uv, fa_vertex_color, _2931, gl_FrontFacing);\n    Surface _2939 = fa_standard_surface(param_1);\n    vec3 _3520 = _2939.albedo;\n    float _3521 = _2939.alpha;\n    vec3 _3522 = _2939.normal;\n    float _3523 = _2939.metallic;\n    float _3524 = _2939.roughness;\n    float _3525 = _2939.occlusion;\n    vec3 _3526 = _2939.emission;\n    float _3527 = _2939.clearcoat;\n    float _3528 = _2939.clearcoat_roughness;\n    vec3 _3529 = _2939.sheen_color;\n    float _3530 = _2939.sheen_roughness;\n    float _3531 = _2939.anisotropy;\n    float _3532 = _2939.anisotropy_rotation;\n    float _3533 = _2939.specular;\n    float _3534 = _2939.ior;\n    vec3 _3535 = _2939.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3489, fa_world_tangent, fa_uv, fa_vertex_color, _2931, gl_FrontFacing);\n    Surface param_3 = _2939;\n    surface(param_2, param_3);\n    _3520 = param_3.albedo;\n    _3521 = param_3.alpha;\n    _3522 = param_3.normal;\n    _3523 = param_3.metallic;\n    _3524 = param_3.roughness;\n    _3525 = param_3.occlusion;\n    _3526 = param_3.emission;\n    _3527 = param_3.clearcoat;\n    _3528 = param_3.clearcoat_roughness;\n    _3529 = param_3.sheen_color;\n    _3530 = param_3.sheen_roughness;\n    _3531 = param_3.anisotropy;\n    _3532 = param_3.anisotropy_rotation;\n    _3533 = param_3.specular;\n    _3534 = param_3.ior;\n    _3535 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3520;\n    }\n    else\n    {\n        vec3 _2961 = normalize(_3522);\n        float _2968 = clamp(_3523, 0.0, 1.0);\n        float _2972 = clamp(_3524, 0.0500000007450580596923828125, 1.0);\n        float _2976 = _2972 * _2972;\n        float _2980 = _2976 * _2976;\n        float _2985 = max(dot(_2961, _2931), 9.9999997473787516355514526367188e-05);\n        vec3 _2991 = _3520 * (1.0 - _2968);\n        vec3 _2998 = mix(vec3(0.039999999105930328369140625), _3520, vec3(_2968));\n        vec3 f0 = _2998;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3489, fa_world_tangent, fa_uv, fa_vertex_color, _2931, gl_FrontFacing);\n        Surface param_5 = Surface(_3520, _3521, _3522, _3523, _3524, _3525, _3526, _3527, _3528, _3529, _3530, _3531, _3532, _3533, _3534, _3535);\n        vec3 param_6 = _2961;\n        vec3 param_7 = _2931;\n        float param_8 = _2968;\n        float param_9 = _2972;\n        vec3 param_10 = _2998;\n        FaLayers _3014 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _2961;\n        vec3 lit = (fa_indirect_diffuse(param_11) * _2991) * _3525;\n        if (_3014.on)\n        {\n            lit *= _3014.base_scale;\n        }\n        int _3036 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3036; ln++)\n        {\n            int param_12 = ln;\n            int _3049 = fa_cl_light(param_12);\n            bool _3052 = fa_lm.z > 0.5;\n            bool _3058;\n            if (_3052)\n            {\n                int param_13 = _3049;\n                _3058 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3058 = _3052;\n            }\n            if (_3058)\n            {\n                continue;\n            }\n            int param_14 = _3049;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3489;\n            LightSample _3070 = fa_light_shadowed(param_14, param_15, param_16);\n            vec3 _3694 = _3070.direction;\n            float _3078 = max(dot(_2961, _3694), 0.0);\n            float _3084 = _3070.attenuation * _3070.shadow;\n            vec3 _3089 = normalize(_3694 + _2931);\n            float _3094 = max(dot(_2961, _3089), 0.0);\n            float _3099 = max(dot(_2931, _3089), 0.0);\n            if (_3014.on)\n            {\n                FaLayers param_17 = _3014;\n                vec3 param_18 = _2991;\n                vec3 param_19 = f0;\n                vec3 param_20 = _2961;\n                vec3 param_21 = _2931;\n                vec3 param_22 = _3694;\n                vec3 param_23 = _3089;\n                float param_24 = _3078;\n                float param_25 = _2985;\n                float param_26 = _3094;\n                float param_27 = _3099;\n                float param_28 = _2976;\n                float param_29 = _2980;\n                int param_30 = _3049;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3084));\n            }\n            else\n            {\n                float _3147 = ((_3094 * _3094) * (_2980 - 1.0)) + 1.0;\n                int param_31 = _3049;\n                lit += (((_2991 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3099, 5.0))) * (((_2980 / ((3.1415927410125732421875 * _3147) * _3147)) * (0.5 / max(mix((2.0 * _3078) * _2985, _3078 + _2985, _2976), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3078))) * fa_light_rgb(param_31)) * (_3078 * _3084));\n            }\n        }\n        if (_3014.on)\n        {\n            FaLayers param_32 = _3014;\n            vec3 param_33 = _2961;\n            vec3 param_34 = _2931;\n            vec3 param_35 = f0;\n            float param_36 = _2972;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3525);\n        }\n        else\n        {\n            vec3 param_37 = _2961;\n            vec3 param_38 = _2931;\n            vec3 param_39 = f0;\n            float param_40 = _2972;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3525);\n        }\n        result = lit;\n    }\n    vec3 _3240 = result;\n    vec3 _3241 = _3240 + _3526;\n    result = _3241;\n    vec3 param_41 = _3241;\n    vec3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3250 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3257;\n    if (!_3250)\n    {\n        _3257 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3257 = _3250;\n    }\n    if (_3257)\n    {\n        vec3 _3266 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3272 = dot(_3266, fa_mesh_fs_params[9].xyz);\n        bool _3276 = fa_mesh_fs_params[9].w > 0.5;\n        float _3277;\n        if (_3276)\n        {\n            _3277 = _3272;\n        }\n        else\n        {\n            _3277 = length(_3266);\n        }\n        float _3289 = _3277 - fa_mesh_fs_params[8].x;\n        if (_3289 > 0.0)\n        {\n            float _3298 = fa_mesh_fs_params[7].w * _3289;\n            float tau = _3298 * _3298;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3314;\n                if (_3276)\n                {\n                    _3314 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3272);\n                }\n                else\n                {\n                    _3314 = fa_mesh_fs_params[0].y;\n                }\n                float _3335 = mix(_3314, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3277, 0.0, 1.0));\n                float _3339 = fa_world_pos.y - _3335;\n                float _3344 = _3335 - fa_mesh_fs_params[8].z;\n                float _3349 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3352 = _3344 <= 0.0;\n                bool _3353 = !_3352;\n                bool _3359;\n                if (_3353)\n                {\n                    _3359 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3359 = _3352;\n                }\n                float _3360;\n                if (_3359)\n                {\n                    _3360 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3360 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3344, 80.0));\n                }\n                bool _3387;\n                if (_3353)\n                {\n                    _3387 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3387 = _3352;\n                }\n                float _3388;\n                if (_3387)\n                {\n                    _3388 = fa_mesh_fs_params[8].y * _3344;\n                }\n                else\n                {\n                    _3388 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3344, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3413 = _3349 <= 0.0;\n                bool _3420;\n                if (!_3413)\n                {\n                    _3420 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3420 = _3413;\n                }\n                float _3421;\n                if (_3420)\n                {\n                    _3421 = fa_mesh_fs_params[8].y * _3349;\n                }\n                else\n                {\n                    _3421 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3349, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3448;\n                if (abs(_3339) < 0.001000000047497451305389404296875)\n                {\n                    _3448 = _3360;\n                }\n                else\n                {\n                    _3448 = (_3421 - _3388) / _3339;\n                }\n                tau += (_3289 * max(_3448, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3521);\n}\n\n",
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
            "inst_name": "_492",
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
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_728",
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
            "inst_name": "_2535",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
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
