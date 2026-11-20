{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1595[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _470 = fa_mesh_fs_params[19].x < 0.0;\n    bool _477;\n    if (!_470)\n    {\n        _477 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    bool _485;\n    if (!_477)\n    {\n        _485 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _485 = _477;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    bool _499;\n    if (!_492)\n    {\n        _499 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _499 = _492;\n    }\n    if (_499)\n    {\n        return ivec2(0);\n    }\n    vec4 _509 = vec4(world_pos, 1.0);\n    float _516 = dot(fa_mesh_fs_params[16], _509);\n    if (!(_516 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _538 = vec2(dot(fa_mesh_fs_params[14], _509), dot(fa_mesh_fs_params[15], _509)) / vec2(_516);\n    int _542 = int(fa_mesh_fs_params[18].x);\n    int _546 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _546) + clamp(int(floor(((_538.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _546 - 1)) * _542)) + clamp(int(floor(((_538.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _542 - 1);\n    vec4 _617 = fa_light_texel(param);\n    return ivec2(int(_617.x), int(_617.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2414 = fa_cluster_lookup(param);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2545 = fa_linear_to_srgb(param);\n        c = _2545;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2553 = fa_srgb_to_linear(param_1);\n            c = _2553;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _237;\n    if (i.front_facing)\n    {\n        _237 = i.world_normal;\n    }\n    else\n    {\n        _237 = -i.world_normal;\n    }\n    vec3 _261 = normalize(i.world_tangent.xyz - (_237 * dot(_237, i.world_tangent.xyz)));\n    vec3 _289 = normalize(((_261 * m.x) + ((cross(_237, _261) * i.world_tangent.w) * m.y)) + (_237 * m.z));\n    vec3 _292;\n    if (i.front_facing)\n    {\n        _292 = _289;\n    }\n    else\n    {\n        _292 = -_289;\n    }\n    return _292;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2584 = fa_tex_fix(param_2, param_3);\n    vec4 _3755 = base_t;\n    _3755.x = _2584.x;\n    _3755.y = _2584.y;\n    _3755.z = _2584.z;\n    base_t = _3755;\n    vec4 _2598 = (_3755 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3689 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2630 = fa_tex_fix(param_6, param_7);\n        vec3 _2633 = (_2630 * 2.0) - vec3(1.0);\n        vec2 _2638 = _2633.xy * fa_mesh_fs_params[6].x;\n        vec3 _3763 = _2633;\n        _3763.x = _2638.x;\n        _3763.y = _2638.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3763;\n        _3689 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2667 = fa_tex_fix(param_12, param_13);\n    vec4 _3766 = mrt;\n    _3766.x = _2667.x;\n    _3766.y = _2667.y;\n    _3766.z = _2667.z;\n    mrt = _3766;\n    vec4 _2695 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2695.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2707 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2737 = fa_tex_fix(param_20, param_21);\n    float _3694 = fa_mesh_fs_params[20].x;\n    float _3695 = fa_mesh_fs_params[20].y;\n    float _3698 = fa_mesh_fs_params[20].z;\n    float _3697 = fa_mesh_fs_params[21].w;\n    float _3700 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3694 *= _2707.y;\n            _3695 *= _2707.z;\n            _3697 *= _2695.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3698 *= mrt.x;\n            _3700 *= mrt.w;\n        }\n    }\n    return Surface(_2598.xyz, _2598.w, _3689, clamp(fa_mesh_fs_params[5].x * _2667.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2667.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2707.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2737), _3694, _3695, fa_mesh_fs_params[21].xyz, _3697, _3698, fa_mesh_fs_params[20].w, _3700, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1520 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1528 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1531 = int(_1520);\n    int _1534 = int(_1528);\n    float _1544 = _1528 - float(_1534);\n    int _1600 = (_1531 * 9) + _1534;\n    int _1620 = ((_1531 + 1) * 9) + _1534;\n    return mix(mix(_1595[_1600], _1595[_1600 + 1], _1544), mix(_1595[_1620], _1595[_1620 + 1], _1544), _1520 - float(_1531));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3625 = false;\n    float _3626 = 1.0;\n    float _3627 = 1.0;\n    float _3628 = 1.0;\n    float _3629 = 0.0;\n    float _3630 = 0.0;\n    float _3631 = 0.0;\n    float _3632 = 0.0;\n    float _3634 = 1.0;\n    bool _3635 = false;\n    vec3 _3636 = vec3(0.0);\n    float _3637 = 1.0;\n    float _3638 = 1.0;\n    float _3639 = 1.0;\n    float _3640 = 0.0;\n    float _3641 = 0.0;\n    vec3 _3642 = vec3(1.0, 0.0, 0.0);\n    vec3 _3643 = vec3(0.0, 0.0, 1.0);\n    float _3644 = 1.0;\n    float _3645 = 1.0;\n    float _1675 = clamp(s.specular, 0.0, 1.0);\n    float _1679 = clamp(s.ior, 1.0, 3.0);\n    bool _1684 = (_1675 != 1.0) || (_1679 != 1.5);\n    bool _1694;\n    if (!_1684)\n    {\n        _1694 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1694 = _1684;\n    }\n    if (_1694)\n    {\n        float _1702 = (_1679 - 1.0) / (_1679 + 1.0);\n        f0 = mix(min(vec3(_1702 * _1702) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1675, s.albedo, vec3(metallic));\n        _3626 = mix(_1675, 1.0, metallic);\n        _3625 = true;\n    }\n    float _1730 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1730 > 0.0)\n    {\n        float _1738 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3629 = _1730;\n        _3630 = _1738;\n        float _1745 = _1738 * _1738;\n        _3631 = _1745;\n        _3632 = _1745 * _1745;\n        float _1757 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3634 = _1757;\n        _3627 = 1.0 - (_1730 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1757, 0.0, 1.0), 5.0))));\n        _3625 = true;\n    }\n    vec3 _1777 = max(s.sheen_color, vec3(0.0));\n    float _1786 = max(_1777.x, max(_1777.y, _1777.z));\n    if (_1786 > 0.0)\n    {\n        float _1794 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3635 = true;\n        _3636 = _1777;\n        _3637 = _1794;\n        _3638 = _1794 * _1794;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1794;\n        float _1811 = fa_sheen_albedo(param, param_1);\n        _3640 = _1811;\n        _3639 = 1.0 - min(_1786 * _1811, 1.0);\n        _3625 = true;\n    }\n    _3628 = _3627 * _3639;\n    float _1830 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1830 != 0.0)\n    {\n        vec3 _1845 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1845;\n        if (dot(_1845, _1845) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1859 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1859.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1859.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1859.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1863 = t;\n        vec3 _1864 = normalize(_1863);\n        t = _1864;\n        vec3 _1889 = normalize((_1864 * cos(s.anisotropy_rotation)) + ((cross(n, _1864) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3642 = _1889;\n        _3643 = cross(n, _1889);\n        float _1899 = roughness * roughness;\n        float _1905 = mix(_1899, 1.0, _1830 * _1830);\n        bool _1907 = _1830 > 0.0;\n        _3644 = _1907 ? _1905 : _1899;\n        _3645 = _1907 ? _1899 : _1905;\n        _3641 = _1830;\n        _3625 = true;\n    }\n    return FaLayers(_3625, _3626, _3627, _3628, _3629, _3630, _3631, _3632, i.world_normal, _3634, _3635, _3636, _3637, _3638, _3639, _3640, _3641, _3642, _3643, _3644, _3645);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _337 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _343 = fa_light_texel(param_1);\n    float _346 = _343.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _353 = _346 < 0.5;\n    vec3 l;\n    if (_353)\n    {\n        l = normalize(_337.xyz);\n    }\n    else\n    {\n        vec3 _365 = _337.xyz - world_pos;\n        float _367 = length(_365);\n        dist = _367;\n        l = _365 / vec3(max(_367, 9.9999997473787516355514526367188e-05));\n        float _382 = _367 / max(_337.w, 0.001000000047497451305389404296875);\n        float _388 = clamp(1.0 - (_382 * _382), 0.0, 1.0);\n        atten = _388 * _388;\n        if (_346 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _402 = fa_light_texel(param_2);\n            float _412 = _402.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _419 = fa_light_texel(param_3);\n            float _420 = _419.x;\n            float cos_inner = _420;\n            if (_420 > 1.5)\n            {\n                cos_inner = mix(_412, 1.0, 0.25);\n            }\n            atten *= smoothstep(_412, cos_inner, dot(-l, normalize(_402.xyz)));\n        }\n    }\n    int _451;\n    if (_353)\n    {\n        _451 = 0;\n    }\n    else\n    {\n        _451 = (_346 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _343.xyz * atten, atten, 1.0, dist, _451);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _691;\n    if (i == 0)\n    {\n        _691 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _707;\n        if (i == 1)\n        {\n            _707 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _715;\n            if (i == 2)\n            {\n                _715 = fa_shadows[24].z;\n            }\n            else\n            {\n                _715 = fa_shadows[24].w;\n            }\n            _707 = _715;\n        }\n        _691 = _707;\n    }\n    return _691;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _679 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_679), sin(_679)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _753 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _758 = clamp(dot(n, l), 0.0, 1.0);\n    float _764 = sqrt(1.0 - (_758 * _758));\n    float _772 = min(_764 / max(_758, 0.20000000298023223876953125), 4.0);\n    float _777;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _777 = fa_shadows[26].y;\n    }\n    else\n    {\n        _777 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _802 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_777 * _764)), 1.0);\n    float _809 = _802.x;\n    bool _812 = _809 < fa_shadows[ci * 1 + 16].x;\n    bool _821;\n    if (!_812)\n    {\n        _821 = _809 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _821 = _812;\n    }\n    bool _830;\n    if (!_821)\n    {\n        _830 = _802.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _830 = _821;\n    }\n    bool _839;\n    if (!_830)\n    {\n        _839 = _802.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _839 = _830;\n    }\n    bool _846;\n    if (!_839)\n    {\n        _846 = _802.z > 1.0;\n    }\n    else\n    {\n        _846 = _839;\n    }\n    if (_846)\n    {\n        return -1.0;\n    }\n    float _855;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _855 = fa_shadows[26].x;\n    }\n    else\n    {\n        _855 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _874 = _802.z - ((_855 * (1.0 + (0.5 * _772))) / _753);\n    float _883 = ((fa_shadows[ci * 1 + 20].x * min(_772, 3.0)) * 0.5) / _753;\n    int _892 = int(fa_shadows[25].z + 0.5);\n    if (_892 == 1)\n    {\n        vec2 param = _802.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _903 = fa_shadow_depth(param, param_1);\n        return float(_874 <= _903);\n    }\n    float _910 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _913 = _892 == 2;\n    if (_913)\n    {\n        float _927 = clamp(((fa_shadows[25].w * _753) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _910;\n            vec2 _946 = fa_shadow_vogel(param_2, param_3, param_4) * _927;\n            vec2 param_5 = _802.xy + (_946 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _957 = fa_shadow_depth(param_5, param_6);\n            if (_957 < (_874 - (length(_946) * _883)))\n            {\n                sum += _957;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_874 - (sum / cnt), 0.0) * _753) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1001 = _913 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1001; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1001;\n        float param_9 = _910;\n        vec2 _1020 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _802.xy + (_1020 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1031 = fa_shadow_depth(param_10, param_11);\n        lit += float((_874 - (length(_1020) * _883)) <= _1031);\n    }\n    return lit / float(_1001);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1061 = int(fa_shadows[25].x + 0.5);\n    if (_1061 < 1)\n    {\n        return 1.0;\n    }\n    float _1077 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1061 - 1;\n    if (_1077 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1089 = _1061 > 1;\n    bool _1096;\n    if (_1089)\n    {\n        _1096 = _1077 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1096 = _1089;\n    }\n    if (_1096)\n    {\n        ci = 1;\n    }\n    bool _1100 = _1061 > 2;\n    bool _1107;\n    if (_1100)\n    {\n        _1107 = _1077 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1107 = _1100;\n    }\n    if (_1107)\n    {\n        ci = 2;\n    }\n    bool _1111 = _1061 > 3;\n    bool _1118;\n    if (_1111)\n    {\n        _1118 = _1077 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1118 = _1111;\n    }\n    if (_1118)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1061)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1144 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1144;\n        if (_1144 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1169;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1169 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1169 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1188 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1169, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1199 = clamp((_1077 - (fa_shadow_split_at(param_7) - _1188)) / _1188, 0.0, 1.0);\n        if (_1199 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1061)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1220 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1220;\n                if (_1220 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1199);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2442 = fa_light_sample(param, param_1);\n    vec3 _3674 = _2442.direction;\n    vec3 _3669 = _2442.color;\n    float _3671 = _2442.shadow;\n    int _3679 = _2442.type;\n    if ((_3679 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _3674;\n        float _2456 = fa_shadow_factor(param_2, param_3);\n        _3671 = _2456;\n        _3669 *= _2456;\n    }\n    return LightSample(_3674, _3669, _2442.attenuation, _3671, _2442._distance, _3679);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2057 = tdh / at;\n    float _2061 = bdh / ab;\n    float _2073 = ((_2057 * _2057) + (_2061 * _2061)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2073) * _2073);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2154 = 1.0 / alpha;\n    return ((2.0 + _2154) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2154)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2187 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2266 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2266) * _2266);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2187);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2187));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2339 = max(dot(L.nc, l), 0.0);\n        float _2345 = max(dot(L.nc, h), 0.0);\n        float _2354 = ((_2345 * _2345) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2354) * _2354)) * (0.5 / max(mix((2.0 * _2339) * L.coat_ndv, _2339 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2339)) * _2339);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1452 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1455 = _1452.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1455 * _1455, exp2((-9.27999973297119140625) * ndv)) * _1455) + _1452.y)) + _1452.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1357 = rough * rough;\n    float _1387 = 0.60000002384185791015625 * _1357;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1357)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1387, 0.0500000007450580596923828125 + _1387, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1357 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1940;\n        if (L.aniso >= 0.0)\n        {\n            _1940 = L.b;\n        }\n        else\n        {\n            _1940 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1940, v), _1940), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1973 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1973.x) + (vec3(L.f90) * _1973.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2028 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2028.x) + _2028.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1494 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1494.x) + vec3(_1494.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1244 = int(fa_shadows[25].x + 0.5);\n    float _1254 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1259 = _1244 > 0;\n    bool _1268;\n    if (_1259)\n    {\n        int param = _1244 - 1;\n        _1268 = _1254 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1268 = _1259;\n    }\n    if (_1268)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1275 = _1244 > 1;\n        bool _1282;\n        if (_1275)\n        {\n            _1282 = _1254 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1282 = _1275;\n        }\n        if (_1282)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1288 = _1244 > 2;\n        bool _1295;\n        if (_1288)\n        {\n            _1295 = _1254 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1295 = _1288;\n        }\n        if (_1295)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1301 = _1244 > 3;\n        bool _1308;\n        if (_1301)\n        {\n            _1308 = _1254 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1308 = _1301;\n        }\n        if (_1308)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3404 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3404 = -_3404;\n    }\n    vec3 _2858 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing);\n    Surface _2866 = fa_standard_surface(param_1);\n    vec3 _3435 = _2866.albedo;\n    float _3436 = _2866.alpha;\n    vec3 _3437 = _2866.normal;\n    float _3438 = _2866.metallic;\n    float _3439 = _2866.roughness;\n    float _3440 = _2866.occlusion;\n    vec3 _3441 = _2866.emission;\n    float _3442 = _2866.clearcoat;\n    float _3443 = _2866.clearcoat_roughness;\n    vec3 _3444 = _2866.sheen_color;\n    float _3445 = _2866.sheen_roughness;\n    float _3446 = _2866.anisotropy;\n    float _3447 = _2866.anisotropy_rotation;\n    float _3448 = _2866.specular;\n    float _3449 = _2866.ior;\n    vec3 _3450 = _2866.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing);\n    Surface param_3 = _2866;\n    surface(param_2, param_3);\n    _3435 = param_3.albedo;\n    _3436 = param_3.alpha;\n    _3437 = param_3.normal;\n    _3438 = param_3.metallic;\n    _3439 = param_3.roughness;\n    _3440 = param_3.occlusion;\n    _3441 = param_3.emission;\n    _3442 = param_3.clearcoat;\n    _3443 = param_3.clearcoat_roughness;\n    _3444 = param_3.sheen_color;\n    _3445 = param_3.sheen_roughness;\n    _3446 = param_3.anisotropy;\n    _3447 = param_3.anisotropy_rotation;\n    _3448 = param_3.specular;\n    _3449 = param_3.ior;\n    _3450 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3435;\n    }\n    else\n    {\n        vec3 _2888 = normalize(_3437);\n        float _2895 = clamp(_3438, 0.0, 1.0);\n        float _2899 = clamp(_3439, 0.0500000007450580596923828125, 1.0);\n        float _2903 = _2899 * _2899;\n        float _2907 = _2903 * _2903;\n        float _2912 = max(dot(_2888, _2858), 9.9999997473787516355514526367188e-05);\n        vec3 _2918 = _3435 * (1.0 - _2895);\n        vec3 _2925 = mix(vec3(0.039999999105930328369140625), _3435, vec3(_2895));\n        vec3 f0 = _2925;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing);\n        Surface param_5 = Surface(_3435, _3436, _3437, _3438, _3439, _3440, _3441, _3442, _3443, _3444, _3445, _3446, _3447, _3448, _3449, _3450);\n        vec3 param_6 = _2888;\n        vec3 param_7 = _2858;\n        float param_8 = _2895;\n        float param_9 = _2899;\n        vec3 param_10 = _2925;\n        FaLayers _2941 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _2888;\n        vec3 lit = (fa_ambient_light(param_11) * _2918) * _3440;\n        if (_2941.on)\n        {\n            lit *= _2941.base_scale;\n        }\n        int _2963 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2963; ln++)\n        {\n            int param_12 = ln;\n            int _2976 = fa_cl_light(param_12);\n            int param_13 = _2976;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _3404;\n            LightSample _2985 = fa_light_shadowed(param_13, param_14, param_15);\n            vec3 _3609 = _2985.direction;\n            float _2993 = max(dot(_2888, _3609), 0.0);\n            float _2999 = _2985.attenuation * _2985.shadow;\n            vec3 _3004 = normalize(_3609 + _2858);\n            float _3009 = max(dot(_2888, _3004), 0.0);\n            float _3014 = max(dot(_2858, _3004), 0.0);\n            if (_2941.on)\n            {\n                FaLayers param_16 = _2941;\n                vec3 param_17 = _2918;\n                vec3 param_18 = f0;\n                vec3 param_19 = _2888;\n                vec3 param_20 = _2858;\n                vec3 param_21 = _3609;\n                vec3 param_22 = _3004;\n                float param_23 = _2993;\n                float param_24 = _2912;\n                float param_25 = _3009;\n                float param_26 = _3014;\n                float param_27 = _2903;\n                float param_28 = _2907;\n                int param_29 = _2976;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _2999));\n            }\n            else\n            {\n                float _3062 = ((_3009 * _3009) * (_2907 - 1.0)) + 1.0;\n                int param_30 = _2976;\n                lit += (((_2918 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3014, 5.0))) * (((_2907 / ((3.1415927410125732421875 * _3062) * _3062)) * (0.5 / max(mix((2.0 * _2993) * _2912, _2993 + _2912, _2903), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2993))) * fa_light_rgb(param_30)) * (_2993 * _2999));\n            }\n        }\n        if (_2941.on)\n        {\n            FaLayers param_31 = _2941;\n            vec3 param_32 = _2888;\n            vec3 param_33 = _2858;\n            vec3 param_34 = f0;\n            float param_35 = _2899;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3440);\n        }\n        else\n        {\n            vec3 param_36 = _2888;\n            vec3 param_37 = _2858;\n            vec3 param_38 = f0;\n            float param_39 = _2899;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3440);\n        }\n        result = lit;\n    }\n    vec3 _3155 = result;\n    vec3 _3156 = _3155 + _3441;\n    result = _3156;\n    vec3 param_40 = _3156;\n    vec3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3165 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3172;\n    if (!_3165)\n    {\n        _3172 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3172 = _3165;\n    }\n    if (_3172)\n    {\n        vec3 _3181 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3187 = dot(_3181, fa_mesh_fs_params[9].xyz);\n        bool _3191 = fa_mesh_fs_params[9].w > 0.5;\n        float _3192;\n        if (_3191)\n        {\n            _3192 = _3187;\n        }\n        else\n        {\n            _3192 = length(_3181);\n        }\n        float _3204 = _3192 - fa_mesh_fs_params[8].x;\n        if (_3204 > 0.0)\n        {\n            float _3213 = fa_mesh_fs_params[7].w * _3204;\n            float tau = _3213 * _3213;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3229;\n                if (_3191)\n                {\n                    _3229 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3187);\n                }\n                else\n                {\n                    _3229 = fa_mesh_fs_params[0].y;\n                }\n                float _3250 = mix(_3229, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3192, 0.0, 1.0));\n                float _3254 = fa_world_pos.y - _3250;\n                float _3259 = _3250 - fa_mesh_fs_params[8].z;\n                float _3264 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3267 = _3259 <= 0.0;\n                bool _3268 = !_3267;\n                bool _3274;\n                if (_3268)\n                {\n                    _3274 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3274 = _3267;\n                }\n                float _3275;\n                if (_3274)\n                {\n                    _3275 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3275 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3259, 80.0));\n                }\n                bool _3302;\n                if (_3268)\n                {\n                    _3302 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3302 = _3267;\n                }\n                float _3303;\n                if (_3302)\n                {\n                    _3303 = fa_mesh_fs_params[8].y * _3259;\n                }\n                else\n                {\n                    _3303 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3259, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3328 = _3264 <= 0.0;\n                bool _3335;\n                if (!_3328)\n                {\n                    _3335 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3335 = _3328;\n                }\n                float _3336;\n                if (_3335)\n                {\n                    _3336 = fa_mesh_fs_params[8].y * _3264;\n                }\n                else\n                {\n                    _3336 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3264, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3363;\n                if (abs(_3254) < 0.001000000047497451305389404296875)\n                {\n                    _3363 = _3275;\n                }\n                else\n                {\n                    _3363 = (_3336 - _3303) / _3254;\n                }\n                tau += (_3204 * max(_3363, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3436);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_465",
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
            "inst_name": "_701",
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
            "inst_name": "_2481",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1595[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _470 = fa_mesh_fs_params[19].x < 0.0;\n    bool _477;\n    if (!_470)\n    {\n        _477 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    bool _485;\n    if (!_477)\n    {\n        _485 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _485 = _477;\n    }\n    bool _492;\n    if (!_485)\n    {\n        _492 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _492 = _485;\n    }\n    bool _499;\n    if (!_492)\n    {\n        _499 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _499 = _492;\n    }\n    if (_499)\n    {\n        return ivec2(0);\n    }\n    vec4 _509 = vec4(world_pos, 1.0);\n    float _516 = dot(fa_mesh_fs_params[16], _509);\n    if (!(_516 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _538 = vec2(dot(fa_mesh_fs_params[14], _509), dot(fa_mesh_fs_params[15], _509)) / vec2(_516);\n    int _542 = int(fa_mesh_fs_params[18].x);\n    int _546 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _546) + clamp(int(floor(((_538.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _546 - 1)) * _542)) + clamp(int(floor(((_538.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _542 - 1);\n    vec4 _617 = fa_light_texel(param);\n    return ivec2(int(_617.x), int(_617.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2414 = fa_cluster_lookup(param);\n    fa_cl_slot = _2414.x;\n    fa_cl_local = _2414.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2545 = fa_linear_to_srgb(param);\n        c = _2545;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2553 = fa_srgb_to_linear(param_1);\n            c = _2553;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _237;\n    if (i.front_facing)\n    {\n        _237 = i.world_normal;\n    }\n    else\n    {\n        _237 = -i.world_normal;\n    }\n    vec3 _261 = normalize(i.world_tangent.xyz - (_237 * dot(_237, i.world_tangent.xyz)));\n    vec3 _289 = normalize(((_261 * m.x) + ((cross(_237, _261) * i.world_tangent.w) * m.y)) + (_237 * m.z));\n    vec3 _292;\n    if (i.front_facing)\n    {\n        _292 = _289;\n    }\n    else\n    {\n        _292 = -_289;\n    }\n    return _292;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2584 = fa_tex_fix(param_2, param_3);\n    vec4 _3755 = base_t;\n    _3755.x = _2584.x;\n    _3755.y = _2584.y;\n    _3755.z = _2584.z;\n    base_t = _3755;\n    vec4 _2598 = (_3755 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3689 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2630 = fa_tex_fix(param_6, param_7);\n        vec3 _2633 = (_2630 * 2.0) - vec3(1.0);\n        vec2 _2638 = _2633.xy * fa_mesh_fs_params[6].x;\n        vec3 _3763 = _2633;\n        _3763.x = _2638.x;\n        _3763.y = _2638.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3763;\n        _3689 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2667 = fa_tex_fix(param_12, param_13);\n    vec4 _3766 = mrt;\n    _3766.x = _2667.x;\n    _3766.y = _2667.y;\n    _3766.z = _2667.z;\n    mrt = _3766;\n    vec4 _2695 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2695.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2707 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2737 = fa_tex_fix(param_20, param_21);\n    float _3694 = fa_mesh_fs_params[20].x;\n    float _3695 = fa_mesh_fs_params[20].y;\n    float _3698 = fa_mesh_fs_params[20].z;\n    float _3697 = fa_mesh_fs_params[21].w;\n    float _3700 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3694 *= _2707.y;\n            _3695 *= _2707.z;\n            _3697 *= _2695.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3698 *= mrt.x;\n            _3700 *= mrt.w;\n        }\n    }\n    return Surface(_2598.xyz, _2598.w, _3689, clamp(fa_mesh_fs_params[5].x * _2667.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2667.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2707.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2737), _3694, _3695, fa_mesh_fs_params[21].xyz, _3697, _3698, fa_mesh_fs_params[20].w, _3700, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1520 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1528 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1531 = int(_1520);\n    int _1534 = int(_1528);\n    float _1544 = _1528 - float(_1534);\n    int _1600 = (_1531 * 9) + _1534;\n    int _1620 = ((_1531 + 1) * 9) + _1534;\n    return mix(mix(_1595[_1600], _1595[_1600 + 1], _1544), mix(_1595[_1620], _1595[_1620 + 1], _1544), _1520 - float(_1531));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3625 = false;\n    float _3626 = 1.0;\n    float _3627 = 1.0;\n    float _3628 = 1.0;\n    float _3629 = 0.0;\n    float _3630 = 0.0;\n    float _3631 = 0.0;\n    float _3632 = 0.0;\n    float _3634 = 1.0;\n    bool _3635 = false;\n    vec3 _3636 = vec3(0.0);\n    float _3637 = 1.0;\n    float _3638 = 1.0;\n    float _3639 = 1.0;\n    float _3640 = 0.0;\n    float _3641 = 0.0;\n    vec3 _3642 = vec3(1.0, 0.0, 0.0);\n    vec3 _3643 = vec3(0.0, 0.0, 1.0);\n    float _3644 = 1.0;\n    float _3645 = 1.0;\n    float _1675 = clamp(s.specular, 0.0, 1.0);\n    float _1679 = clamp(s.ior, 1.0, 3.0);\n    bool _1684 = (_1675 != 1.0) || (_1679 != 1.5);\n    bool _1694;\n    if (!_1684)\n    {\n        _1694 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1694 = _1684;\n    }\n    if (_1694)\n    {\n        float _1702 = (_1679 - 1.0) / (_1679 + 1.0);\n        f0 = mix(min(vec3(_1702 * _1702) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1675, s.albedo, vec3(metallic));\n        _3626 = mix(_1675, 1.0, metallic);\n        _3625 = true;\n    }\n    float _1730 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1730 > 0.0)\n    {\n        float _1738 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3629 = _1730;\n        _3630 = _1738;\n        float _1745 = _1738 * _1738;\n        _3631 = _1745;\n        _3632 = _1745 * _1745;\n        float _1757 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3634 = _1757;\n        _3627 = 1.0 - (_1730 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1757, 0.0, 1.0), 5.0))));\n        _3625 = true;\n    }\n    vec3 _1777 = max(s.sheen_color, vec3(0.0));\n    float _1786 = max(_1777.x, max(_1777.y, _1777.z));\n    if (_1786 > 0.0)\n    {\n        float _1794 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3635 = true;\n        _3636 = _1777;\n        _3637 = _1794;\n        _3638 = _1794 * _1794;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1794;\n        float _1811 = fa_sheen_albedo(param, param_1);\n        _3640 = _1811;\n        _3639 = 1.0 - min(_1786 * _1811, 1.0);\n        _3625 = true;\n    }\n    _3628 = _3627 * _3639;\n    float _1830 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1830 != 0.0)\n    {\n        vec3 _1845 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1845;\n        if (dot(_1845, _1845) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1859 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1859.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1859.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1859.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1863 = t;\n        vec3 _1864 = normalize(_1863);\n        t = _1864;\n        vec3 _1889 = normalize((_1864 * cos(s.anisotropy_rotation)) + ((cross(n, _1864) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3642 = _1889;\n        _3643 = cross(n, _1889);\n        float _1899 = roughness * roughness;\n        float _1905 = mix(_1899, 1.0, _1830 * _1830);\n        bool _1907 = _1830 > 0.0;\n        _3644 = _1907 ? _1905 : _1899;\n        _3645 = _1907 ? _1899 : _1905;\n        _3641 = _1830;\n        _3625 = true;\n    }\n    return FaLayers(_3625, _3626, _3627, _3628, _3629, _3630, _3631, _3632, i.world_normal, _3634, _3635, _3636, _3637, _3638, _3639, _3640, _3641, _3642, _3643, _3644, _3645);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _337 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _343 = fa_light_texel(param_1);\n    float _346 = _343.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _353 = _346 < 0.5;\n    vec3 l;\n    if (_353)\n    {\n        l = normalize(_337.xyz);\n    }\n    else\n    {\n        vec3 _365 = _337.xyz - world_pos;\n        float _367 = length(_365);\n        dist = _367;\n        l = _365 / vec3(max(_367, 9.9999997473787516355514526367188e-05));\n        float _382 = _367 / max(_337.w, 0.001000000047497451305389404296875);\n        float _388 = clamp(1.0 - (_382 * _382), 0.0, 1.0);\n        atten = _388 * _388;\n        if (_346 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _402 = fa_light_texel(param_2);\n            float _412 = _402.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _419 = fa_light_texel(param_3);\n            float _420 = _419.x;\n            float cos_inner = _420;\n            if (_420 > 1.5)\n            {\n                cos_inner = mix(_412, 1.0, 0.25);\n            }\n            atten *= smoothstep(_412, cos_inner, dot(-l, normalize(_402.xyz)));\n        }\n    }\n    int _451;\n    if (_353)\n    {\n        _451 = 0;\n    }\n    else\n    {\n        _451 = (_346 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _343.xyz * atten, atten, 1.0, dist, _451);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _691;\n    if (i == 0)\n    {\n        _691 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _707;\n        if (i == 1)\n        {\n            _707 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _715;\n            if (i == 2)\n            {\n                _715 = fa_shadows[24].z;\n            }\n            else\n            {\n                _715 = fa_shadows[24].w;\n            }\n            _707 = _715;\n        }\n        _691 = _707;\n    }\n    return _691;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _679 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_679), sin(_679)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _753 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _758 = clamp(dot(n, l), 0.0, 1.0);\n    float _764 = sqrt(1.0 - (_758 * _758));\n    float _772 = min(_764 / max(_758, 0.20000000298023223876953125), 4.0);\n    float _777;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _777 = fa_shadows[26].y;\n    }\n    else\n    {\n        _777 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _802 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_777 * _764)), 1.0);\n    float _809 = _802.x;\n    bool _812 = _809 < fa_shadows[ci * 1 + 16].x;\n    bool _821;\n    if (!_812)\n    {\n        _821 = _809 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _821 = _812;\n    }\n    bool _830;\n    if (!_821)\n    {\n        _830 = _802.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _830 = _821;\n    }\n    bool _839;\n    if (!_830)\n    {\n        _839 = _802.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _839 = _830;\n    }\n    bool _846;\n    if (!_839)\n    {\n        _846 = _802.z > 1.0;\n    }\n    else\n    {\n        _846 = _839;\n    }\n    if (_846)\n    {\n        return -1.0;\n    }\n    float _855;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _855 = fa_shadows[26].x;\n    }\n    else\n    {\n        _855 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _874 = _802.z - ((_855 * (1.0 + (0.5 * _772))) / _753);\n    float _883 = ((fa_shadows[ci * 1 + 20].x * min(_772, 3.0)) * 0.5) / _753;\n    int _892 = int(fa_shadows[25].z + 0.5);\n    if (_892 == 1)\n    {\n        vec2 param = _802.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _903 = fa_shadow_depth(param, param_1);\n        return float(_874 <= _903);\n    }\n    float _910 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _913 = _892 == 2;\n    if (_913)\n    {\n        float _927 = clamp(((fa_shadows[25].w * _753) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _910;\n            vec2 _946 = fa_shadow_vogel(param_2, param_3, param_4) * _927;\n            vec2 param_5 = _802.xy + (_946 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _957 = fa_shadow_depth(param_5, param_6);\n            if (_957 < (_874 - (length(_946) * _883)))\n            {\n                sum += _957;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_874 - (sum / cnt), 0.0) * _753) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1001 = _913 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1001; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1001;\n        float param_9 = _910;\n        vec2 _1020 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _802.xy + (_1020 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1031 = fa_shadow_depth(param_10, param_11);\n        lit += float((_874 - (length(_1020) * _883)) <= _1031);\n    }\n    return lit / float(_1001);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1061 = int(fa_shadows[25].x + 0.5);\n    if (_1061 < 1)\n    {\n        return 1.0;\n    }\n    float _1077 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1061 - 1;\n    if (_1077 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1089 = _1061 > 1;\n    bool _1096;\n    if (_1089)\n    {\n        _1096 = _1077 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1096 = _1089;\n    }\n    if (_1096)\n    {\n        ci = 1;\n    }\n    bool _1100 = _1061 > 2;\n    bool _1107;\n    if (_1100)\n    {\n        _1107 = _1077 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1107 = _1100;\n    }\n    if (_1107)\n    {\n        ci = 2;\n    }\n    bool _1111 = _1061 > 3;\n    bool _1118;\n    if (_1111)\n    {\n        _1118 = _1077 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1118 = _1111;\n    }\n    if (_1118)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1061)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1144 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1144;\n        if (_1144 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1169;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1169 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1169 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1188 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1169, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1199 = clamp((_1077 - (fa_shadow_split_at(param_7) - _1188)) / _1188, 0.0, 1.0);\n        if (_1199 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1061)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1220 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1220;\n                if (_1220 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1199);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2442 = fa_light_sample(param, param_1);\n    vec3 _3674 = _2442.direction;\n    vec3 _3669 = _2442.color;\n    float _3671 = _2442.shadow;\n    int _3679 = _2442.type;\n    if ((_3679 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _3674;\n        float _2456 = fa_shadow_factor(param_2, param_3);\n        _3671 = _2456;\n        _3669 *= _2456;\n    }\n    return LightSample(_3674, _3669, _2442.attenuation, _3671, _2442._distance, _3679);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2057 = tdh / at;\n    float _2061 = bdh / ab;\n    float _2073 = ((_2057 * _2057) + (_2061 * _2061)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2073) * _2073);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2154 = 1.0 / alpha;\n    return ((2.0 + _2154) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2154)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2187 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2266 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2266) * _2266);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2187);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2187));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2339 = max(dot(L.nc, l), 0.0);\n        float _2345 = max(dot(L.nc, h), 0.0);\n        float _2354 = ((_2345 * _2345) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2354) * _2354)) * (0.5 / max(mix((2.0 * _2339) * L.coat_ndv, _2339 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2339)) * _2339);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1452 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1455 = _1452.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1455 * _1455, exp2((-9.27999973297119140625) * ndv)) * _1455) + _1452.y)) + _1452.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1357 = rough * rough;\n    float _1387 = 0.60000002384185791015625 * _1357;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1357)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1387, 0.0500000007450580596923828125 + _1387, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1357 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1940;\n        if (L.aniso >= 0.0)\n        {\n            _1940 = L.b;\n        }\n        else\n        {\n            _1940 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1940, v), _1940), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1973 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1973.x) + (vec3(L.f90) * _1973.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2028 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2028.x) + _2028.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1494 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1494.x) + vec3(_1494.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1244 = int(fa_shadows[25].x + 0.5);\n    float _1254 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _1259 = _1244 > 0;\n    bool _1268;\n    if (_1259)\n    {\n        int param = _1244 - 1;\n        _1268 = _1254 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1268 = _1259;\n    }\n    if (_1268)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1275 = _1244 > 1;\n        bool _1282;\n        if (_1275)\n        {\n            _1282 = _1254 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1282 = _1275;\n        }\n        if (_1282)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1288 = _1244 > 2;\n        bool _1295;\n        if (_1288)\n        {\n            _1295 = _1254 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1295 = _1288;\n        }\n        if (_1295)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1301 = _1244 > 3;\n        bool _1308;\n        if (_1301)\n        {\n            _1308 = _1254 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1308 = _1301;\n        }\n        if (_1308)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3404 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3404 = -_3404;\n    }\n    vec3 _2858 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing);\n    Surface _2866 = fa_standard_surface(param_1);\n    vec3 _3435 = _2866.albedo;\n    float _3436 = _2866.alpha;\n    vec3 _3437 = _2866.normal;\n    float _3438 = _2866.metallic;\n    float _3439 = _2866.roughness;\n    float _3440 = _2866.occlusion;\n    vec3 _3441 = _2866.emission;\n    float _3442 = _2866.clearcoat;\n    float _3443 = _2866.clearcoat_roughness;\n    vec3 _3444 = _2866.sheen_color;\n    float _3445 = _2866.sheen_roughness;\n    float _3446 = _2866.anisotropy;\n    float _3447 = _2866.anisotropy_rotation;\n    float _3448 = _2866.specular;\n    float _3449 = _2866.ior;\n    vec3 _3450 = _2866.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing);\n    Surface param_3 = _2866;\n    surface(param_2, param_3);\n    _3435 = param_3.albedo;\n    _3436 = param_3.alpha;\n    _3437 = param_3.normal;\n    _3438 = param_3.metallic;\n    _3439 = param_3.roughness;\n    _3440 = param_3.occlusion;\n    _3441 = param_3.emission;\n    _3442 = param_3.clearcoat;\n    _3443 = param_3.clearcoat_roughness;\n    _3444 = param_3.sheen_color;\n    _3445 = param_3.sheen_roughness;\n    _3446 = param_3.anisotropy;\n    _3447 = param_3.anisotropy_rotation;\n    _3448 = param_3.specular;\n    _3449 = param_3.ior;\n    _3450 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3435;\n    }\n    else\n    {\n        vec3 _2888 = normalize(_3437);\n        float _2895 = clamp(_3438, 0.0, 1.0);\n        float _2899 = clamp(_3439, 0.0500000007450580596923828125, 1.0);\n        float _2903 = _2899 * _2899;\n        float _2907 = _2903 * _2903;\n        float _2912 = max(dot(_2888, _2858), 9.9999997473787516355514526367188e-05);\n        vec3 _2918 = _3435 * (1.0 - _2895);\n        vec3 _2925 = mix(vec3(0.039999999105930328369140625), _3435, vec3(_2895));\n        vec3 f0 = _2925;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3404, fa_world_tangent, fa_uv, fa_vertex_color, _2858, gl_FrontFacing);\n        Surface param_5 = Surface(_3435, _3436, _3437, _3438, _3439, _3440, _3441, _3442, _3443, _3444, _3445, _3446, _3447, _3448, _3449, _3450);\n        vec3 param_6 = _2888;\n        vec3 param_7 = _2858;\n        float param_8 = _2895;\n        float param_9 = _2899;\n        vec3 param_10 = _2925;\n        FaLayers _2941 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _2888;\n        vec3 lit = (fa_ambient_light(param_11) * _2918) * _3440;\n        if (_2941.on)\n        {\n            lit *= _2941.base_scale;\n        }\n        int _2963 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2963; ln++)\n        {\n            int param_12 = ln;\n            int _2976 = fa_cl_light(param_12);\n            int param_13 = _2976;\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _3404;\n            LightSample _2985 = fa_light_shadowed(param_13, param_14, param_15);\n            vec3 _3609 = _2985.direction;\n            float _2993 = max(dot(_2888, _3609), 0.0);\n            float _2999 = _2985.attenuation * _2985.shadow;\n            vec3 _3004 = normalize(_3609 + _2858);\n            float _3009 = max(dot(_2888, _3004), 0.0);\n            float _3014 = max(dot(_2858, _3004), 0.0);\n            if (_2941.on)\n            {\n                FaLayers param_16 = _2941;\n                vec3 param_17 = _2918;\n                vec3 param_18 = f0;\n                vec3 param_19 = _2888;\n                vec3 param_20 = _2858;\n                vec3 param_21 = _3609;\n                vec3 param_22 = _3004;\n                float param_23 = _2993;\n                float param_24 = _2912;\n                float param_25 = _3009;\n                float param_26 = _3014;\n                float param_27 = _2903;\n                float param_28 = _2907;\n                int param_29 = _2976;\n                lit += (fa_layers_light(param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28) * (fa_light_rgb(param_29) * _2999));\n            }\n            else\n            {\n                float _3062 = ((_3009 * _3009) * (_2907 - 1.0)) + 1.0;\n                int param_30 = _2976;\n                lit += (((_2918 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3014, 5.0))) * (((_2907 / ((3.1415927410125732421875 * _3062) * _3062)) * (0.5 / max(mix((2.0 * _2993) * _2912, _2993 + _2912, _2903), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2993))) * fa_light_rgb(param_30)) * (_2993 * _2999));\n            }\n        }\n        if (_2941.on)\n        {\n            FaLayers param_31 = _2941;\n            vec3 param_32 = _2888;\n            vec3 param_33 = _2858;\n            vec3 param_34 = f0;\n            float param_35 = _2899;\n            lit += (fa_layers_ibl(param_31, param_32, param_33, param_34, param_35) * _3440);\n        }\n        else\n        {\n            vec3 param_36 = _2888;\n            vec3 param_37 = _2858;\n            vec3 param_38 = f0;\n            float param_39 = _2899;\n            lit += (fa_sky_reflection(param_36, param_37, param_38, param_39) * _3440);\n        }\n        result = lit;\n    }\n    vec3 _3155 = result;\n    vec3 _3156 = _3155 + _3441;\n    result = _3156;\n    vec3 param_40 = _3156;\n    vec3 param_41 = fa_world_pos;\n    result = fa_shadow_debug(param_40, param_41);\n    bool _3165 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3172;\n    if (!_3165)\n    {\n        _3172 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3172 = _3165;\n    }\n    if (_3172)\n    {\n        vec3 _3181 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3187 = dot(_3181, fa_mesh_fs_params[9].xyz);\n        bool _3191 = fa_mesh_fs_params[9].w > 0.5;\n        float _3192;\n        if (_3191)\n        {\n            _3192 = _3187;\n        }\n        else\n        {\n            _3192 = length(_3181);\n        }\n        float _3204 = _3192 - fa_mesh_fs_params[8].x;\n        if (_3204 > 0.0)\n        {\n            float _3213 = fa_mesh_fs_params[7].w * _3204;\n            float tau = _3213 * _3213;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3229;\n                if (_3191)\n                {\n                    _3229 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3187);\n                }\n                else\n                {\n                    _3229 = fa_mesh_fs_params[0].y;\n                }\n                float _3250 = mix(_3229, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3192, 0.0, 1.0));\n                float _3254 = fa_world_pos.y - _3250;\n                float _3259 = _3250 - fa_mesh_fs_params[8].z;\n                float _3264 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3267 = _3259 <= 0.0;\n                bool _3268 = !_3267;\n                bool _3274;\n                if (_3268)\n                {\n                    _3274 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3274 = _3267;\n                }\n                float _3275;\n                if (_3274)\n                {\n                    _3275 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3275 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3259, 80.0));\n                }\n                bool _3302;\n                if (_3268)\n                {\n                    _3302 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3302 = _3267;\n                }\n                float _3303;\n                if (_3302)\n                {\n                    _3303 = fa_mesh_fs_params[8].y * _3259;\n                }\n                else\n                {\n                    _3303 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3259, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3328 = _3264 <= 0.0;\n                bool _3335;\n                if (!_3328)\n                {\n                    _3335 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3335 = _3328;\n                }\n                float _3336;\n                if (_3335)\n                {\n                    _3336 = fa_mesh_fs_params[8].y * _3264;\n                }\n                else\n                {\n                    _3336 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3264, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3363;\n                if (abs(_3254) < 0.001000000047497451305389404296875)\n                {\n                    _3363 = _3275;\n                }\n                else\n                {\n                    _3363 = (_3336 - _3303) / _3254;\n                }\n                tau += (_3204 * max(_3363, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3436);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_465",
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
            "inst_name": "_701",
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
            "inst_name": "_2481",
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
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _303 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _310 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_303 * _310).z;\n    fa_pre_r0 = vec3(_303[0].x, _303[1].x, _303[2].x);\n    fa_pre_r1 = vec3(_303[0].y, _303[1].y, _303[2].y);\n    fa_pre_r2 = vec3(_303[0].z, _303[1].z, _303[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _310;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
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
