{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "3995aa0ba56be221fe15f8a0d00a1f706ae46d0f598c3711968fac755bdd80f5",
  "slang": "glsl430",
  "params": [
    "lift"
  ],
  "textures": [
    "height"
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    vec4 _200 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _200;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _200;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _783[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D height_height_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1659 = fa_linear_to_srgb(param);\n        c = _1659;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1667 = fa_srgb_to_linear(param_1);\n            c = _1667;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _167;\n    if (i.front_facing)\n    {\n        _167 = i.world_normal;\n    }\n    else\n    {\n        _167 = -i.world_normal;\n    }\n    vec3 _191 = normalize(i.world_tangent.xyz - (_167 * dot(_167, i.world_tangent.xyz)));\n    vec3 _219 = normalize(((_191 * m.x) + ((cross(_167, _191) * i.world_tangent.w) * m.y)) + (_167 * m.z));\n    vec3 _222;\n    if (i.front_facing)\n    {\n        _222 = _219;\n    }\n    else\n    {\n        _222 = -_219;\n    }\n    return _222;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1698 = fa_tex_fix(param_2, param_3);\n    vec4 _2858 = base_t;\n    _2858.x = _1698.x;\n    _2858.y = _1698.y;\n    _2858.z = _1698.z;\n    base_t = _2858;\n    vec4 _1712 = (_2858 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2801 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1745 = fa_tex_fix(param_6, param_7);\n        vec3 _1748 = (_1745 * 2.0) - vec3(1.0);\n        vec2 _1753 = _1748.xy * fa_mesh_fs_params[6].x;\n        vec3 _2866 = _1748;\n        _2866.x = _1753.x;\n        _2866.y = _1753.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2866;\n        _2801 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1782 = fa_tex_fix(param_12, param_13);\n    vec4 _2869 = mrt;\n    _2869.x = _1782.x;\n    _2869.y = _1782.y;\n    _2869.z = _1782.z;\n    mrt = _2869;\n    vec4 _1810 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1810.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1822 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1852 = fa_tex_fix(param_20, param_21);\n    float _2806 = fa_mesh_fs_params[14].x;\n    float _2807 = fa_mesh_fs_params[14].y;\n    float _2810 = fa_mesh_fs_params[14].z;\n    float _2809 = fa_mesh_fs_params[15].w;\n    float _2812 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2806 *= _1822.y;\n            _2807 *= _1822.z;\n            _2809 *= _1810.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2810 *= mrt.x;\n            _2812 *= mrt.w;\n        }\n    }\n    return Surface(_1712.xyz, _1712.w, _2801, clamp(fa_mesh_fs_params[5].x * _1782.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1782.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1822.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1852), _2806, _2807, fa_mesh_fs_params[15].xyz, _2809, _2810, fa_mesh_fs_params[14].w, _2812, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _708 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _716 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _719 = int(_708);\n    int _722 = int(_716);\n    float _732 = _716 - float(_722);\n    int _788 = (_719 * 9) + _722;\n    int _808 = ((_719 + 1) * 9) + _722;\n    return mix(mix(_783[_788], _783[_788 + 1], _732), mix(_783[_808], _783[_808 + 1], _732), _708 - float(_719));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2737 = false;\n    float _2738 = 1.0;\n    float _2739 = 1.0;\n    float _2740 = 1.0;\n    float _2741 = 0.0;\n    float _2742 = 0.0;\n    float _2743 = 0.0;\n    float _2744 = 0.0;\n    float _2746 = 1.0;\n    bool _2747 = false;\n    vec3 _2748 = vec3(0.0);\n    float _2749 = 1.0;\n    float _2750 = 1.0;\n    float _2751 = 1.0;\n    float _2752 = 0.0;\n    float _2753 = 0.0;\n    vec3 _2754 = vec3(1.0, 0.0, 0.0);\n    vec3 _2755 = vec3(0.0, 0.0, 1.0);\n    float _2756 = 1.0;\n    float _2757 = 1.0;\n    float _870 = clamp(s.specular, 0.0, 1.0);\n    float _875 = clamp(s.ior, 1.0, 3.0);\n    bool _880 = (_870 != 1.0) || (_875 != 1.5);\n    bool _890;\n    if (!_880)\n    {\n        _890 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _890 = _880;\n    }\n    if (_890)\n    {\n        float _898 = (_875 - 1.0) / (_875 + 1.0);\n        f0 = mix(min(vec3(_898 * _898) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _870, s.albedo, vec3(metallic));\n        _2738 = mix(_870, 1.0, metallic);\n        _2737 = true;\n    }\n    float _926 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_926 > 0.0)\n    {\n        float _934 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2741 = _926;\n        _2742 = _934;\n        float _941 = _934 * _934;\n        _2743 = _941;\n        _2744 = _941 * _941;\n        float _953 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2746 = _953;\n        _2739 = 1.0 - (_926 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(1.0 - _953, 5.0))));\n        _2737 = true;\n    }\n    vec3 _972 = max(s.sheen_color, vec3(0.0));\n    float _981 = max(_972.x, max(_972.y, _972.z));\n    if (_981 > 0.0)\n    {\n        float _989 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2747 = true;\n        _2748 = _972;\n        _2749 = _989;\n        _2750 = _989 * _989;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _989;\n        float _1006 = fa_sheen_albedo(param, param_1);\n        _2752 = _1006;\n        _2751 = 1.0 - min(_981 * _1006, 1.0);\n        _2737 = true;\n    }\n    _2740 = _2739 * _2751;\n    float _1025 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1025 != 0.0)\n    {\n        vec3 _1040 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1040;\n        if (dot(_1040, _1040) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1054 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1054.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1054.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1054.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1058 = t;\n        vec3 _1059 = normalize(_1058);\n        t = _1059;\n        vec3 _1084 = normalize((_1059 * cos(s.anisotropy_rotation)) + ((cross(n, _1059) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2754 = _1084;\n        _2755 = cross(n, _1084);\n        float _1094 = roughness * roughness;\n        float _1100 = mix(_1094, 1.0, _1025 * _1025);\n        bool _1102 = _1025 > 0.0;\n        _2756 = _1102 ? _1100 : _1094;\n        _2757 = _1102 ? _1094 : _1100;\n        _2753 = _1025;\n        _2737 = true;\n    }\n    return FaLayers(_2737, _2738, _2739, _2740, _2741, _2742, _2743, _2744, i.world_normal, _2746, _2747, _2748, _2749, _2750, _2751, _2752, _2753, _2754, _2755, _2756, _2757);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _250 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_250)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _268 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _270 = length(_268);\n        dist = _270;\n        l = _268 / vec3(max(_270, 9.9999997473787516355514526367188e-05));\n        float _286 = _270 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _292 = clamp(1.0 - (_286 * _286), 0.0, 1.0);\n        atten = _292 * _292;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _343;\n    if (_250)\n    {\n        _343 = 0;\n    }\n    else\n    {\n        _343 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _343);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _370 = coord.xyz / vec3(coord.w);\n    vec3 p = _370;\n    vec2 suv = (_370.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2833 = p;\n        _2833.z = (_2833.z * 0.5) + 0.5;\n        p = _2833;\n    }\n    else\n    {\n        vec2 _2836 = suv;\n        _2836.y = 1.0 - _2836.y;\n        suv = _2836;\n    }\n    bool _398 = suv.x < 0.0;\n    bool _405;\n    if (!_398)\n    {\n        _405 = suv.x > 1.0;\n    }\n    else\n    {\n        _405 = _398;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.y < 0.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y > 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = p.z > 1.0;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    if (_426)\n    {\n        return 1.0;\n    }\n    float _441 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _441) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1568 = fa_light_sample(param, param_1);\n    vec3 _2786 = _1568.direction;\n    vec3 _2781 = _1568.color;\n    float _2788 = _1568.attenuation;\n    float _2783 = _1568.shadow;\n    int _2791 = _1568.type;\n    if ((_2791 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2786;\n        float _1582 = fa_shadow_factor(param_2, param_3);\n        _2783 = _1582;\n        _2781 = fa_lights[li * 1 + 32].xyz * (_2788 * _1582);\n    }\n    return LightSample(_2786, _2781, _2788, _2783, _1568._distance, _2791);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1252 = at * ab;\n    vec3 _1263 = vec3(ab * tdh, at * bdh, _1252 * ndh);\n    float _1269 = _1252 / dot(_1263, _1263);\n    return ((_1252 * _1269) * _1269) * 0.3183098733425140380859375;\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    return clamp(0.5 / max((ndl * length(vec3(at * tdv, ab * bdv, ndv))) + (ndv * length(vec3(at * tdl, ab * bdl, ndl))), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    return ((2.0 + (1.0 / alpha)) * pow(max(1.0 - (ndh * ndh), 0.0078125), 0.5 / alpha)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / ((ndl + ndv) - (ndl * ndv)), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1347 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1425 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1425) * _1425);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(1.0 - vdh, 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1347);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1347));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1498 = max(dot(L.nc, l), 0.0);\n        float _1504 = max(dot(L.nc, h), 0.0);\n        float _1513 = ((_1504 * _1504) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(1.0 - vdh, 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1513) * _1513)) * (0.5 / max(mix((2.0 * _1498) * L.coat_ndv, _1498 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1498)) * _1498);\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _638 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _641 = _638.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_641 * _641, exp2((-9.27999973297119140625) * ndv)) * _641) + _638.y)) + _638.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _541 = rough * rough;\n    float _572 = 0.60000002384185791015625 * _541;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _541)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _572, 0.0500000007450580596923828125 + _572, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_541 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1135;\n        if (L.aniso >= 0.0)\n        {\n            _1135 = L.b;\n        }\n        else\n        {\n            _1135 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1135, v), _1135), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1168 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1168.x) + (vec3(L.f90) * _1168.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1223 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1223.x) + _1223.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _680 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _680.x) + vec3(_680.y));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2516 = -_2516;\n    }\n    vec3 _1972 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _1972, gl_FrontFacing);\n    Surface _1977 = fa_standard_surface(param);\n    vec3 _2547 = _1977.albedo;\n    float _2548 = _1977.alpha;\n    vec3 _2549 = _1977.normal;\n    float _2550 = _1977.metallic;\n    float _2551 = _1977.roughness;\n    float _2552 = _1977.occlusion;\n    vec3 _2553 = _1977.emission;\n    float _2554 = _1977.clearcoat;\n    float _2555 = _1977.clearcoat_roughness;\n    vec3 _2556 = _1977.sheen_color;\n    float _2557 = _1977.sheen_roughness;\n    float _2558 = _1977.anisotropy;\n    float _2559 = _1977.anisotropy_rotation;\n    float _2560 = _1977.specular;\n    float _2561 = _1977.ior;\n    vec3 _2562 = _1977.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _1972, gl_FrontFacing);\n    Surface param_2 = _1977;\n    surface(param_1, param_2);\n    _2547 = param_2.albedo;\n    _2548 = param_2.alpha;\n    _2549 = param_2.normal;\n    _2550 = param_2.metallic;\n    _2551 = param_2.roughness;\n    _2552 = param_2.occlusion;\n    _2553 = param_2.emission;\n    _2554 = param_2.clearcoat;\n    _2555 = param_2.clearcoat_roughness;\n    _2556 = param_2.sheen_color;\n    _2557 = param_2.sheen_roughness;\n    _2558 = param_2.anisotropy;\n    _2559 = param_2.anisotropy_rotation;\n    _2560 = param_2.specular;\n    _2561 = param_2.ior;\n    _2562 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2547;\n    }\n    else\n    {\n        vec3 _1999 = normalize(_2549);\n        float _2006 = clamp(_2550, 0.0, 1.0);\n        float _2010 = clamp(_2551, 0.0500000007450580596923828125, 1.0);\n        float _2014 = _2010 * _2010;\n        float _2018 = _2014 * _2014;\n        float _2023 = max(dot(_1999, _1972), 9.9999997473787516355514526367188e-05);\n        vec3 _2029 = _2547 * (1.0 - _2006);\n        vec3 _2036 = mix(vec3(0.039999999105930328369140625), _2547, vec3(_2006));\n        vec3 f0 = _2036;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _1972, gl_FrontFacing);\n        Surface param_4 = Surface(_2547, _2548, _2549, _2550, _2551, _2552, _2553, _2554, _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562);\n        vec3 param_5 = _1999;\n        vec3 param_6 = _1972;\n        float param_7 = _2006;\n        float param_8 = _2010;\n        vec3 param_9 = _2036;\n        FaLayers _2052 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        vec3 param_10 = _1999;\n        vec3 lit = (fa_ambient_light(param_10) * _2029) * _2552;\n        if (_2052.on)\n        {\n            lit *= _2052.base_scale;\n        }\n        int _2074 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2074)\n            {\n                break;\n            }\n            int param_11 = li;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _2516;\n            LightSample _2098 = fa_light_shadowed(param_11, param_12, param_13);\n            vec3 _2721 = _2098.direction;\n            float _2106 = max(dot(_1999, _2721), 0.0);\n            float _2112 = _2098.attenuation * _2098.shadow;\n            vec3 _2117 = normalize(_2721 + _1972);\n            float _2122 = max(dot(_1999, _2117), 0.0);\n            float _2127 = max(dot(_1972, _2117), 0.0);\n            if (_2052.on)\n            {\n                FaLayers param_14 = _2052;\n                vec3 param_15 = _2029;\n                vec3 param_16 = f0;\n                vec3 param_17 = _1999;\n                vec3 param_18 = _1972;\n                vec3 param_19 = _2721;\n                vec3 param_20 = _2117;\n                float param_21 = _2106;\n                float param_22 = _2023;\n                float param_23 = _2122;\n                float param_24 = _2127;\n                float param_25 = _2014;\n                float param_26 = _2018;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (fa_lights[li * 1 + 32].xyz * _2112));\n            }\n            else\n            {\n                float _2176 = ((_2122 * _2122) * (_2018 - 1.0)) + 1.0;\n                lit += (((_2029 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _2127, 5.0))) * (((_2018 / ((3.1415927410125732421875 * _2176) * _2176)) * (0.5 / max(mix((2.0 * _2106) * _2023, _2106 + _2023, _2014), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2106))) * fa_lights[li * 1 + 32].xyz) * (_2106 * _2112));\n            }\n        }\n        if (_2052.on)\n        {\n            FaLayers param_27 = _2052;\n            vec3 param_28 = _1999;\n            vec3 param_29 = _1972;\n            vec3 param_30 = f0;\n            float param_31 = _2010;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2552);\n        }\n        else\n        {\n            vec3 param_32 = _1999;\n            vec3 param_33 = _1972;\n            vec3 param_34 = f0;\n            float param_35 = _2010;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2552);\n        }\n        result = lit;\n    }\n    result += _2553;\n    bool _2274 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2281;\n    if (!_2274)\n    {\n        _2281 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2281 = _2274;\n    }\n    if (_2281)\n    {\n        vec3 _2290 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2296 = dot(_2290, fa_mesh_fs_params[9].xyz);\n        bool _2300 = fa_mesh_fs_params[9].w > 0.5;\n        float _2301;\n        if (_2300)\n        {\n            _2301 = _2296;\n        }\n        else\n        {\n            _2301 = length(_2290);\n        }\n        float _2313 = _2301 - fa_mesh_fs_params[8].x;\n        if (_2313 > 0.0)\n        {\n            float _2322 = fa_mesh_fs_params[7].w * _2313;\n            float tau = _2322 * _2322;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2338;\n                if (_2300)\n                {\n                    _2338 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2296);\n                }\n                else\n                {\n                    _2338 = fa_mesh_fs_params[0].y;\n                }\n                float _2359 = mix(_2338, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2301, 0.0, 1.0));\n                float _2363 = fa_world_pos.y - _2359;\n                float _2368 = _2359 - fa_mesh_fs_params[8].z;\n                float _2373 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2376 = _2368 <= 0.0;\n                bool _2377 = !_2376;\n                bool _2383;\n                if (_2377)\n                {\n                    _2383 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2383 = _2376;\n                }\n                float _2384;\n                if (_2383)\n                {\n                    _2384 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2384 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2368, 80.0));\n                }\n                bool _2411;\n                if (_2377)\n                {\n                    _2411 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2411 = _2376;\n                }\n                float _2412;\n                if (_2411)\n                {\n                    _2412 = fa_mesh_fs_params[8].y * _2368;\n                }\n                else\n                {\n                    _2412 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2368, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2437 = _2373 <= 0.0;\n                bool _2444;\n                if (!_2437)\n                {\n                    _2444 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2444 = _2437;\n                }\n                float _2445;\n                if (_2444)\n                {\n                    _2445 = fa_mesh_fs_params[8].y * _2373;\n                }\n                else\n                {\n                    _2445 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2373, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2472;\n                if (abs(_2363) < 0.001000000047497451305389404296875)\n                {\n                    _2472 = _2384;\n                }\n                else\n                {\n                    _2472 = (_2445 - _2412) / _2363;\n                }\n                tau += (_2313 * max(_2472, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2548);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_239",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_357",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 18,
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
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
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
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
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "height_height_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_203 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_203 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_203 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    vec4 _313 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _313;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _313;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _783[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D height_height_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1659 = fa_linear_to_srgb(param);\n        c = _1659;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1667 = fa_srgb_to_linear(param_1);\n            c = _1667;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _167;\n    if (i.front_facing)\n    {\n        _167 = i.world_normal;\n    }\n    else\n    {\n        _167 = -i.world_normal;\n    }\n    vec3 _191 = normalize(i.world_tangent.xyz - (_167 * dot(_167, i.world_tangent.xyz)));\n    vec3 _219 = normalize(((_191 * m.x) + ((cross(_167, _191) * i.world_tangent.w) * m.y)) + (_167 * m.z));\n    vec3 _222;\n    if (i.front_facing)\n    {\n        _222 = _219;\n    }\n    else\n    {\n        _222 = -_219;\n    }\n    return _222;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1698 = fa_tex_fix(param_2, param_3);\n    vec4 _2858 = base_t;\n    _2858.x = _1698.x;\n    _2858.y = _1698.y;\n    _2858.z = _1698.z;\n    base_t = _2858;\n    vec4 _1712 = (_2858 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2801 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1745 = fa_tex_fix(param_6, param_7);\n        vec3 _1748 = (_1745 * 2.0) - vec3(1.0);\n        vec2 _1753 = _1748.xy * fa_mesh_fs_params[6].x;\n        vec3 _2866 = _1748;\n        _2866.x = _1753.x;\n        _2866.y = _1753.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2866;\n        _2801 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1782 = fa_tex_fix(param_12, param_13);\n    vec4 _2869 = mrt;\n    _2869.x = _1782.x;\n    _2869.y = _1782.y;\n    _2869.z = _1782.z;\n    mrt = _2869;\n    vec4 _1810 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1810.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1822 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1852 = fa_tex_fix(param_20, param_21);\n    float _2806 = fa_mesh_fs_params[14].x;\n    float _2807 = fa_mesh_fs_params[14].y;\n    float _2810 = fa_mesh_fs_params[14].z;\n    float _2809 = fa_mesh_fs_params[15].w;\n    float _2812 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2806 *= _1822.y;\n            _2807 *= _1822.z;\n            _2809 *= _1810.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2810 *= mrt.x;\n            _2812 *= mrt.w;\n        }\n    }\n    return Surface(_1712.xyz, _1712.w, _2801, clamp(fa_mesh_fs_params[5].x * _1782.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1782.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1822.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1852), _2806, _2807, fa_mesh_fs_params[15].xyz, _2809, _2810, fa_mesh_fs_params[14].w, _2812, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _708 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _716 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _719 = int(_708);\n    int _722 = int(_716);\n    float _732 = _716 - float(_722);\n    int _788 = (_719 * 9) + _722;\n    int _808 = ((_719 + 1) * 9) + _722;\n    return mix(mix(_783[_788], _783[_788 + 1], _732), mix(_783[_808], _783[_808 + 1], _732), _708 - float(_719));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2737 = false;\n    float _2738 = 1.0;\n    float _2739 = 1.0;\n    float _2740 = 1.0;\n    float _2741 = 0.0;\n    float _2742 = 0.0;\n    float _2743 = 0.0;\n    float _2744 = 0.0;\n    float _2746 = 1.0;\n    bool _2747 = false;\n    vec3 _2748 = vec3(0.0);\n    float _2749 = 1.0;\n    float _2750 = 1.0;\n    float _2751 = 1.0;\n    float _2752 = 0.0;\n    float _2753 = 0.0;\n    vec3 _2754 = vec3(1.0, 0.0, 0.0);\n    vec3 _2755 = vec3(0.0, 0.0, 1.0);\n    float _2756 = 1.0;\n    float _2757 = 1.0;\n    float _870 = clamp(s.specular, 0.0, 1.0);\n    float _875 = clamp(s.ior, 1.0, 3.0);\n    bool _880 = (_870 != 1.0) || (_875 != 1.5);\n    bool _890;\n    if (!_880)\n    {\n        _890 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _890 = _880;\n    }\n    if (_890)\n    {\n        float _898 = (_875 - 1.0) / (_875 + 1.0);\n        f0 = mix(min(vec3(_898 * _898) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _870, s.albedo, vec3(metallic));\n        _2738 = mix(_870, 1.0, metallic);\n        _2737 = true;\n    }\n    float _926 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_926 > 0.0)\n    {\n        float _934 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2741 = _926;\n        _2742 = _934;\n        float _941 = _934 * _934;\n        _2743 = _941;\n        _2744 = _941 * _941;\n        float _953 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2746 = _953;\n        _2739 = 1.0 - (_926 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(1.0 - _953, 5.0))));\n        _2737 = true;\n    }\n    vec3 _972 = max(s.sheen_color, vec3(0.0));\n    float _981 = max(_972.x, max(_972.y, _972.z));\n    if (_981 > 0.0)\n    {\n        float _989 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2747 = true;\n        _2748 = _972;\n        _2749 = _989;\n        _2750 = _989 * _989;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _989;\n        float _1006 = fa_sheen_albedo(param, param_1);\n        _2752 = _1006;\n        _2751 = 1.0 - min(_981 * _1006, 1.0);\n        _2737 = true;\n    }\n    _2740 = _2739 * _2751;\n    float _1025 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1025 != 0.0)\n    {\n        vec3 _1040 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1040;\n        if (dot(_1040, _1040) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1054 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1054.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1054.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1054.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1058 = t;\n        vec3 _1059 = normalize(_1058);\n        t = _1059;\n        vec3 _1084 = normalize((_1059 * cos(s.anisotropy_rotation)) + ((cross(n, _1059) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2754 = _1084;\n        _2755 = cross(n, _1084);\n        float _1094 = roughness * roughness;\n        float _1100 = mix(_1094, 1.0, _1025 * _1025);\n        bool _1102 = _1025 > 0.0;\n        _2756 = _1102 ? _1100 : _1094;\n        _2757 = _1102 ? _1094 : _1100;\n        _2753 = _1025;\n        _2737 = true;\n    }\n    return FaLayers(_2737, _2738, _2739, _2740, _2741, _2742, _2743, _2744, i.world_normal, _2746, _2747, _2748, _2749, _2750, _2751, _2752, _2753, _2754, _2755, _2756, _2757);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _250 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_250)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _268 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _270 = length(_268);\n        dist = _270;\n        l = _268 / vec3(max(_270, 9.9999997473787516355514526367188e-05));\n        float _286 = _270 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _292 = clamp(1.0 - (_286 * _286), 0.0, 1.0);\n        atten = _292 * _292;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _343;\n    if (_250)\n    {\n        _343 = 0;\n    }\n    else\n    {\n        _343 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _343);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _370 = coord.xyz / vec3(coord.w);\n    vec3 p = _370;\n    vec2 suv = (_370.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2833 = p;\n        _2833.z = (_2833.z * 0.5) + 0.5;\n        p = _2833;\n    }\n    else\n    {\n        vec2 _2836 = suv;\n        _2836.y = 1.0 - _2836.y;\n        suv = _2836;\n    }\n    bool _398 = suv.x < 0.0;\n    bool _405;\n    if (!_398)\n    {\n        _405 = suv.x > 1.0;\n    }\n    else\n    {\n        _405 = _398;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.y < 0.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y > 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = p.z > 1.0;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    if (_426)\n    {\n        return 1.0;\n    }\n    float _441 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _441) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1568 = fa_light_sample(param, param_1);\n    vec3 _2786 = _1568.direction;\n    vec3 _2781 = _1568.color;\n    float _2788 = _1568.attenuation;\n    float _2783 = _1568.shadow;\n    int _2791 = _1568.type;\n    if ((_2791 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2786;\n        float _1582 = fa_shadow_factor(param_2, param_3);\n        _2783 = _1582;\n        _2781 = fa_lights[li * 1 + 32].xyz * (_2788 * _1582);\n    }\n    return LightSample(_2786, _2781, _2788, _2783, _1568._distance, _2791);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1252 = at * ab;\n    vec3 _1263 = vec3(ab * tdh, at * bdh, _1252 * ndh);\n    float _1269 = _1252 / dot(_1263, _1263);\n    return ((_1252 * _1269) * _1269) * 0.3183098733425140380859375;\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    return clamp(0.5 / max((ndl * length(vec3(at * tdv, ab * bdv, ndv))) + (ndv * length(vec3(at * tdl, ab * bdl, ndl))), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    return ((2.0 + (1.0 / alpha)) * pow(max(1.0 - (ndh * ndh), 0.0078125), 0.5 / alpha)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / ((ndl + ndv) - (ndl * ndv)), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1347 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1425 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1425) * _1425);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(1.0 - vdh, 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1347);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1347));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1498 = max(dot(L.nc, l), 0.0);\n        float _1504 = max(dot(L.nc, h), 0.0);\n        float _1513 = ((_1504 * _1504) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(1.0 - vdh, 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1513) * _1513)) * (0.5 / max(mix((2.0 * _1498) * L.coat_ndv, _1498 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1498)) * _1498);\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _638 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _641 = _638.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_641 * _641, exp2((-9.27999973297119140625) * ndv)) * _641) + _638.y)) + _638.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _541 = rough * rough;\n    float _572 = 0.60000002384185791015625 * _541;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _541)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _572, 0.0500000007450580596923828125 + _572, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_541 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1135;\n        if (L.aniso >= 0.0)\n        {\n            _1135 = L.b;\n        }\n        else\n        {\n            _1135 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1135, v), _1135), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1168 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1168.x) + (vec3(L.f90) * _1168.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1223 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1223.x) + _1223.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _680 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _680.x) + vec3(_680.y));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2516 = -_2516;\n    }\n    vec3 _1972 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _1972, gl_FrontFacing);\n    Surface _1977 = fa_standard_surface(param);\n    vec3 _2547 = _1977.albedo;\n    float _2548 = _1977.alpha;\n    vec3 _2549 = _1977.normal;\n    float _2550 = _1977.metallic;\n    float _2551 = _1977.roughness;\n    float _2552 = _1977.occlusion;\n    vec3 _2553 = _1977.emission;\n    float _2554 = _1977.clearcoat;\n    float _2555 = _1977.clearcoat_roughness;\n    vec3 _2556 = _1977.sheen_color;\n    float _2557 = _1977.sheen_roughness;\n    float _2558 = _1977.anisotropy;\n    float _2559 = _1977.anisotropy_rotation;\n    float _2560 = _1977.specular;\n    float _2561 = _1977.ior;\n    vec3 _2562 = _1977.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _1972, gl_FrontFacing);\n    Surface param_2 = _1977;\n    surface(param_1, param_2);\n    _2547 = param_2.albedo;\n    _2548 = param_2.alpha;\n    _2549 = param_2.normal;\n    _2550 = param_2.metallic;\n    _2551 = param_2.roughness;\n    _2552 = param_2.occlusion;\n    _2553 = param_2.emission;\n    _2554 = param_2.clearcoat;\n    _2555 = param_2.clearcoat_roughness;\n    _2556 = param_2.sheen_color;\n    _2557 = param_2.sheen_roughness;\n    _2558 = param_2.anisotropy;\n    _2559 = param_2.anisotropy_rotation;\n    _2560 = param_2.specular;\n    _2561 = param_2.ior;\n    _2562 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2547;\n    }\n    else\n    {\n        vec3 _1999 = normalize(_2549);\n        float _2006 = clamp(_2550, 0.0, 1.0);\n        float _2010 = clamp(_2551, 0.0500000007450580596923828125, 1.0);\n        float _2014 = _2010 * _2010;\n        float _2018 = _2014 * _2014;\n        float _2023 = max(dot(_1999, _1972), 9.9999997473787516355514526367188e-05);\n        vec3 _2029 = _2547 * (1.0 - _2006);\n        vec3 _2036 = mix(vec3(0.039999999105930328369140625), _2547, vec3(_2006));\n        vec3 f0 = _2036;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _1972, gl_FrontFacing);\n        Surface param_4 = Surface(_2547, _2548, _2549, _2550, _2551, _2552, _2553, _2554, _2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562);\n        vec3 param_5 = _1999;\n        vec3 param_6 = _1972;\n        float param_7 = _2006;\n        float param_8 = _2010;\n        vec3 param_9 = _2036;\n        FaLayers _2052 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        vec3 param_10 = _1999;\n        vec3 lit = (fa_ambient_light(param_10) * _2029) * _2552;\n        if (_2052.on)\n        {\n            lit *= _2052.base_scale;\n        }\n        int _2074 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2074)\n            {\n                break;\n            }\n            int param_11 = li;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _2516;\n            LightSample _2098 = fa_light_shadowed(param_11, param_12, param_13);\n            vec3 _2721 = _2098.direction;\n            float _2106 = max(dot(_1999, _2721), 0.0);\n            float _2112 = _2098.attenuation * _2098.shadow;\n            vec3 _2117 = normalize(_2721 + _1972);\n            float _2122 = max(dot(_1999, _2117), 0.0);\n            float _2127 = max(dot(_1972, _2117), 0.0);\n            if (_2052.on)\n            {\n                FaLayers param_14 = _2052;\n                vec3 param_15 = _2029;\n                vec3 param_16 = f0;\n                vec3 param_17 = _1999;\n                vec3 param_18 = _1972;\n                vec3 param_19 = _2721;\n                vec3 param_20 = _2117;\n                float param_21 = _2106;\n                float param_22 = _2023;\n                float param_23 = _2122;\n                float param_24 = _2127;\n                float param_25 = _2014;\n                float param_26 = _2018;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (fa_lights[li * 1 + 32].xyz * _2112));\n            }\n            else\n            {\n                float _2176 = ((_2122 * _2122) * (_2018 - 1.0)) + 1.0;\n                lit += (((_2029 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _2127, 5.0))) * (((_2018 / ((3.1415927410125732421875 * _2176) * _2176)) * (0.5 / max(mix((2.0 * _2106) * _2023, _2106 + _2023, _2014), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2106))) * fa_lights[li * 1 + 32].xyz) * (_2106 * _2112));\n            }\n        }\n        if (_2052.on)\n        {\n            FaLayers param_27 = _2052;\n            vec3 param_28 = _1999;\n            vec3 param_29 = _1972;\n            vec3 param_30 = f0;\n            float param_31 = _2010;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2552);\n        }\n        else\n        {\n            vec3 param_32 = _1999;\n            vec3 param_33 = _1972;\n            vec3 param_34 = f0;\n            float param_35 = _2010;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2552);\n        }\n        result = lit;\n    }\n    result += _2553;\n    bool _2274 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2281;\n    if (!_2274)\n    {\n        _2281 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2281 = _2274;\n    }\n    if (_2281)\n    {\n        vec3 _2290 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2296 = dot(_2290, fa_mesh_fs_params[9].xyz);\n        bool _2300 = fa_mesh_fs_params[9].w > 0.5;\n        float _2301;\n        if (_2300)\n        {\n            _2301 = _2296;\n        }\n        else\n        {\n            _2301 = length(_2290);\n        }\n        float _2313 = _2301 - fa_mesh_fs_params[8].x;\n        if (_2313 > 0.0)\n        {\n            float _2322 = fa_mesh_fs_params[7].w * _2313;\n            float tau = _2322 * _2322;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2338;\n                if (_2300)\n                {\n                    _2338 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2296);\n                }\n                else\n                {\n                    _2338 = fa_mesh_fs_params[0].y;\n                }\n                float _2359 = mix(_2338, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2301, 0.0, 1.0));\n                float _2363 = fa_world_pos.y - _2359;\n                float _2368 = _2359 - fa_mesh_fs_params[8].z;\n                float _2373 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2376 = _2368 <= 0.0;\n                bool _2377 = !_2376;\n                bool _2383;\n                if (_2377)\n                {\n                    _2383 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2383 = _2376;\n                }\n                float _2384;\n                if (_2383)\n                {\n                    _2384 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2384 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2368, 80.0));\n                }\n                bool _2411;\n                if (_2377)\n                {\n                    _2411 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2411 = _2376;\n                }\n                float _2412;\n                if (_2411)\n                {\n                    _2412 = fa_mesh_fs_params[8].y * _2368;\n                }\n                else\n                {\n                    _2412 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2368, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2437 = _2373 <= 0.0;\n                bool _2444;\n                if (!_2437)\n                {\n                    _2444 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2444 = _2437;\n                }\n                float _2445;\n                if (_2444)\n                {\n                    _2445 = fa_mesh_fs_params[8].y * _2373;\n                }\n                else\n                {\n                    _2445 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2373, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2472;\n                if (abs(_2363) < 0.001000000047497451305389404296875)\n                {\n                    _2472 = _2384;\n                }\n                else\n                {\n                    _2472 = (_2445 - _2412) / _2363;\n                }\n                tau += (_2313 * max(_2472, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2548);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
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
            "inst_name": "_212",
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
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_239",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_357",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 18,
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
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
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
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
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "height_height_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _103 = cross(model[1].xyz, model[2].xyz);\n    float _108 = (dot(model[0].xyz, _103) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_103 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _108, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _108), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _197 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _204 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_197 * _204).z;\n    fa_pre_r0 = vec3(_197[0].x, _197[1].x, _197[2].x);\n    fa_pre_r1 = vec3(_197[0].y, _197[1].y, _197[2].y);\n    fa_pre_r2 = vec3(_197[0].z, _197[1].z, _197[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _204;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D height_height_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _240 = fa_tex_fix(param_2, param_3);\n    vec4 _747 = base_t;\n    _747.x = _240.x;\n    _747.y = _240.y;\n    _747.z = _240.z;\n    base_t = _747;\n    vec4 _256 = (_747 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _710 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _289 = fa_tex_fix(param_6, param_7);\n        vec3 _293 = (_289 * 2.0) - vec3(1.0);\n        vec2 _298 = _293.xy * fa_mesh_fs_params[6].x;\n        vec3 _755 = _293;\n        _755.x = _298.x;\n        _755.y = _298.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _755;\n        _710 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _327 = fa_tex_fix(param_12, param_13);\n    vec4 _758 = mrt;\n    _758.x = _327.x;\n    _758.y = _327.y;\n    _758.z = _327.z;\n    mrt = _758;\n    vec4 _357 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _357.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _399 = fa_tex_fix(param_20, param_21);\n    float _715 = fa_mesh_fs_params[14].x;\n    float _716 = fa_mesh_fs_params[14].y;\n    float _719 = fa_mesh_fs_params[14].z;\n    float _718 = fa_mesh_fs_params[15].w;\n    float _721 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _715 *= _369.y;\n            _716 *= _369.z;\n            _718 *= _357.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _719 *= mrt.x;\n            _721 *= mrt.w;\n        }\n    }\n    return Surface(_256.xyz, _256.w, _710, clamp(fa_mesh_fs_params[5].x * _327.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _327.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_369.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _399), _715, _716, fa_mesh_fs_params[15].xyz, _718, _719, fa_mesh_fs_params[14].w, _721, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _621 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _621 = -_621;\n    }\n    vec3 _531 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _621, fa_world_tangent, fa_uv, fa_vertex_color, _531, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _621, fa_world_tangent, fa_uv, fa_vertex_color, _531, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _546 = normalize(param_2.normal);\n    vec3 _561 = normalize(vec3(dot(fa_pre_r0, _546), dot(fa_pre_r1, _546), dot(fa_pre_r2, _546)));\n    float _573 = _561.z;\n    vec2 e = _561.xy / vec2((abs(_561.x) + abs(_561.y)) + abs(_573));\n    if (_573 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_63",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_160",
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 18,
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "height_height_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _203 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_203 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_203 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_203 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _108 = cross(model[1].xyz, model[2].xyz);\n    float _113 = (dot(model[0].xyz, _108) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_108 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _113, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _113), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _310 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _317 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_310 * _317).z;\n    fa_pre_r0 = vec3(_310[0].x, _310[1].x, _310[2].x);\n    fa_pre_r1 = vec3(_310[0].y, _310[1].y, _310[2].y);\n    fa_pre_r2 = vec3(_310[0].z, _310[1].z, _310[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _317;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D height_height_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _196 = fa_linear_to_srgb(param);\n        c = _196;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _204 = fa_srgb_to_linear(param_1);\n            c = _204;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _240 = fa_tex_fix(param_2, param_3);\n    vec4 _747 = base_t;\n    _747.x = _240.x;\n    _747.y = _240.y;\n    _747.z = _240.z;\n    base_t = _747;\n    vec4 _256 = (_747 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _710 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _289 = fa_tex_fix(param_6, param_7);\n        vec3 _293 = (_289 * 2.0) - vec3(1.0);\n        vec2 _298 = _293.xy * fa_mesh_fs_params[6].x;\n        vec3 _755 = _293;\n        _755.x = _298.x;\n        _755.y = _298.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _755;\n        _710 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _327 = fa_tex_fix(param_12, param_13);\n    vec4 _758 = mrt;\n    _758.x = _327.x;\n    _758.y = _327.y;\n    _758.z = _327.z;\n    mrt = _758;\n    vec4 _357 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _357.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _369 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _399 = fa_tex_fix(param_20, param_21);\n    float _715 = fa_mesh_fs_params[14].x;\n    float _716 = fa_mesh_fs_params[14].y;\n    float _719 = fa_mesh_fs_params[14].z;\n    float _718 = fa_mesh_fs_params[15].w;\n    float _721 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _715 *= _369.y;\n            _716 *= _369.z;\n            _718 *= _357.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _719 *= mrt.x;\n            _721 *= mrt.w;\n        }\n    }\n    return Surface(_256.xyz, _256.w, _710, clamp(fa_mesh_fs_params[5].x * _327.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _327.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_369.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _399), _715, _716, fa_mesh_fs_params[15].xyz, _718, _719, fa_mesh_fs_params[14].w, _721, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.albedo *= mix(0.5, 1.0, texture(height_height_smp, i.uv).x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _621 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _621 = -_621;\n    }\n    vec3 _531 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _621, fa_world_tangent, fa_uv, fa_vertex_color, _531, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _621, fa_world_tangent, fa_uv, fa_vertex_color, _531, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _546 = normalize(param_2.normal);\n    vec3 _561 = normalize(vec3(dot(fa_pre_r0, _546), dot(fa_pre_r1, _546), dot(fa_pre_r2, _546)));\n    float _573 = _561.z;\n    vec2 e = _561.xy / vec2((abs(_561.x) + abs(_561.y)) + abs(_573));\n    if (_573 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_68",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_165",
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
            "inst_name": "_212",
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 18,
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
              "slot": 6,
              "stage": "fragment",
              "name": "height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "height_smp",
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
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
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
            "name": "height_height_smp",
            "view_name": "height",
            "sampler_name": "height_smp",
            "view_slot": 6,
            "sampler_slot": 2,
            "glsl_name": "height_height_smp"
          }
        ]
      }
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _99 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _99, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _99), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_54",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_151",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 10,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_material_vs[1];\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(binding = 0) uniform sampler2D fa_vs_height_fa_vs_height_smp;\n\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _194 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_194 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_194 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_194 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _104 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _104, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _104), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += (textureLod(fa_vs_height_fa_vs_height_smp, v.uv, 0.0).x * fa_material_vs[0].x);\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "slot": 4,
            "stage": "vertex",
            "size": 16,
            "struct_name": "fa_material_vs",
            "inst_name": "_59",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material_vs"
              }
            ]
          },
          {
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_156",
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
            "inst_name": "_203",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 10,
              "stage": "vertex",
              "name": "fa_vs_height",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 6,
            "stage": "vertex",
            "name": "fa_vs_height_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_vs_height_fa_vs_height_smp",
            "view_name": "fa_vs_height",
            "sampler_name": "fa_vs_height_smp",
            "view_slot": 10,
            "sampler_slot": 6,
            "glsl_name": "fa_vs_height_fa_vs_height_smp"
          }
        ]
      }
    }
  }
}
