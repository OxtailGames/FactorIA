{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
  "slang": "glsl430",
  "params": [
    "alphaCutoff"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1616[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _491 = fa_mesh_fs_params[19].x < 0.0;\n    bool _498;\n    if (!_491)\n    {\n        _498 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _498 = _491;\n    }\n    bool _506;\n    if (!_498)\n    {\n        _506 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _506 = _498;\n    }\n    bool _513;\n    if (!_506)\n    {\n        _513 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _513 = _506;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return ivec2(0);\n    }\n    vec4 _530 = vec4(world_pos, 1.0);\n    float _537 = dot(fa_mesh_fs_params[16], _530);\n    if (!(_537 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _559 = vec2(dot(fa_mesh_fs_params[14], _530), dot(fa_mesh_fs_params[15], _530)) / vec2(_537);\n    int _563 = int(fa_mesh_fs_params[18].x);\n    int _567 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _567) + clamp(int(floor(((_559.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _567 - 1)) * _563)) + clamp(int(floor(((_559.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _563 - 1);\n    vec4 _638 = fa_light_texel(param);\n    return ivec2(int(_638.x), int(_638.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2435 = fa_cluster_lookup(param);\n    fa_cl_slot = _2435.x;\n    fa_cl_local = _2435.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _241;\n    if (i.front_facing)\n    {\n        _241 = i.world_normal;\n    }\n    else\n    {\n        _241 = -i.world_normal;\n    }\n    vec3 _265 = normalize(i.world_tangent.xyz - (_241 * dot(_241, i.world_tangent.xyz)));\n    vec3 _293 = normalize(((_265 * m.x) + ((cross(_241, _265) * i.world_tangent.w) * m.y)) + (_241 * m.z));\n    vec3 _296;\n    if (i.front_facing)\n    {\n        _296 = _293;\n    }\n    else\n    {\n        _296 = -_293;\n    }\n    return _296;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2601 = fa_tex_fix(param_2, param_3);\n    vec4 _3827 = base_t;\n    _3827.x = _2601.x;\n    _3827.y = _2601.y;\n    _3827.z = _2601.z;\n    base_t = _3827;\n    vec4 _2615 = (_3827 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3761 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2647 = fa_tex_fix(param_6, param_7);\n        vec3 _2650 = (_2647 * 2.0) - vec3(1.0);\n        vec2 _2655 = _2650.xy * fa_mesh_fs_params[6].x;\n        vec3 _3835 = _2650;\n        _3835.x = _2655.x;\n        _3835.y = _2655.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3835;\n        _3761 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2684 = fa_tex_fix(param_12, param_13);\n    vec4 _3838 = mrt;\n    _3838.x = _2684.x;\n    _3838.y = _2684.y;\n    _3838.z = _2684.z;\n    mrt = _3838;\n    vec4 _2712 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3766 = fa_mesh_fs_params[20].x;\n    float _3767 = fa_mesh_fs_params[20].y;\n    float _3770 = fa_mesh_fs_params[20].z;\n    float _3769 = fa_mesh_fs_params[21].w;\n    float _3772 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3766 *= _2724.y;\n            _3767 *= _2724.z;\n            _3769 *= _2712.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3770 *= mrt.x;\n            _3772 *= mrt.w;\n        }\n    }\n    return Surface(_2615.xyz, _2615.w, _3761, clamp(fa_mesh_fs_params[5].x * _2684.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2684.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2724.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2754), _3766, _3767, fa_mesh_fs_params[21].xyz, _3769, _3770, fa_mesh_fs_params[20].w, _3772, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1541 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1549 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1552 = int(_1541);\n    int _1555 = int(_1549);\n    float _1565 = _1549 - float(_1555);\n    int _1621 = (_1552 * 9) + _1555;\n    int _1641 = ((_1552 + 1) * 9) + _1555;\n    return mix(mix(_1616[_1621], _1616[_1621 + 1], _1565), mix(_1616[_1641], _1616[_1641 + 1], _1565), _1541 - float(_1552));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3684 = false;\n    float _3685 = 1.0;\n    float _3686 = 1.0;\n    float _3687 = 1.0;\n    float _3688 = 0.0;\n    float _3689 = 0.0;\n    float _3690 = 0.0;\n    float _3691 = 0.0;\n    float _3693 = 1.0;\n    bool _3694 = false;\n    vec3 _3695 = vec3(0.0);\n    float _3696 = 1.0;\n    float _3697 = 1.0;\n    float _3698 = 1.0;\n    float _3699 = 0.0;\n    float _3700 = 0.0;\n    vec3 _3701 = vec3(1.0, 0.0, 0.0);\n    vec3 _3702 = vec3(0.0, 0.0, 1.0);\n    float _3703 = 1.0;\n    float _3704 = 1.0;\n    float _1696 = clamp(s.specular, 0.0, 1.0);\n    float _1700 = clamp(s.ior, 1.0, 3.0);\n    bool _1705 = (_1696 != 1.0) || (_1700 != 1.5);\n    bool _1715;\n    if (!_1705)\n    {\n        _1715 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1715 = _1705;\n    }\n    if (_1715)\n    {\n        float _1723 = (_1700 - 1.0) / (_1700 + 1.0);\n        f0 = mix(min(vec3(_1723 * _1723) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1696, s.albedo, vec3(metallic));\n        _3685 = mix(_1696, 1.0, metallic);\n        _3684 = true;\n    }\n    float _1751 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1751 > 0.0)\n    {\n        float _1759 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3688 = _1751;\n        _3689 = _1759;\n        float _1766 = _1759 * _1759;\n        _3690 = _1766;\n        _3691 = _1766 * _1766;\n        float _1778 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3693 = _1778;\n        _3686 = 1.0 - (_1751 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1778, 0.0, 1.0), 5.0))));\n        _3684 = true;\n    }\n    vec3 _1798 = max(s.sheen_color, vec3(0.0));\n    float _1807 = max(_1798.x, max(_1798.y, _1798.z));\n    if (_1807 > 0.0)\n    {\n        float _1815 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3694 = true;\n        _3695 = _1798;\n        _3696 = _1815;\n        _3697 = _1815 * _1815;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1815;\n        float _1832 = fa_sheen_albedo(param, param_1);\n        _3699 = _1832;\n        _3698 = 1.0 - min(_1807 * _1832, 1.0);\n        _3684 = true;\n    }\n    _3687 = _3686 * _3698;\n    float _1851 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1851 != 0.0)\n    {\n        vec3 _1866 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1866;\n        if (dot(_1866, _1866) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1880 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1880.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1880.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1880.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1884 = t;\n        vec3 _1885 = normalize(_1884);\n        t = _1885;\n        vec3 _1910 = normalize((_1885 * cos(s.anisotropy_rotation)) + ((cross(n, _1885) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3701 = _1910;\n        _3702 = cross(n, _1910);\n        float _1920 = roughness * roughness;\n        float _1926 = mix(_1920, 1.0, _1851 * _1851);\n        bool _1928 = _1851 > 0.0;\n        _3703 = _1928 ? _1926 : _1920;\n        _3704 = _1928 ? _1920 : _1926;\n        _3700 = _1851;\n        _3684 = true;\n    }\n    return FaLayers(_3684, _3685, _3686, _3687, _3688, _3689, _3690, _3691, i.world_normal, _3693, _3694, _3695, _3696, _3697, _3698, _3699, _3700, _3701, _3702, _3703, _3704);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _360 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _366 = fa_light_texel(param_1);\n    float _369 = _366.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _375 = _369 < 0.5;\n    vec3 l;\n    if (_375)\n    {\n        l = normalize(_360.xyz);\n    }\n    else\n    {\n        vec3 _387 = _360.xyz - world_pos;\n        float _389 = length(_387);\n        dist = _389;\n        l = _387 / vec3(max(_389, 9.9999997473787516355514526367188e-05));\n        float _404 = _389 / max(_360.w, 0.001000000047497451305389404296875);\n        float _410 = clamp(1.0 - (_404 * _404), 0.0, 1.0);\n        atten = _410 * _410;\n        if (_369 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _424 = fa_light_texel(param_2);\n            float _434 = _424.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _440 = fa_light_texel(param_3);\n            float _441 = _440.x;\n            float cos_inner = _441;\n            if (_441 > 1.5)\n            {\n                cos_inner = mix(_434, 1.0, 0.25);\n            }\n            atten *= smoothstep(_434, cos_inner, dot(-l, normalize(_424.xyz)));\n        }\n    }\n    int _472;\n    if (_375)\n    {\n        _472 = 0;\n    }\n    else\n    {\n        _472 = (_369 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _366.xyz * atten, atten, 1.0, dist, _472);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _712;\n    if (i == 0)\n    {\n        _712 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _728;\n        if (i == 1)\n        {\n            _728 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _736;\n            if (i == 2)\n            {\n                _736 = fa_shadows[24].z;\n            }\n            else\n            {\n                _736 = fa_shadows[24].w;\n            }\n            _728 = _736;\n        }\n        _712 = _728;\n    }\n    return _712;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _700 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_700), sin(_700)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _774 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _779 = clamp(dot(n, l), 0.0, 1.0);\n    float _785 = sqrt(1.0 - (_779 * _779));\n    float _793 = min(_785 / max(_779, 0.20000000298023223876953125), 4.0);\n    float _798;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _798 = fa_shadows[26].y;\n    }\n    else\n    {\n        _798 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _823 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_798 * _785)), 1.0);\n    float _830 = _823.x;\n    bool _833 = _830 < fa_shadows[ci * 1 + 16].x;\n    bool _842;\n    if (!_833)\n    {\n        _842 = _830 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _842 = _833;\n    }\n    bool _851;\n    if (!_842)\n    {\n        _851 = _823.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _851 = _842;\n    }\n    bool _860;\n    if (!_851)\n    {\n        _860 = _823.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _860 = _851;\n    }\n    bool _867;\n    if (!_860)\n    {\n        _867 = _823.z > 1.0;\n    }\n    else\n    {\n        _867 = _860;\n    }\n    if (_867)\n    {\n        return -1.0;\n    }\n    float _876;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _876 = fa_shadows[26].x;\n    }\n    else\n    {\n        _876 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _895 = _823.z - ((_876 * (1.0 + (0.5 * _793))) / _774);\n    float _904 = ((fa_shadows[ci * 1 + 20].x * min(_793, 3.0)) * 0.5) / _774;\n    int _913 = int(fa_shadows[25].z + 0.5);\n    if (_913 == 1)\n    {\n        vec2 param = _823.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _924 = fa_shadow_depth(param, param_1);\n        return float(_895 <= _924);\n    }\n    float _931 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _934 = _913 == 2;\n    if (_934)\n    {\n        float _948 = clamp(((fa_shadows[25].w * _774) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _931;\n            vec2 _967 = fa_shadow_vogel(param_2, param_3, param_4) * _948;\n            vec2 param_5 = _823.xy + (_967 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _978 = fa_shadow_depth(param_5, param_6);\n            if (_978 < (_895 - (length(_967) * _904)))\n            {\n                sum += _978;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_895 - (sum / cnt), 0.0) * _774) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1022 = _934 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1022; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1022;\n        float param_9 = _931;\n        vec2 _1041 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _823.xy + (_1041 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1052 = fa_shadow_depth(param_10, param_11);\n        lit += float((_895 - (length(_1041) * _904)) <= _1052);\n    }\n    return lit / float(_1022);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1082 = int(fa_shadows[25].x + 0.5);\n    if (_1082 < 1)\n    {\n        return 1.0;\n    }\n    float _1098 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1082 - 1;\n    if (_1098 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1110 = _1082 > 1;\n    bool _1117;\n    if (_1110)\n    {\n        _1117 = _1098 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1117 = _1110;\n    }\n    if (_1117)\n    {\n        ci = 1;\n    }\n    bool _1121 = _1082 > 2;\n    bool _1128;\n    if (_1121)\n    {\n        _1128 = _1098 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1128 = _1121;\n    }\n    if (_1128)\n    {\n        ci = 2;\n    }\n    bool _1132 = _1082 > 3;\n    bool _1139;\n    if (_1132)\n    {\n        _1139 = _1098 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1139 = _1132;\n    }\n    if (_1139)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1082)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1165 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1165;\n        if (_1165 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1190;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1190 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1190 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1209 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1190, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1220 = clamp((_1098 - (fa_shadow_split_at(param_7) - _1209)) / _1209, 0.0, 1.0);\n        if (_1220 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1082)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1241 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1241;\n                if (_1241 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1220);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2462 = fa_lm.z > 0.5;\n    bool _2468;\n    if (_2462)\n    {\n        int param = li;\n        _2468 = fa_light_baked(param);\n    }\n    else\n    {\n        _2468 = _2462;\n    }\n    if (_2468)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2490 = fa_light_sample(param_2, param_3);\n    vec3 _3746 = _2490.direction;\n    vec3 _3741 = _2490.color;\n    float _3743 = _2490.shadow;\n    int _3751 = _2490.type;\n    if ((_3751 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3746;\n        float _2504 = fa_shadow_factor(param_4, param_5);\n        _3743 = _2504;\n        _3741 *= _2504;\n    }\n    return LightSample(_3746, _3741, _2490.attenuation, _3743, _2490._distance, _3751);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2078 = tdh / at;\n    float _2082 = bdh / ab;\n    float _2094 = ((_2078 * _2078) + (_2082 * _2082)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2094) * _2094);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2175 = 1.0 / alpha;\n    return ((2.0 + _2175) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2175)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2208 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2287 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2287) * _2287);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2208);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2208));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2360 = max(dot(L.nc, l), 0.0);\n        float _2366 = max(dot(L.nc, h), 0.0);\n        float _2375 = ((_2366 * _2366) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2375) * _2375)) * (0.5 / max(mix((2.0 * _2360) * L.coat_ndv, _2360 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2360)) * _2360);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1473 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1476 = _1473.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1476 * _1476, exp2((-9.27999973297119140625) * ndv)) * _1476) + _1473.y)) + _1473.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1378 = rough * rough;\n    float _1408 = 0.60000002384185791015625 * _1378;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1378)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1408, 0.0500000007450580596923828125 + _1408, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1378 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1961;\n        if (L.aniso >= 0.0)\n        {\n            _1961 = L.b;\n        }\n        else\n        {\n            _1961 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1961, v), _1961), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1994 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1994.x) + (vec3(L.f90) * _1994.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2049 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2049.x) + _2049.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1515 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1515.x) + vec3(_1515.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1265 = int(fa_shadows[25].x + 0.5);\n    float _1275 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1280 = _1265 > 0;\n    bool _1289;\n    if (_1280)\n    {\n        int param = _1265 - 1;\n        _1289 = _1275 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    if (_1289)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1296 = _1265 > 1;\n        bool _1303;\n        if (_1296)\n        {\n            _1303 = _1275 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1303 = _1296;\n        }\n        if (_1303)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1309 = _1265 > 2;\n        bool _1316;\n        if (_1309)\n        {\n            _1316 = _1275 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1316 = _1309;\n        }\n        if (_1316)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1322 = _1265 > 3;\n        bool _1329;\n        if (_1322)\n        {\n            _1329 = _1275 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1329 = _1322;\n        }\n        if (_1329)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3463 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3463 = -_3463;\n    }\n    vec3 _2894 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3463, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing);\n    Surface _2902 = fa_standard_surface(param_1);\n    vec3 _3494 = _2902.albedo;\n    float _3495 = _2902.alpha;\n    vec3 _3496 = _2902.normal;\n    float _3497 = _2902.metallic;\n    float _3498 = _2902.roughness;\n    float _3499 = _2902.occlusion;\n    vec3 _3500 = _2902.emission;\n    float _3501 = _2902.clearcoat;\n    float _3502 = _2902.clearcoat_roughness;\n    vec3 _3503 = _2902.sheen_color;\n    float _3504 = _2902.sheen_roughness;\n    float _3505 = _2902.anisotropy;\n    float _3506 = _2902.anisotropy_rotation;\n    float _3507 = _2902.specular;\n    float _3508 = _2902.ior;\n    vec3 _3509 = _2902.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3463, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing);\n    Surface param_3 = _2902;\n    surface(param_2, param_3);\n    _3494 = param_3.albedo;\n    _3495 = param_3.alpha;\n    _3496 = param_3.normal;\n    _3497 = param_3.metallic;\n    _3498 = param_3.roughness;\n    _3499 = param_3.occlusion;\n    _3500 = param_3.emission;\n    _3501 = param_3.clearcoat;\n    _3502 = param_3.clearcoat_roughness;\n    _3503 = param_3.sheen_color;\n    _3504 = param_3.sheen_roughness;\n    _3505 = param_3.anisotropy;\n    _3506 = param_3.anisotropy_rotation;\n    _3507 = param_3.specular;\n    _3508 = param_3.ior;\n    _3509 = param_3.specular_color;\n    if (param_3.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3494;\n    }\n    else\n    {\n        vec3 _2935 = normalize(_3496);\n        float _2942 = clamp(_3497, 0.0, 1.0);\n        float _2946 = clamp(_3498, 0.0500000007450580596923828125, 1.0);\n        float _2950 = _2946 * _2946;\n        float _2954 = _2950 * _2950;\n        float _2959 = max(dot(_2935, _2894), 9.9999997473787516355514526367188e-05);\n        vec3 _2965 = _3494 * (1.0 - _2942);\n        vec3 _2972 = mix(vec3(0.039999999105930328369140625), _3494, vec3(_2942));\n        vec3 f0 = _2972;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3463, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing);\n        Surface param_5 = Surface(_3494, _3495, _3496, _3497, _3498, _3499, _3500, _3501, _3502, _3503, _3504, _3505, _3506, _3507, _3508, _3509);\n        vec3 param_6 = _2935;\n        vec3 param_7 = _2894;\n        float param_8 = _2942;\n        float param_9 = _2946;\n        vec3 param_10 = _2972;\n        FaLayers _2988 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _2935;\n        vec3 lit = (fa_indirect_diffuse(param_11) * _2965) * _3499;\n        if (_2988.on)\n        {\n            lit *= _2988.base_scale;\n        }\n        int _3010 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3010; ln++)\n        {\n            int param_12 = ln;\n            int _3023 = fa_cl_light(param_12);\n            bool _3026 = fa_lm.z > 0.5;\n            bool _3032;\n            if (_3026)\n            {\n                int param_13 = _3023;\n                _3032 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3032 = _3026;\n            }\n            if (_3032)\n            {\n                continue;\n            }\n            int param_14 = _3023;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3463;\n            LightSample _3044 = fa_light_shadowed(param_14, param_15, param_16);\n            vec3 _3668 = _3044.direction;\n            float _3052 = max(dot(_2935, _3668), 0.0);\n            float _3058 = _3044.attenuation * _3044.shadow;\n            vec3 _3063 = normalize(_3668 + _2894);\n            float _3068 = max(dot(_2935, _3063), 0.0);\n            float _3073 = max(dot(_2894, _3063), 0.0);\n            if (_2988.on)\n            {\n                FaLayers param_17 = _2988;\n                vec3 param_18 = _2965;\n                vec3 param_19 = f0;\n                vec3 param_20 = _2935;\n                vec3 param_21 = _2894;\n                vec3 param_22 = _3668;\n                vec3 param_23 = _3063;\n                float param_24 = _3052;\n                float param_25 = _2959;\n                float param_26 = _3068;\n                float param_27 = _3073;\n                float param_28 = _2950;\n                float param_29 = _2954;\n                int param_30 = _3023;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3058));\n            }\n            else\n            {\n                float _3121 = ((_3068 * _3068) * (_2954 - 1.0)) + 1.0;\n                int param_31 = _3023;\n                lit += (((_2965 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3073, 5.0))) * (((_2954 / ((3.1415927410125732421875 * _3121) * _3121)) * (0.5 / max(mix((2.0 * _3052) * _2959, _3052 + _2959, _2950), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3052))) * fa_light_rgb(param_31)) * (_3052 * _3058));\n            }\n        }\n        if (_2988.on)\n        {\n            FaLayers param_32 = _2988;\n            vec3 param_33 = _2935;\n            vec3 param_34 = _2894;\n            vec3 param_35 = f0;\n            float param_36 = _2946;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3499);\n        }\n        else\n        {\n            vec3 param_37 = _2935;\n            vec3 param_38 = _2894;\n            vec3 param_39 = f0;\n            float param_40 = _2946;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3499);\n        }\n        result = lit;\n    }\n    vec3 _3214 = result;\n    vec3 _3215 = _3214 + _3500;\n    result = _3215;\n    vec3 param_41 = _3215;\n    vec3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3224 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3231;\n    if (!_3224)\n    {\n        _3231 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3231 = _3224;\n    }\n    if (_3231)\n    {\n        vec3 _3240 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3246 = dot(_3240, fa_mesh_fs_params[9].xyz);\n        bool _3250 = fa_mesh_fs_params[9].w > 0.5;\n        float _3251;\n        if (_3250)\n        {\n            _3251 = _3246;\n        }\n        else\n        {\n            _3251 = length(_3240);\n        }\n        float _3263 = _3251 - fa_mesh_fs_params[8].x;\n        if (_3263 > 0.0)\n        {\n            float _3272 = fa_mesh_fs_params[7].w * _3263;\n            float tau = _3272 * _3272;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3288;\n                if (_3250)\n                {\n                    _3288 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3246);\n                }\n                else\n                {\n                    _3288 = fa_mesh_fs_params[0].y;\n                }\n                float _3309 = mix(_3288, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3251, 0.0, 1.0));\n                float _3313 = fa_world_pos.y - _3309;\n                float _3318 = _3309 - fa_mesh_fs_params[8].z;\n                float _3323 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3326 = _3318 <= 0.0;\n                bool _3327 = !_3326;\n                bool _3333;\n                if (_3327)\n                {\n                    _3333 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3333 = _3326;\n                }\n                float _3334;\n                if (_3333)\n                {\n                    _3334 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3334 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3318, 80.0));\n                }\n                bool _3361;\n                if (_3327)\n                {\n                    _3361 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3361 = _3326;\n                }\n                float _3362;\n                if (_3361)\n                {\n                    _3362 = fa_mesh_fs_params[8].y * _3318;\n                }\n                else\n                {\n                    _3362 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3318, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3387 = _3323 <= 0.0;\n                bool _3394;\n                if (!_3387)\n                {\n                    _3394 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3394 = _3387;\n                }\n                float _3395;\n                if (_3394)\n                {\n                    _3395 = fa_mesh_fs_params[8].y * _3323;\n                }\n                else\n                {\n                    _3395 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3323, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3422;\n                if (abs(_3313) < 0.001000000047497451305389404296875)\n                {\n                    _3422 = _3334;\n                }\n                else\n                {\n                    _3422 = (_3395 - _3362) / _3313;\n                }\n                tau += (_3263 * max(_3422, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3495);\n}\n\n",
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
            "inst_name": "_486",
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
            "inst_name": "_722",
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
            "inst_name": "_2913",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1616[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _491 = fa_mesh_fs_params[19].x < 0.0;\n    bool _498;\n    if (!_491)\n    {\n        _498 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _498 = _491;\n    }\n    bool _506;\n    if (!_498)\n    {\n        _506 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _506 = _498;\n    }\n    bool _513;\n    if (!_506)\n    {\n        _513 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _513 = _506;\n    }\n    bool _520;\n    if (!_513)\n    {\n        _520 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _520 = _513;\n    }\n    if (_520)\n    {\n        return ivec2(0);\n    }\n    vec4 _530 = vec4(world_pos, 1.0);\n    float _537 = dot(fa_mesh_fs_params[16], _530);\n    if (!(_537 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _559 = vec2(dot(fa_mesh_fs_params[14], _530), dot(fa_mesh_fs_params[15], _530)) / vec2(_537);\n    int _563 = int(fa_mesh_fs_params[18].x);\n    int _567 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _567) + clamp(int(floor(((_559.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _567 - 1)) * _563)) + clamp(int(floor(((_559.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _563 - 1);\n    vec4 _638 = fa_light_texel(param);\n    return ivec2(int(_638.x), int(_638.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2435 = fa_cluster_lookup(param);\n    fa_cl_slot = _2435.x;\n    fa_cl_local = _2435.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2562 = fa_linear_to_srgb(param);\n        c = _2562;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2570 = fa_srgb_to_linear(param_1);\n            c = _2570;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _241;\n    if (i.front_facing)\n    {\n        _241 = i.world_normal;\n    }\n    else\n    {\n        _241 = -i.world_normal;\n    }\n    vec3 _265 = normalize(i.world_tangent.xyz - (_241 * dot(_241, i.world_tangent.xyz)));\n    vec3 _293 = normalize(((_265 * m.x) + ((cross(_241, _265) * i.world_tangent.w) * m.y)) + (_241 * m.z));\n    vec3 _296;\n    if (i.front_facing)\n    {\n        _296 = _293;\n    }\n    else\n    {\n        _296 = -_293;\n    }\n    return _296;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2601 = fa_tex_fix(param_2, param_3);\n    vec4 _3827 = base_t;\n    _3827.x = _2601.x;\n    _3827.y = _2601.y;\n    _3827.z = _2601.z;\n    base_t = _3827;\n    vec4 _2615 = (_3827 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3761 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2647 = fa_tex_fix(param_6, param_7);\n        vec3 _2650 = (_2647 * 2.0) - vec3(1.0);\n        vec2 _2655 = _2650.xy * fa_mesh_fs_params[6].x;\n        vec3 _3835 = _2650;\n        _3835.x = _2655.x;\n        _3835.y = _2655.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3835;\n        _3761 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2684 = fa_tex_fix(param_12, param_13);\n    vec4 _3838 = mrt;\n    _3838.x = _2684.x;\n    _3838.y = _2684.y;\n    _3838.z = _2684.z;\n    mrt = _3838;\n    vec4 _2712 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2712.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2724 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2754 = fa_tex_fix(param_20, param_21);\n    float _3766 = fa_mesh_fs_params[20].x;\n    float _3767 = fa_mesh_fs_params[20].y;\n    float _3770 = fa_mesh_fs_params[20].z;\n    float _3769 = fa_mesh_fs_params[21].w;\n    float _3772 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3766 *= _2724.y;\n            _3767 *= _2724.z;\n            _3769 *= _2712.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3770 *= mrt.x;\n            _3772 *= mrt.w;\n        }\n    }\n    return Surface(_2615.xyz, _2615.w, _3761, clamp(fa_mesh_fs_params[5].x * _2684.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2684.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2724.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2754), _3766, _3767, fa_mesh_fs_params[21].xyz, _3769, _3770, fa_mesh_fs_params[20].w, _3772, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1541 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1549 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1552 = int(_1541);\n    int _1555 = int(_1549);\n    float _1565 = _1549 - float(_1555);\n    int _1621 = (_1552 * 9) + _1555;\n    int _1641 = ((_1552 + 1) * 9) + _1555;\n    return mix(mix(_1616[_1621], _1616[_1621 + 1], _1565), mix(_1616[_1641], _1616[_1641 + 1], _1565), _1541 - float(_1552));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3684 = false;\n    float _3685 = 1.0;\n    float _3686 = 1.0;\n    float _3687 = 1.0;\n    float _3688 = 0.0;\n    float _3689 = 0.0;\n    float _3690 = 0.0;\n    float _3691 = 0.0;\n    float _3693 = 1.0;\n    bool _3694 = false;\n    vec3 _3695 = vec3(0.0);\n    float _3696 = 1.0;\n    float _3697 = 1.0;\n    float _3698 = 1.0;\n    float _3699 = 0.0;\n    float _3700 = 0.0;\n    vec3 _3701 = vec3(1.0, 0.0, 0.0);\n    vec3 _3702 = vec3(0.0, 0.0, 1.0);\n    float _3703 = 1.0;\n    float _3704 = 1.0;\n    float _1696 = clamp(s.specular, 0.0, 1.0);\n    float _1700 = clamp(s.ior, 1.0, 3.0);\n    bool _1705 = (_1696 != 1.0) || (_1700 != 1.5);\n    bool _1715;\n    if (!_1705)\n    {\n        _1715 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1715 = _1705;\n    }\n    if (_1715)\n    {\n        float _1723 = (_1700 - 1.0) / (_1700 + 1.0);\n        f0 = mix(min(vec3(_1723 * _1723) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1696, s.albedo, vec3(metallic));\n        _3685 = mix(_1696, 1.0, metallic);\n        _3684 = true;\n    }\n    float _1751 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1751 > 0.0)\n    {\n        float _1759 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3688 = _1751;\n        _3689 = _1759;\n        float _1766 = _1759 * _1759;\n        _3690 = _1766;\n        _3691 = _1766 * _1766;\n        float _1778 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3693 = _1778;\n        _3686 = 1.0 - (_1751 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1778, 0.0, 1.0), 5.0))));\n        _3684 = true;\n    }\n    vec3 _1798 = max(s.sheen_color, vec3(0.0));\n    float _1807 = max(_1798.x, max(_1798.y, _1798.z));\n    if (_1807 > 0.0)\n    {\n        float _1815 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3694 = true;\n        _3695 = _1798;\n        _3696 = _1815;\n        _3697 = _1815 * _1815;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1815;\n        float _1832 = fa_sheen_albedo(param, param_1);\n        _3699 = _1832;\n        _3698 = 1.0 - min(_1807 * _1832, 1.0);\n        _3684 = true;\n    }\n    _3687 = _3686 * _3698;\n    float _1851 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1851 != 0.0)\n    {\n        vec3 _1866 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1866;\n        if (dot(_1866, _1866) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1880 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1880.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1880.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1880.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1884 = t;\n        vec3 _1885 = normalize(_1884);\n        t = _1885;\n        vec3 _1910 = normalize((_1885 * cos(s.anisotropy_rotation)) + ((cross(n, _1885) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3701 = _1910;\n        _3702 = cross(n, _1910);\n        float _1920 = roughness * roughness;\n        float _1926 = mix(_1920, 1.0, _1851 * _1851);\n        bool _1928 = _1851 > 0.0;\n        _3703 = _1928 ? _1926 : _1920;\n        _3704 = _1928 ? _1920 : _1926;\n        _3700 = _1851;\n        _3684 = true;\n    }\n    return FaLayers(_3684, _3685, _3686, _3687, _3688, _3689, _3690, _3691, i.world_normal, _3693, _3694, _3695, _3696, _3697, _3698, _3699, _3700, _3701, _3702, _3703, _3704);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _360 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _366 = fa_light_texel(param_1);\n    float _369 = _366.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _375 = _369 < 0.5;\n    vec3 l;\n    if (_375)\n    {\n        l = normalize(_360.xyz);\n    }\n    else\n    {\n        vec3 _387 = _360.xyz - world_pos;\n        float _389 = length(_387);\n        dist = _389;\n        l = _387 / vec3(max(_389, 9.9999997473787516355514526367188e-05));\n        float _404 = _389 / max(_360.w, 0.001000000047497451305389404296875);\n        float _410 = clamp(1.0 - (_404 * _404), 0.0, 1.0);\n        atten = _410 * _410;\n        if (_369 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _424 = fa_light_texel(param_2);\n            float _434 = _424.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _440 = fa_light_texel(param_3);\n            float _441 = _440.x;\n            float cos_inner = _441;\n            if (_441 > 1.5)\n            {\n                cos_inner = mix(_434, 1.0, 0.25);\n            }\n            atten *= smoothstep(_434, cos_inner, dot(-l, normalize(_424.xyz)));\n        }\n    }\n    int _472;\n    if (_375)\n    {\n        _472 = 0;\n    }\n    else\n    {\n        _472 = (_369 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _366.xyz * atten, atten, 1.0, dist, _472);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _712;\n    if (i == 0)\n    {\n        _712 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _728;\n        if (i == 1)\n        {\n            _728 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _736;\n            if (i == 2)\n            {\n                _736 = fa_shadows[24].z;\n            }\n            else\n            {\n                _736 = fa_shadows[24].w;\n            }\n            _728 = _736;\n        }\n        _712 = _728;\n    }\n    return _712;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _700 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_700), sin(_700)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _774 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _779 = clamp(dot(n, l), 0.0, 1.0);\n    float _785 = sqrt(1.0 - (_779 * _779));\n    float _793 = min(_785 / max(_779, 0.20000000298023223876953125), 4.0);\n    float _798;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _798 = fa_shadows[26].y;\n    }\n    else\n    {\n        _798 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _823 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_798 * _785)), 1.0);\n    float _830 = _823.x;\n    bool _833 = _830 < fa_shadows[ci * 1 + 16].x;\n    bool _842;\n    if (!_833)\n    {\n        _842 = _830 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _842 = _833;\n    }\n    bool _851;\n    if (!_842)\n    {\n        _851 = _823.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _851 = _842;\n    }\n    bool _860;\n    if (!_851)\n    {\n        _860 = _823.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _860 = _851;\n    }\n    bool _867;\n    if (!_860)\n    {\n        _867 = _823.z > 1.0;\n    }\n    else\n    {\n        _867 = _860;\n    }\n    if (_867)\n    {\n        return -1.0;\n    }\n    float _876;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _876 = fa_shadows[26].x;\n    }\n    else\n    {\n        _876 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _895 = _823.z - ((_876 * (1.0 + (0.5 * _793))) / _774);\n    float _904 = ((fa_shadows[ci * 1 + 20].x * min(_793, 3.0)) * 0.5) / _774;\n    int _913 = int(fa_shadows[25].z + 0.5);\n    if (_913 == 1)\n    {\n        vec2 param = _823.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _924 = fa_shadow_depth(param, param_1);\n        return float(_895 <= _924);\n    }\n    float _931 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _934 = _913 == 2;\n    if (_934)\n    {\n        float _948 = clamp(((fa_shadows[25].w * _774) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _931;\n            vec2 _967 = fa_shadow_vogel(param_2, param_3, param_4) * _948;\n            vec2 param_5 = _823.xy + (_967 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _978 = fa_shadow_depth(param_5, param_6);\n            if (_978 < (_895 - (length(_967) * _904)))\n            {\n                sum += _978;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_895 - (sum / cnt), 0.0) * _774) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1022 = _934 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1022; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1022;\n        float param_9 = _931;\n        vec2 _1041 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _823.xy + (_1041 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1052 = fa_shadow_depth(param_10, param_11);\n        lit += float((_895 - (length(_1041) * _904)) <= _1052);\n    }\n    return lit / float(_1022);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1082 = int(fa_shadows[25].x + 0.5);\n    if (_1082 < 1)\n    {\n        return 1.0;\n    }\n    float _1098 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1082 - 1;\n    if (_1098 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1110 = _1082 > 1;\n    bool _1117;\n    if (_1110)\n    {\n        _1117 = _1098 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1117 = _1110;\n    }\n    if (_1117)\n    {\n        ci = 1;\n    }\n    bool _1121 = _1082 > 2;\n    bool _1128;\n    if (_1121)\n    {\n        _1128 = _1098 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1128 = _1121;\n    }\n    if (_1128)\n    {\n        ci = 2;\n    }\n    bool _1132 = _1082 > 3;\n    bool _1139;\n    if (_1132)\n    {\n        _1139 = _1098 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1139 = _1132;\n    }\n    if (_1139)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1082)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1165 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1165;\n        if (_1165 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1190;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1190 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1190 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1209 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1190, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1220 = clamp((_1098 - (fa_shadow_split_at(param_7) - _1209)) / _1209, 0.0, 1.0);\n        if (_1220 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1082)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1241 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1241;\n                if (_1241 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1220);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2462 = fa_lm.z > 0.5;\n    bool _2468;\n    if (_2462)\n    {\n        int param = li;\n        _2468 = fa_light_baked(param);\n    }\n    else\n    {\n        _2468 = _2462;\n    }\n    if (_2468)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2490 = fa_light_sample(param_2, param_3);\n    vec3 _3746 = _2490.direction;\n    vec3 _3741 = _2490.color;\n    float _3743 = _2490.shadow;\n    int _3751 = _2490.type;\n    if ((_3751 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3746;\n        float _2504 = fa_shadow_factor(param_4, param_5);\n        _3743 = _2504;\n        _3741 *= _2504;\n    }\n    return LightSample(_3746, _3741, _2490.attenuation, _3743, _2490._distance, _3751);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _2078 = tdh / at;\n    float _2082 = bdh / ab;\n    float _2094 = ((_2078 * _2078) + (_2082 * _2082)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _2094) * _2094);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _2175 = 1.0 / alpha;\n    return ((2.0 + _2175) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _2175)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _2208 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _2287 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _2287) * _2287);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _2208);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _2208));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _2360 = max(dot(L.nc, l), 0.0);\n        float _2366 = max(dot(L.nc, h), 0.0);\n        float _2375 = ((_2366 * _2366) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _2375) * _2375)) * (0.5 / max(mix((2.0 * _2360) * L.coat_ndv, _2360 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2360)) * _2360);\n    }\n    return result;\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1473 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1476 = _1473.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1476 * _1476, exp2((-9.27999973297119140625) * ndv)) * _1476) + _1473.y)) + _1473.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1378 = rough * rough;\n    float _1408 = 0.60000002384185791015625 * _1378;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1378)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1408, 0.0500000007450580596923828125 + _1408, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1378 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1961;\n        if (L.aniso >= 0.0)\n        {\n            _1961 = L.b;\n        }\n        else\n        {\n            _1961 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1961, v), _1961), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1994 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1994.x) + (vec3(L.f90) * _1994.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2049 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2049.x) + _2049.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1515 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1515.x) + vec3(_1515.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1265 = int(fa_shadows[25].x + 0.5);\n    float _1275 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1280 = _1265 > 0;\n    bool _1289;\n    if (_1280)\n    {\n        int param = _1265 - 1;\n        _1289 = _1275 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    if (_1289)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1296 = _1265 > 1;\n        bool _1303;\n        if (_1296)\n        {\n            _1303 = _1275 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1303 = _1296;\n        }\n        if (_1303)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1309 = _1265 > 2;\n        bool _1316;\n        if (_1309)\n        {\n            _1316 = _1275 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1316 = _1309;\n        }\n        if (_1316)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1322 = _1265 > 3;\n        bool _1329;\n        if (_1322)\n        {\n            _1329 = _1275 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1329 = _1322;\n        }\n        if (_1329)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3463 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3463 = -_3463;\n    }\n    vec3 _2894 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3463, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing);\n    Surface _2902 = fa_standard_surface(param_1);\n    vec3 _3494 = _2902.albedo;\n    float _3495 = _2902.alpha;\n    vec3 _3496 = _2902.normal;\n    float _3497 = _2902.metallic;\n    float _3498 = _2902.roughness;\n    float _3499 = _2902.occlusion;\n    vec3 _3500 = _2902.emission;\n    float _3501 = _2902.clearcoat;\n    float _3502 = _2902.clearcoat_roughness;\n    vec3 _3503 = _2902.sheen_color;\n    float _3504 = _2902.sheen_roughness;\n    float _3505 = _2902.anisotropy;\n    float _3506 = _2902.anisotropy_rotation;\n    float _3507 = _2902.specular;\n    float _3508 = _2902.ior;\n    vec3 _3509 = _2902.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3463, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing);\n    Surface param_3 = _2902;\n    surface(param_2, param_3);\n    _3494 = param_3.albedo;\n    _3495 = param_3.alpha;\n    _3496 = param_3.normal;\n    _3497 = param_3.metallic;\n    _3498 = param_3.roughness;\n    _3499 = param_3.occlusion;\n    _3500 = param_3.emission;\n    _3501 = param_3.clearcoat;\n    _3502 = param_3.clearcoat_roughness;\n    _3503 = param_3.sheen_color;\n    _3504 = param_3.sheen_roughness;\n    _3505 = param_3.anisotropy;\n    _3506 = param_3.anisotropy_rotation;\n    _3507 = param_3.specular;\n    _3508 = param_3.ior;\n    _3509 = param_3.specular_color;\n    if (param_3.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3494;\n    }\n    else\n    {\n        vec3 _2935 = normalize(_3496);\n        float _2942 = clamp(_3497, 0.0, 1.0);\n        float _2946 = clamp(_3498, 0.0500000007450580596923828125, 1.0);\n        float _2950 = _2946 * _2946;\n        float _2954 = _2950 * _2950;\n        float _2959 = max(dot(_2935, _2894), 9.9999997473787516355514526367188e-05);\n        vec3 _2965 = _3494 * (1.0 - _2942);\n        vec3 _2972 = mix(vec3(0.039999999105930328369140625), _3494, vec3(_2942));\n        vec3 f0 = _2972;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3463, fa_world_tangent, fa_uv, fa_vertex_color, _2894, gl_FrontFacing);\n        Surface param_5 = Surface(_3494, _3495, _3496, _3497, _3498, _3499, _3500, _3501, _3502, _3503, _3504, _3505, _3506, _3507, _3508, _3509);\n        vec3 param_6 = _2935;\n        vec3 param_7 = _2894;\n        float param_8 = _2942;\n        float param_9 = _2946;\n        vec3 param_10 = _2972;\n        FaLayers _2988 = fa_layers_setup(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        f0 = param_10;\n        vec3 param_11 = _2935;\n        vec3 lit = (fa_indirect_diffuse(param_11) * _2965) * _3499;\n        if (_2988.on)\n        {\n            lit *= _2988.base_scale;\n        }\n        int _3010 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _3010; ln++)\n        {\n            int param_12 = ln;\n            int _3023 = fa_cl_light(param_12);\n            bool _3026 = fa_lm.z > 0.5;\n            bool _3032;\n            if (_3026)\n            {\n                int param_13 = _3023;\n                _3032 = fa_light_baked(param_13);\n            }\n            else\n            {\n                _3032 = _3026;\n            }\n            if (_3032)\n            {\n                continue;\n            }\n            int param_14 = _3023;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _3463;\n            LightSample _3044 = fa_light_shadowed(param_14, param_15, param_16);\n            vec3 _3668 = _3044.direction;\n            float _3052 = max(dot(_2935, _3668), 0.0);\n            float _3058 = _3044.attenuation * _3044.shadow;\n            vec3 _3063 = normalize(_3668 + _2894);\n            float _3068 = max(dot(_2935, _3063), 0.0);\n            float _3073 = max(dot(_2894, _3063), 0.0);\n            if (_2988.on)\n            {\n                FaLayers param_17 = _2988;\n                vec3 param_18 = _2965;\n                vec3 param_19 = f0;\n                vec3 param_20 = _2935;\n                vec3 param_21 = _2894;\n                vec3 param_22 = _3668;\n                vec3 param_23 = _3063;\n                float param_24 = _3052;\n                float param_25 = _2959;\n                float param_26 = _3068;\n                float param_27 = _3073;\n                float param_28 = _2950;\n                float param_29 = _2954;\n                int param_30 = _3023;\n                lit += (fa_layers_light(param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29) * (fa_light_rgb(param_30) * _3058));\n            }\n            else\n            {\n                float _3121 = ((_3068 * _3068) * (_2954 - 1.0)) + 1.0;\n                int param_31 = _3023;\n                lit += (((_2965 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _3073, 5.0))) * (((_2954 / ((3.1415927410125732421875 * _3121) * _3121)) * (0.5 / max(mix((2.0 * _3052) * _2959, _3052 + _2959, _2950), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _3052))) * fa_light_rgb(param_31)) * (_3052 * _3058));\n            }\n        }\n        if (_2988.on)\n        {\n            FaLayers param_32 = _2988;\n            vec3 param_33 = _2935;\n            vec3 param_34 = _2894;\n            vec3 param_35 = f0;\n            float param_36 = _2946;\n            lit += (fa_layers_ibl(param_32, param_33, param_34, param_35, param_36) * _3499);\n        }\n        else\n        {\n            vec3 param_37 = _2935;\n            vec3 param_38 = _2894;\n            vec3 param_39 = f0;\n            float param_40 = _2946;\n            lit += (fa_sky_reflection(param_37, param_38, param_39, param_40) * _3499);\n        }\n        result = lit;\n    }\n    vec3 _3214 = result;\n    vec3 _3215 = _3214 + _3500;\n    result = _3215;\n    vec3 param_41 = _3215;\n    vec3 param_42 = fa_world_pos;\n    result = fa_shadow_debug(param_41, param_42);\n    bool _3224 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3231;\n    if (!_3224)\n    {\n        _3231 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3231 = _3224;\n    }\n    if (_3231)\n    {\n        vec3 _3240 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3246 = dot(_3240, fa_mesh_fs_params[9].xyz);\n        bool _3250 = fa_mesh_fs_params[9].w > 0.5;\n        float _3251;\n        if (_3250)\n        {\n            _3251 = _3246;\n        }\n        else\n        {\n            _3251 = length(_3240);\n        }\n        float _3263 = _3251 - fa_mesh_fs_params[8].x;\n        if (_3263 > 0.0)\n        {\n            float _3272 = fa_mesh_fs_params[7].w * _3263;\n            float tau = _3272 * _3272;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3288;\n                if (_3250)\n                {\n                    _3288 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3246);\n                }\n                else\n                {\n                    _3288 = fa_mesh_fs_params[0].y;\n                }\n                float _3309 = mix(_3288, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3251, 0.0, 1.0));\n                float _3313 = fa_world_pos.y - _3309;\n                float _3318 = _3309 - fa_mesh_fs_params[8].z;\n                float _3323 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3326 = _3318 <= 0.0;\n                bool _3327 = !_3326;\n                bool _3333;\n                if (_3327)\n                {\n                    _3333 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3333 = _3326;\n                }\n                float _3334;\n                if (_3333)\n                {\n                    _3334 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3334 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3318, 80.0));\n                }\n                bool _3361;\n                if (_3327)\n                {\n                    _3361 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3361 = _3326;\n                }\n                float _3362;\n                if (_3361)\n                {\n                    _3362 = fa_mesh_fs_params[8].y * _3318;\n                }\n                else\n                {\n                    _3362 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3318, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3387 = _3323 <= 0.0;\n                bool _3394;\n                if (!_3387)\n                {\n                    _3394 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3394 = _3387;\n                }\n                float _3395;\n                if (_3394)\n                {\n                    _3395 = fa_mesh_fs_params[8].y * _3323;\n                }\n                else\n                {\n                    _3395 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3323, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3422;\n                if (abs(_3313) < 0.001000000047497451305389404296875)\n                {\n                    _3422 = _3334;\n                }\n                else\n                {\n                    _3422 = (_3395 - _3362) / _3313;\n                }\n                tau += (_3263 * max(_3422, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3495);\n}\n\n",
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
            "inst_name": "_486",
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
            "inst_name": "_722",
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
            "inst_name": "_2913",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _744 = base_t;\n    _744.x = _225.x;\n    _744.y = _225.y;\n    _744.z = _225.z;\n    base_t = _744;\n    vec4 _241 = (_744 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _707 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _752 = _279;\n        _752.x = _284.x;\n        _752.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _752;\n        _707 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _755 = mrt;\n    _755.x = _313.x;\n    _755.y = _313.y;\n    _755.z = _313.z;\n    mrt = _755;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _712 = fa_mesh_fs_params[20].x;\n    float _713 = fa_mesh_fs_params[20].y;\n    float _716 = fa_mesh_fs_params[20].z;\n    float _715 = fa_mesh_fs_params[21].w;\n    float _718 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _712 *= _355.y;\n            _713 *= _355.z;\n            _715 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _716 *= mrt.x;\n            _718 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _707, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _712, _713, fa_mesh_fs_params[21].xyz, _715, _716, fa_mesh_fs_params[20].w, _718, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _618 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _618 = -_618;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _618, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface _524 = fa_standard_surface(param);\n    vec3 _642 = _524.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _618, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = _524;\n    surface(param_1, param_2);\n    _642 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 _545 = normalize(_642);\n    vec3 _560 = normalize(vec3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    vec2 e = _560.xy / vec2((abs(_560.x) + abs(_560.y)) + abs(_572));\n    if (_572 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _744 = base_t;\n    _744.x = _225.x;\n    _744.y = _225.y;\n    _744.z = _225.z;\n    base_t = _744;\n    vec4 _241 = (_744 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _707 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _752 = _279;\n        _752.x = _284.x;\n        _752.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _752;\n        _707 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _755 = mrt;\n    _755.x = _313.x;\n    _755.y = _313.y;\n    _755.z = _313.z;\n    mrt = _755;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _712 = fa_mesh_fs_params[20].x;\n    float _713 = fa_mesh_fs_params[20].y;\n    float _716 = fa_mesh_fs_params[20].z;\n    float _715 = fa_mesh_fs_params[21].w;\n    float _718 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _712 *= _355.y;\n            _713 *= _355.z;\n            _715 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _716 *= mrt.x;\n            _718 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _707, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _712, _713, fa_mesh_fs_params[21].xyz, _715, _716, fa_mesh_fs_params[20].w, _718, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _618 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _618 = -_618;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _618, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface _524 = fa_standard_surface(param);\n    vec3 _642 = _524.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _618, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = _524;\n    surface(param_1, param_2);\n    _642 = param_2.normal;\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    vec3 _545 = normalize(_642);\n    vec3 _560 = normalize(vec3(dot(fa_pre_r0, _545), dot(fa_pre_r1, _545), dot(fa_pre_r2, _545)));\n    float _572 = _560.z;\n    vec2 e = _560.xy / vec2((abs(_560.x) + abs(_560.y)) + abs(_572));\n    if (_572 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _60 = cross(model[1].xyz, model[2].xyz);\n    float _66 = (dot(model[0].xyz, _60) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_60 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _66, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _66), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData _190 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _233 = _190.world_pos;\n    fa_world_pos = _233;\n    fa_world_normal = _190.world_normal;\n    fa_world_tangent = _190.world_tangent;\n    fa_uv = _190.uv;\n    fa_vertex_color = _190.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_233, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _678 = base_t;\n    _678.x = _225.x;\n    _678.y = _225.y;\n    _678.z = _225.z;\n    base_t = _678;\n    vec4 _241 = (_678 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _647 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _686 = _279;\n        _686.x = _284.x;\n        _686.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _686;\n        _647 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _689 = mrt;\n    _689.x = _313.x;\n    _689.y = _313.y;\n    _689.z = _313.z;\n    mrt = _689;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _652 = fa_mesh_fs_params[20].x;\n    float _653 = fa_mesh_fs_params[20].y;\n    float _656 = fa_mesh_fs_params[20].z;\n    float _655 = fa_mesh_fs_params[21].w;\n    float _658 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _652 *= _355.y;\n            _653 *= _355.z;\n            _655 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _656 *= mrt.x;\n            _658 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _647, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _652, _653, fa_mesh_fs_params[21].xyz, _655, _656, fa_mesh_fs_params[20].w, _658, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _558 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _558 = -_558;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _558, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _558, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_122",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _165 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_165 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_165 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_165 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _65 = cross(model[1].xyz, model[2].xyz);\n    float _71 = (dot(model[0].xyz, _65) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_65 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _71, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _71), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData _311 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vec3 _354 = _311.world_pos;\n    fa_world_pos = _354;\n    fa_world_normal = _311.world_normal;\n    fa_world_tangent = _311.world_tangent;\n    fa_uv = _311.uv;\n    fa_vertex_color = _311.color;\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(_354, 1.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _678 = base_t;\n    _678.x = _225.x;\n    _678.y = _225.y;\n    _678.z = _225.z;\n    base_t = _678;\n    vec4 _241 = (_678 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _647 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _686 = _279;\n        _686.x = _284.x;\n        _686.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _686;\n        _647 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _689 = mrt;\n    _689.x = _313.x;\n    _689.y = _313.y;\n    _689.z = _313.z;\n    mrt = _689;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _652 = fa_mesh_fs_params[20].x;\n    float _653 = fa_mesh_fs_params[20].y;\n    float _656 = fa_mesh_fs_params[20].z;\n    float _655 = fa_mesh_fs_params[21].w;\n    float _658 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _652 *= _355.y;\n            _653 *= _355.z;\n            _655 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _656 *= mrt.x;\n            _658 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _647, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _652, _653, fa_mesh_fs_params[21].xyz, _655, _656, fa_mesh_fs_params[20].w, _658, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _558 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _558 = -_558;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _558, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _558, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    if (param_2.alpha < fa_material[0].x)\n    {\n        discard;\n    }\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
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
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_127",
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
            "inst_name": "_174",
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_535",
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
