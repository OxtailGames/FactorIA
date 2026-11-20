{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "67b1186c6e51021b07dd68cec7aaad42a4febc7364ef358b4473bc1e089911c0",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "buffers": [
    {
      "name": "points",
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
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    vec4 _206 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _206;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _206;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _790[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1706 = fa_linear_to_srgb(param);\n        c = _1706;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1714 = fa_srgb_to_linear(param_1);\n            c = _1714;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    vec3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    vec3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    vec3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1745 = fa_tex_fix(param_2, param_3);\n    vec4 _2902 = base_t;\n    _2902.x = _1745.x;\n    _2902.y = _1745.y;\n    _2902.z = _1745.z;\n    base_t = _2902;\n    vec4 _1759 = (_2902 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2845 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1792 = fa_tex_fix(param_6, param_7);\n        vec3 _1795 = (_1792 * 2.0) - vec3(1.0);\n        vec2 _1800 = _1795.xy * fa_mesh_fs_params[6].x;\n        vec3 _2910 = _1795;\n        _2910.x = _1800.x;\n        _2910.y = _1800.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2910;\n        _2845 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1829 = fa_tex_fix(param_12, param_13);\n    vec4 _2913 = mrt;\n    _2913.x = _1829.x;\n    _2913.y = _1829.y;\n    _2913.z = _1829.z;\n    mrt = _2913;\n    vec4 _1857 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1857.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1869 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1899 = fa_tex_fix(param_20, param_21);\n    float _2850 = fa_mesh_fs_params[14].x;\n    float _2851 = fa_mesh_fs_params[14].y;\n    float _2854 = fa_mesh_fs_params[14].z;\n    float _2853 = fa_mesh_fs_params[15].w;\n    float _2856 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2850 *= _1869.y;\n            _2851 *= _1869.z;\n            _2853 *= _1857.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2854 *= mrt.x;\n            _2856 *= mrt.w;\n        }\n    }\n    return Surface(_1759.xyz, _1759.w, _2845, clamp(fa_mesh_fs_params[5].x * _1829.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1829.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1869.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1899), _2850, _2851, fa_mesh_fs_params[15].xyz, _2853, _2854, fa_mesh_fs_params[14].w, _2856, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _715 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _723 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _726 = int(_715);\n    int _729 = int(_723);\n    float _739 = _723 - float(_729);\n    int _795 = (_726 * 9) + _729;\n    int _815 = ((_726 + 1) * 9) + _729;\n    return mix(mix(_790[_795], _790[_795 + 1], _739), mix(_790[_815], _790[_815 + 1], _739), _715 - float(_726));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2781 = false;\n    float _2782 = 1.0;\n    float _2783 = 1.0;\n    float _2784 = 1.0;\n    float _2785 = 0.0;\n    float _2786 = 0.0;\n    float _2787 = 0.0;\n    float _2788 = 0.0;\n    float _2790 = 1.0;\n    bool _2791 = false;\n    vec3 _2792 = vec3(0.0);\n    float _2793 = 1.0;\n    float _2794 = 1.0;\n    float _2795 = 1.0;\n    float _2796 = 0.0;\n    float _2797 = 0.0;\n    vec3 _2798 = vec3(1.0, 0.0, 0.0);\n    vec3 _2799 = vec3(0.0, 0.0, 1.0);\n    float _2800 = 1.0;\n    float _2801 = 1.0;\n    float _877 = clamp(s.specular, 0.0, 1.0);\n    float _882 = clamp(s.ior, 1.0, 3.0);\n    bool _887 = (_877 != 1.0) || (_882 != 1.5);\n    bool _897;\n    if (!_887)\n    {\n        _897 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _897 = _887;\n    }\n    if (_897)\n    {\n        float _905 = (_882 - 1.0) / (_882 + 1.0);\n        f0 = mix(min(vec3(_905 * _905) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _877, s.albedo, vec3(metallic));\n        _2782 = mix(_877, 1.0, metallic);\n        _2781 = true;\n    }\n    float _933 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_933 > 0.0)\n    {\n        float _941 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2785 = _933;\n        _2786 = _941;\n        float _948 = _941 * _941;\n        _2787 = _948;\n        _2788 = _948 * _948;\n        float _960 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2790 = _960;\n        _2783 = 1.0 - (_933 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _960, 0.0, 1.0), 5.0))));\n        _2781 = true;\n    }\n    vec3 _980 = max(s.sheen_color, vec3(0.0));\n    float _989 = max(_980.x, max(_980.y, _980.z));\n    if (_989 > 0.0)\n    {\n        float _997 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2791 = true;\n        _2792 = _980;\n        _2793 = _997;\n        _2794 = _997 * _997;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _997;\n        float _1014 = fa_sheen_albedo(param, param_1);\n        _2796 = _1014;\n        _2795 = 1.0 - min(_989 * _1014, 1.0);\n        _2781 = true;\n    }\n    _2784 = _2783 * _2795;\n    float _1033 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1033 != 0.0)\n    {\n        vec3 _1048 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1048;\n        if (dot(_1048, _1048) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1062 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1062.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1062.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1062.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1066 = t;\n        vec3 _1067 = normalize(_1066);\n        t = _1067;\n        vec3 _1092 = normalize((_1067 * cos(s.anisotropy_rotation)) + ((cross(n, _1067) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2798 = _1092;\n        _2799 = cross(n, _1092);\n        float _1102 = roughness * roughness;\n        float _1108 = mix(_1102, 1.0, _1033 * _1033);\n        bool _1110 = _1033 > 0.0;\n        _2800 = _1110 ? _1108 : _1102;\n        _2801 = _1110 ? _1102 : _1108;\n        _2797 = _1033;\n        _2781 = true;\n    }\n    return FaLayers(_2781, _2782, _2783, _2784, _2785, _2786, _2787, _2788, i.world_normal, _2790, _2791, _2792, _2793, _2794, _2795, _2796, _2797, _2798, _2799, _2800, _2801);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _257 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_257)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _275 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _277 = length(_275);\n        dist = _277;\n        l = _275 / vec3(max(_277, 9.9999997473787516355514526367188e-05));\n        float _293 = _277 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _299 = clamp(1.0 - (_293 * _293), 0.0, 1.0);\n        atten = _299 * _299;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _350;\n    if (_257)\n    {\n        _350 = 0;\n    }\n    else\n    {\n        _350 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _350);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _377 = coord.xyz / vec3(coord.w);\n    vec3 p = _377;\n    vec2 suv = (_377.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2877 = p;\n        _2877.z = (_2877.z * 0.5) + 0.5;\n        p = _2877;\n    }\n    else\n    {\n        vec2 _2880 = suv;\n        _2880.y = 1.0 - _2880.y;\n        suv = _2880;\n    }\n    bool _405 = suv.x < 0.0;\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.x > 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y < 0.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = suv.y > 1.0;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _433;\n    if (!_426)\n    {\n        _433 = p.z > 1.0;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    if (_433)\n    {\n        return 1.0;\n    }\n    float _448 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _448) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1614 = fa_light_sample(param, param_1);\n    vec3 _2830 = _1614.direction;\n    vec3 _2825 = _1614.color;\n    float _2832 = _1614.attenuation;\n    float _2827 = _1614.shadow;\n    int _2835 = _1614.type;\n    if ((_2835 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2830;\n        float _1628 = fa_shadow_factor(param_2, param_3);\n        _2827 = _1628;\n        _2825 = fa_lights[li * 1 + 32].xyz * (_2832 * _1628);\n    }\n    return LightSample(_2830, _2825, _2832, _2827, _1614._distance, _2835);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1260 = tdh / at;\n    float _1264 = bdh / ab;\n    float _1276 = ((_1260 * _1260) + (_1264 * _1264)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _1276) * _1276);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1358 = 1.0 / alpha;\n    return ((2.0 + _1358) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _1358)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1391 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1470 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1470) * _1470);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1391);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1391));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1543 = max(dot(L.nc, l), 0.0);\n        float _1549 = max(dot(L.nc, h), 0.0);\n        float _1558 = ((_1549 * _1549) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1558) * _1558)) * (0.5 / max(mix((2.0 * _1543) * L.coat_ndv, _1543 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1543)) * _1543);\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _645 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _648 = _645.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_648 * _648, exp2((-9.27999973297119140625) * ndv)) * _648) + _645.y)) + _645.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _548 = rough * rough;\n    float _579 = 0.60000002384185791015625 * _548;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _548)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _579, 0.0500000007450580596923828125 + _579, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_548 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1143;\n        if (L.aniso >= 0.0)\n        {\n            _1143 = L.b;\n        }\n        else\n        {\n            _1143 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1143, v), _1143), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1176 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1176.x) + (vec3(L.f90) * _1176.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1231 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1231.x) + _1231.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _687 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _687.x) + vec3(_687.y));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2560 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2560 = -_2560;\n    }\n    vec3 _2019 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2560, fa_world_tangent, fa_uv, fa_vertex_color, _2019, gl_FrontFacing);\n    Surface _2024 = fa_standard_surface(param);\n    vec3 _2591 = _2024.albedo;\n    float _2592 = _2024.alpha;\n    vec3 _2593 = _2024.normal;\n    float _2594 = _2024.metallic;\n    float _2595 = _2024.roughness;\n    float _2596 = _2024.occlusion;\n    vec3 _2597 = _2024.emission;\n    float _2598 = _2024.clearcoat;\n    float _2599 = _2024.clearcoat_roughness;\n    vec3 _2600 = _2024.sheen_color;\n    float _2601 = _2024.sheen_roughness;\n    float _2602 = _2024.anisotropy;\n    float _2603 = _2024.anisotropy_rotation;\n    float _2604 = _2024.specular;\n    float _2605 = _2024.ior;\n    vec3 _2606 = _2024.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2560, fa_world_tangent, fa_uv, fa_vertex_color, _2019, gl_FrontFacing);\n    Surface param_2 = _2024;\n    surface(param_1, param_2);\n    _2591 = param_2.albedo;\n    _2592 = param_2.alpha;\n    _2593 = param_2.normal;\n    _2594 = param_2.metallic;\n    _2595 = param_2.roughness;\n    _2596 = param_2.occlusion;\n    _2597 = param_2.emission;\n    _2598 = param_2.clearcoat;\n    _2599 = param_2.clearcoat_roughness;\n    _2600 = param_2.sheen_color;\n    _2601 = param_2.sheen_roughness;\n    _2602 = param_2.anisotropy;\n    _2603 = param_2.anisotropy_rotation;\n    _2604 = param_2.specular;\n    _2605 = param_2.ior;\n    _2606 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2591;\n    }\n    else\n    {\n        vec3 _2046 = normalize(_2593);\n        float _2053 = clamp(_2594, 0.0, 1.0);\n        float _2057 = clamp(_2595, 0.0500000007450580596923828125, 1.0);\n        float _2061 = _2057 * _2057;\n        float _2065 = _2061 * _2061;\n        float _2070 = max(dot(_2046, _2019), 9.9999997473787516355514526367188e-05);\n        vec3 _2076 = _2591 * (1.0 - _2053);\n        vec3 _2083 = mix(vec3(0.039999999105930328369140625), _2591, vec3(_2053));\n        vec3 f0 = _2083;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _2560, fa_world_tangent, fa_uv, fa_vertex_color, _2019, gl_FrontFacing);\n        Surface param_4 = Surface(_2591, _2592, _2593, _2594, _2595, _2596, _2597, _2598, _2599, _2600, _2601, _2602, _2603, _2604, _2605, _2606);\n        vec3 param_5 = _2046;\n        vec3 param_6 = _2019;\n        float param_7 = _2053;\n        float param_8 = _2057;\n        vec3 param_9 = _2083;\n        FaLayers _2099 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        vec3 param_10 = _2046;\n        vec3 lit = (fa_ambient_light(param_10) * _2076) * _2596;\n        if (_2099.on)\n        {\n            lit *= _2099.base_scale;\n        }\n        int _2121 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2121)\n            {\n                break;\n            }\n            int param_11 = li;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _2560;\n            LightSample _2145 = fa_light_shadowed(param_11, param_12, param_13);\n            vec3 _2765 = _2145.direction;\n            float _2153 = max(dot(_2046, _2765), 0.0);\n            float _2159 = _2145.attenuation * _2145.shadow;\n            vec3 _2164 = normalize(_2765 + _2019);\n            float _2169 = max(dot(_2046, _2164), 0.0);\n            float _2174 = max(dot(_2019, _2164), 0.0);\n            if (_2099.on)\n            {\n                FaLayers param_14 = _2099;\n                vec3 param_15 = _2076;\n                vec3 param_16 = f0;\n                vec3 param_17 = _2046;\n                vec3 param_18 = _2019;\n                vec3 param_19 = _2765;\n                vec3 param_20 = _2164;\n                float param_21 = _2153;\n                float param_22 = _2070;\n                float param_23 = _2169;\n                float param_24 = _2174;\n                float param_25 = _2061;\n                float param_26 = _2065;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (fa_lights[li * 1 + 32].xyz * _2159));\n            }\n            else\n            {\n                float _2223 = ((_2169 * _2169) * (_2065 - 1.0)) + 1.0;\n                lit += (((_2076 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _2174, 5.0))) * (((_2065 / ((3.1415927410125732421875 * _2223) * _2223)) * (0.5 / max(mix((2.0 * _2153) * _2070, _2153 + _2070, _2061), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2153))) * fa_lights[li * 1 + 32].xyz) * (_2153 * _2159));\n            }\n        }\n        if (_2099.on)\n        {\n            FaLayers param_27 = _2099;\n            vec3 param_28 = _2046;\n            vec3 param_29 = _2019;\n            vec3 param_30 = f0;\n            float param_31 = _2057;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2596);\n        }\n        else\n        {\n            vec3 param_32 = _2046;\n            vec3 param_33 = _2019;\n            vec3 param_34 = f0;\n            float param_35 = _2057;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2596);\n        }\n        result = lit;\n    }\n    result += _2597;\n    bool _2321 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2328;\n    if (!_2321)\n    {\n        _2328 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2328 = _2321;\n    }\n    if (_2328)\n    {\n        vec3 _2337 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2343 = dot(_2337, fa_mesh_fs_params[9].xyz);\n        bool _2347 = fa_mesh_fs_params[9].w > 0.5;\n        float _2348;\n        if (_2347)\n        {\n            _2348 = _2343;\n        }\n        else\n        {\n            _2348 = length(_2337);\n        }\n        float _2360 = _2348 - fa_mesh_fs_params[8].x;\n        if (_2360 > 0.0)\n        {\n            float _2369 = fa_mesh_fs_params[7].w * _2360;\n            float tau = _2369 * _2369;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2385;\n                if (_2347)\n                {\n                    _2385 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2343);\n                }\n                else\n                {\n                    _2385 = fa_mesh_fs_params[0].y;\n                }\n                float _2406 = mix(_2385, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2348, 0.0, 1.0));\n                float _2410 = fa_world_pos.y - _2406;\n                float _2415 = _2406 - fa_mesh_fs_params[8].z;\n                float _2420 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2423 = _2415 <= 0.0;\n                bool _2424 = !_2423;\n                bool _2430;\n                if (_2424)\n                {\n                    _2430 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2430 = _2423;\n                }\n                float _2431;\n                if (_2430)\n                {\n                    _2431 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2431 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2415, 80.0));\n                }\n                bool _2458;\n                if (_2424)\n                {\n                    _2458 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2458 = _2423;\n                }\n                float _2459;\n                if (_2458)\n                {\n                    _2459 = fa_mesh_fs_params[8].y * _2415;\n                }\n                else\n                {\n                    _2459 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2415, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2484 = _2420 <= 0.0;\n                bool _2491;\n                if (!_2484)\n                {\n                    _2491 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2491 = _2484;\n                }\n                float _2492;\n                if (_2491)\n                {\n                    _2492 = fa_mesh_fs_params[8].y * _2420;\n                }\n                else\n                {\n                    _2492 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2420, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2519;\n                if (abs(_2410) < 0.001000000047497451305389404296875)\n                {\n                    _2519 = _2431;\n                }\n                else\n                {\n                    _2519 = (_2492 - _2459) / _2410;\n                }\n                tau += (_2360 * max(_2519, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2592);\n}\n\n",
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
            "inst_name": "_168",
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
            "inst_name": "_243",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_246",
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
            "inst_name": "_364",
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 7,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_208 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_208 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_208 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    vec4 _318 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _318;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _318;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _790[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1706 = fa_linear_to_srgb(param);\n        c = _1706;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1714 = fa_srgb_to_linear(param_1);\n            c = _1714;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _174;\n    if (i.front_facing)\n    {\n        _174 = i.world_normal;\n    }\n    else\n    {\n        _174 = -i.world_normal;\n    }\n    vec3 _198 = normalize(i.world_tangent.xyz - (_174 * dot(_174, i.world_tangent.xyz)));\n    vec3 _226 = normalize(((_198 * m.x) + ((cross(_174, _198) * i.world_tangent.w) * m.y)) + (_174 * m.z));\n    vec3 _229;\n    if (i.front_facing)\n    {\n        _229 = _226;\n    }\n    else\n    {\n        _229 = -_226;\n    }\n    return _229;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1745 = fa_tex_fix(param_2, param_3);\n    vec4 _2902 = base_t;\n    _2902.x = _1745.x;\n    _2902.y = _1745.y;\n    _2902.z = _1745.z;\n    base_t = _2902;\n    vec4 _1759 = (_2902 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2845 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1792 = fa_tex_fix(param_6, param_7);\n        vec3 _1795 = (_1792 * 2.0) - vec3(1.0);\n        vec2 _1800 = _1795.xy * fa_mesh_fs_params[6].x;\n        vec3 _2910 = _1795;\n        _2910.x = _1800.x;\n        _2910.y = _1800.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2910;\n        _2845 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1829 = fa_tex_fix(param_12, param_13);\n    vec4 _2913 = mrt;\n    _2913.x = _1829.x;\n    _2913.y = _1829.y;\n    _2913.z = _1829.z;\n    mrt = _2913;\n    vec4 _1857 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1857.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1869 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1899 = fa_tex_fix(param_20, param_21);\n    float _2850 = fa_mesh_fs_params[14].x;\n    float _2851 = fa_mesh_fs_params[14].y;\n    float _2854 = fa_mesh_fs_params[14].z;\n    float _2853 = fa_mesh_fs_params[15].w;\n    float _2856 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2850 *= _1869.y;\n            _2851 *= _1869.z;\n            _2853 *= _1857.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2854 *= mrt.x;\n            _2856 *= mrt.w;\n        }\n    }\n    return Surface(_1759.xyz, _1759.w, _2845, clamp(fa_mesh_fs_params[5].x * _1829.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1829.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1869.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1899), _2850, _2851, fa_mesh_fs_params[15].xyz, _2853, _2854, fa_mesh_fs_params[14].w, _2856, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _715 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _723 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _726 = int(_715);\n    int _729 = int(_723);\n    float _739 = _723 - float(_729);\n    int _795 = (_726 * 9) + _729;\n    int _815 = ((_726 + 1) * 9) + _729;\n    return mix(mix(_790[_795], _790[_795 + 1], _739), mix(_790[_815], _790[_815 + 1], _739), _715 - float(_726));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2781 = false;\n    float _2782 = 1.0;\n    float _2783 = 1.0;\n    float _2784 = 1.0;\n    float _2785 = 0.0;\n    float _2786 = 0.0;\n    float _2787 = 0.0;\n    float _2788 = 0.0;\n    float _2790 = 1.0;\n    bool _2791 = false;\n    vec3 _2792 = vec3(0.0);\n    float _2793 = 1.0;\n    float _2794 = 1.0;\n    float _2795 = 1.0;\n    float _2796 = 0.0;\n    float _2797 = 0.0;\n    vec3 _2798 = vec3(1.0, 0.0, 0.0);\n    vec3 _2799 = vec3(0.0, 0.0, 1.0);\n    float _2800 = 1.0;\n    float _2801 = 1.0;\n    float _877 = clamp(s.specular, 0.0, 1.0);\n    float _882 = clamp(s.ior, 1.0, 3.0);\n    bool _887 = (_877 != 1.0) || (_882 != 1.5);\n    bool _897;\n    if (!_887)\n    {\n        _897 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _897 = _887;\n    }\n    if (_897)\n    {\n        float _905 = (_882 - 1.0) / (_882 + 1.0);\n        f0 = mix(min(vec3(_905 * _905) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _877, s.albedo, vec3(metallic));\n        _2782 = mix(_877, 1.0, metallic);\n        _2781 = true;\n    }\n    float _933 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_933 > 0.0)\n    {\n        float _941 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2785 = _933;\n        _2786 = _941;\n        float _948 = _941 * _941;\n        _2787 = _948;\n        _2788 = _948 * _948;\n        float _960 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2790 = _960;\n        _2783 = 1.0 - (_933 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _960, 0.0, 1.0), 5.0))));\n        _2781 = true;\n    }\n    vec3 _980 = max(s.sheen_color, vec3(0.0));\n    float _989 = max(_980.x, max(_980.y, _980.z));\n    if (_989 > 0.0)\n    {\n        float _997 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2791 = true;\n        _2792 = _980;\n        _2793 = _997;\n        _2794 = _997 * _997;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _997;\n        float _1014 = fa_sheen_albedo(param, param_1);\n        _2796 = _1014;\n        _2795 = 1.0 - min(_989 * _1014, 1.0);\n        _2781 = true;\n    }\n    _2784 = _2783 * _2795;\n    float _1033 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1033 != 0.0)\n    {\n        vec3 _1048 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1048;\n        if (dot(_1048, _1048) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1062 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1062.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1062.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1062.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1066 = t;\n        vec3 _1067 = normalize(_1066);\n        t = _1067;\n        vec3 _1092 = normalize((_1067 * cos(s.anisotropy_rotation)) + ((cross(n, _1067) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2798 = _1092;\n        _2799 = cross(n, _1092);\n        float _1102 = roughness * roughness;\n        float _1108 = mix(_1102, 1.0, _1033 * _1033);\n        bool _1110 = _1033 > 0.0;\n        _2800 = _1110 ? _1108 : _1102;\n        _2801 = _1110 ? _1102 : _1108;\n        _2797 = _1033;\n        _2781 = true;\n    }\n    return FaLayers(_2781, _2782, _2783, _2784, _2785, _2786, _2787, _2788, i.world_normal, _2790, _2791, _2792, _2793, _2794, _2795, _2796, _2797, _2798, _2799, _2800, _2801);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _257 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_257)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _275 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _277 = length(_275);\n        dist = _277;\n        l = _275 / vec3(max(_277, 9.9999997473787516355514526367188e-05));\n        float _293 = _277 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _299 = clamp(1.0 - (_293 * _293), 0.0, 1.0);\n        atten = _299 * _299;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _350;\n    if (_257)\n    {\n        _350 = 0;\n    }\n    else\n    {\n        _350 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _350);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _377 = coord.xyz / vec3(coord.w);\n    vec3 p = _377;\n    vec2 suv = (_377.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2877 = p;\n        _2877.z = (_2877.z * 0.5) + 0.5;\n        p = _2877;\n    }\n    else\n    {\n        vec2 _2880 = suv;\n        _2880.y = 1.0 - _2880.y;\n        suv = _2880;\n    }\n    bool _405 = suv.x < 0.0;\n    bool _412;\n    if (!_405)\n    {\n        _412 = suv.x > 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = suv.y < 0.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    bool _426;\n    if (!_419)\n    {\n        _426 = suv.y > 1.0;\n    }\n    else\n    {\n        _426 = _419;\n    }\n    bool _433;\n    if (!_426)\n    {\n        _433 = p.z > 1.0;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    if (_433)\n    {\n        return 1.0;\n    }\n    float _448 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _448) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1614 = fa_light_sample(param, param_1);\n    vec3 _2830 = _1614.direction;\n    vec3 _2825 = _1614.color;\n    float _2832 = _1614.attenuation;\n    float _2827 = _1614.shadow;\n    int _2835 = _1614.type;\n    if ((_2835 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2830;\n        float _1628 = fa_shadow_factor(param_2, param_3);\n        _2827 = _1628;\n        _2825 = fa_lights[li * 1 + 32].xyz * (_2832 * _1628);\n    }\n    return LightSample(_2830, _2825, _2832, _2827, _1614._distance, _2835);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1260 = tdh / at;\n    float _1264 = bdh / ab;\n    float _1276 = ((_1260 * _1260) + (_1264 * _1264)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _1276) * _1276);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1358 = 1.0 / alpha;\n    return ((2.0 + _1358) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _1358)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1391 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1470 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1470) * _1470);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1391);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1391));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1543 = max(dot(L.nc, l), 0.0);\n        float _1549 = max(dot(L.nc, h), 0.0);\n        float _1558 = ((_1549 * _1549) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1558) * _1558)) * (0.5 / max(mix((2.0 * _1543) * L.coat_ndv, _1543 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1543)) * _1543);\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _645 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _648 = _645.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_648 * _648, exp2((-9.27999973297119140625) * ndv)) * _648) + _645.y)) + _645.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _548 = rough * rough;\n    float _579 = 0.60000002384185791015625 * _548;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _548)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _579, 0.0500000007450580596923828125 + _579, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_548 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1143;\n        if (L.aniso >= 0.0)\n        {\n            _1143 = L.b;\n        }\n        else\n        {\n            _1143 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1143, v), _1143), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1176 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1176.x) + (vec3(L.f90) * _1176.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1231 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1231.x) + _1231.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _687 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _687.x) + vec3(_687.y));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2560 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2560 = -_2560;\n    }\n    vec3 _2019 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2560, fa_world_tangent, fa_uv, fa_vertex_color, _2019, gl_FrontFacing);\n    Surface _2024 = fa_standard_surface(param);\n    vec3 _2591 = _2024.albedo;\n    float _2592 = _2024.alpha;\n    vec3 _2593 = _2024.normal;\n    float _2594 = _2024.metallic;\n    float _2595 = _2024.roughness;\n    float _2596 = _2024.occlusion;\n    vec3 _2597 = _2024.emission;\n    float _2598 = _2024.clearcoat;\n    float _2599 = _2024.clearcoat_roughness;\n    vec3 _2600 = _2024.sheen_color;\n    float _2601 = _2024.sheen_roughness;\n    float _2602 = _2024.anisotropy;\n    float _2603 = _2024.anisotropy_rotation;\n    float _2604 = _2024.specular;\n    float _2605 = _2024.ior;\n    vec3 _2606 = _2024.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2560, fa_world_tangent, fa_uv, fa_vertex_color, _2019, gl_FrontFacing);\n    Surface param_2 = _2024;\n    surface(param_1, param_2);\n    _2591 = param_2.albedo;\n    _2592 = param_2.alpha;\n    _2593 = param_2.normal;\n    _2594 = param_2.metallic;\n    _2595 = param_2.roughness;\n    _2596 = param_2.occlusion;\n    _2597 = param_2.emission;\n    _2598 = param_2.clearcoat;\n    _2599 = param_2.clearcoat_roughness;\n    _2600 = param_2.sheen_color;\n    _2601 = param_2.sheen_roughness;\n    _2602 = param_2.anisotropy;\n    _2603 = param_2.anisotropy_rotation;\n    _2604 = param_2.specular;\n    _2605 = param_2.ior;\n    _2606 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2591;\n    }\n    else\n    {\n        vec3 _2046 = normalize(_2593);\n        float _2053 = clamp(_2594, 0.0, 1.0);\n        float _2057 = clamp(_2595, 0.0500000007450580596923828125, 1.0);\n        float _2061 = _2057 * _2057;\n        float _2065 = _2061 * _2061;\n        float _2070 = max(dot(_2046, _2019), 9.9999997473787516355514526367188e-05);\n        vec3 _2076 = _2591 * (1.0 - _2053);\n        vec3 _2083 = mix(vec3(0.039999999105930328369140625), _2591, vec3(_2053));\n        vec3 f0 = _2083;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _2560, fa_world_tangent, fa_uv, fa_vertex_color, _2019, gl_FrontFacing);\n        Surface param_4 = Surface(_2591, _2592, _2593, _2594, _2595, _2596, _2597, _2598, _2599, _2600, _2601, _2602, _2603, _2604, _2605, _2606);\n        vec3 param_5 = _2046;\n        vec3 param_6 = _2019;\n        float param_7 = _2053;\n        float param_8 = _2057;\n        vec3 param_9 = _2083;\n        FaLayers _2099 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        vec3 param_10 = _2046;\n        vec3 lit = (fa_ambient_light(param_10) * _2076) * _2596;\n        if (_2099.on)\n        {\n            lit *= _2099.base_scale;\n        }\n        int _2121 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2121)\n            {\n                break;\n            }\n            int param_11 = li;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _2560;\n            LightSample _2145 = fa_light_shadowed(param_11, param_12, param_13);\n            vec3 _2765 = _2145.direction;\n            float _2153 = max(dot(_2046, _2765), 0.0);\n            float _2159 = _2145.attenuation * _2145.shadow;\n            vec3 _2164 = normalize(_2765 + _2019);\n            float _2169 = max(dot(_2046, _2164), 0.0);\n            float _2174 = max(dot(_2019, _2164), 0.0);\n            if (_2099.on)\n            {\n                FaLayers param_14 = _2099;\n                vec3 param_15 = _2076;\n                vec3 param_16 = f0;\n                vec3 param_17 = _2046;\n                vec3 param_18 = _2019;\n                vec3 param_19 = _2765;\n                vec3 param_20 = _2164;\n                float param_21 = _2153;\n                float param_22 = _2070;\n                float param_23 = _2169;\n                float param_24 = _2174;\n                float param_25 = _2061;\n                float param_26 = _2065;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (fa_lights[li * 1 + 32].xyz * _2159));\n            }\n            else\n            {\n                float _2223 = ((_2169 * _2169) * (_2065 - 1.0)) + 1.0;\n                lit += (((_2076 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _2174, 5.0))) * (((_2065 / ((3.1415927410125732421875 * _2223) * _2223)) * (0.5 / max(mix((2.0 * _2153) * _2070, _2153 + _2070, _2061), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2153))) * fa_lights[li * 1 + 32].xyz) * (_2153 * _2159));\n            }\n        }\n        if (_2099.on)\n        {\n            FaLayers param_27 = _2099;\n            vec3 param_28 = _2046;\n            vec3 param_29 = _2019;\n            vec3 param_30 = f0;\n            float param_31 = _2057;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2596);\n        }\n        else\n        {\n            vec3 param_32 = _2046;\n            vec3 param_33 = _2019;\n            vec3 param_34 = f0;\n            float param_35 = _2057;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2596);\n        }\n        result = lit;\n    }\n    result += _2597;\n    bool _2321 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2328;\n    if (!_2321)\n    {\n        _2328 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2328 = _2321;\n    }\n    if (_2328)\n    {\n        vec3 _2337 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2343 = dot(_2337, fa_mesh_fs_params[9].xyz);\n        bool _2347 = fa_mesh_fs_params[9].w > 0.5;\n        float _2348;\n        if (_2347)\n        {\n            _2348 = _2343;\n        }\n        else\n        {\n            _2348 = length(_2337);\n        }\n        float _2360 = _2348 - fa_mesh_fs_params[8].x;\n        if (_2360 > 0.0)\n        {\n            float _2369 = fa_mesh_fs_params[7].w * _2360;\n            float tau = _2369 * _2369;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2385;\n                if (_2347)\n                {\n                    _2385 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2343);\n                }\n                else\n                {\n                    _2385 = fa_mesh_fs_params[0].y;\n                }\n                float _2406 = mix(_2385, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2348, 0.0, 1.0));\n                float _2410 = fa_world_pos.y - _2406;\n                float _2415 = _2406 - fa_mesh_fs_params[8].z;\n                float _2420 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2423 = _2415 <= 0.0;\n                bool _2424 = !_2423;\n                bool _2430;\n                if (_2424)\n                {\n                    _2430 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2430 = _2423;\n                }\n                float _2431;\n                if (_2430)\n                {\n                    _2431 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2431 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2415, 80.0));\n                }\n                bool _2458;\n                if (_2424)\n                {\n                    _2458 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2458 = _2423;\n                }\n                float _2459;\n                if (_2458)\n                {\n                    _2459 = fa_mesh_fs_params[8].y * _2415;\n                }\n                else\n                {\n                    _2459 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2415, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2484 = _2420 <= 0.0;\n                bool _2491;\n                if (!_2484)\n                {\n                    _2491 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2491 = _2484;\n                }\n                float _2492;\n                if (_2491)\n                {\n                    _2492 = fa_mesh_fs_params[8].y * _2420;\n                }\n                else\n                {\n                    _2492 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2420, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2519;\n                if (abs(_2410) < 0.001000000047497451305389404296875)\n                {\n                    _2519 = _2431;\n                }\n                else\n                {\n                    _2519 = (_2492 - _2459) / _2410;\n                }\n                tau += (_2360 * max(_2519, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2592);\n}\n\n",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_217",
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
            "inst_name": "_355",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_246",
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
            "inst_name": "_364",
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
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
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_irr_tex_fa_env_smp",
            "view_name": "fa_irr_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 15,
            "sampler_slot": 10,
            "glsl_name": "fa_irr_tex_fa_env_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 7,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _109 = cross(model[1].xyz, model[2].xyz);\n    float _114 = (dot(model[0].xyz, _109) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_109 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _114, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _114), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _203 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _210 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_203 * _210).z;\n    fa_pre_r0 = vec3(_203[0].x, _203[1].x, _203[2].x);\n    fa_pre_r1 = vec3(_203[0].y, _203[1].y, _203[2].y);\n    fa_pre_r2 = vec3(_203[0].z, _203[1].z, _203[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _210;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _745 = base_t;\n    _745.x = _242.x;\n    _745.y = _242.y;\n    _745.z = _242.z;\n    base_t = _745;\n    vec4 _257 = (_745 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _708 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _753 = _294;\n        _753.x = _299.x;\n        _753.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _756 = mrt;\n    _756.x = _328.x;\n    _756.y = _328.y;\n    _756.z = _328.z;\n    mrt = _756;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _713 = fa_mesh_fs_params[14].x;\n    float _714 = fa_mesh_fs_params[14].y;\n    float _717 = fa_mesh_fs_params[14].z;\n    float _716 = fa_mesh_fs_params[15].w;\n    float _719 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _713 *= _370.y;\n            _714 *= _370.z;\n            _716 *= _358.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _708, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _713, _714, fa_mesh_fs_params[15].xyz, _716, _717, fa_mesh_fs_params[14].w, _719, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    vec3 _532 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _547 = normalize(param_2.normal);\n    vec3 _562 = normalize(vec3(dot(fa_pre_r0, _547), dot(fa_pre_r1, _547), dot(fa_pre_r2, _547)));\n    float _574 = _562.z;\n    vec2 e = _562.xy / vec2((abs(_562.x) + abs(_562.y)) + abs(_574));\n    if (_574 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_168",
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
            "inst_name": "_272",
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _208 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_208 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_208 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_208 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _114 = cross(model[1].xyz, model[2].xyz);\n    float _119 = (dot(model[0].xyz, _114) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_114 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _119, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _119), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _315 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _322 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_315 * _322).z;\n    fa_pre_r0 = vec3(_315[0].x, _315[1].x, _315[2].x);\n    fa_pre_r1 = vec3(_315[0].y, _315[1].y, _315[2].y);\n    fa_pre_r2 = vec3(_315[0].z, _315[1].z, _315[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _322;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 1, std430) readonly buffer fa_points_buf\n{\n    points_item data[];\n} points;\n\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _190 = fa_linear_to_srgb(param);\n        c = _190;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _199 = fa_srgb_to_linear(param_1);\n            c = _199;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _242 = fa_tex_fix(param_2, param_3);\n    vec4 _745 = base_t;\n    _745.x = _242.x;\n    _745.y = _242.y;\n    _745.z = _242.z;\n    base_t = _745;\n    vec4 _257 = (_745 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _708 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _290 = fa_tex_fix(param_6, param_7);\n        vec3 _294 = (_290 * 2.0) - vec3(1.0);\n        vec2 _299 = _294.xy * fa_mesh_fs_params[6].x;\n        vec3 _753 = _294;\n        _753.x = _299.x;\n        _753.y = _299.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _753;\n        _708 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _328 = fa_tex_fix(param_12, param_13);\n    vec4 _756 = mrt;\n    _756.x = _328.x;\n    _756.y = _328.y;\n    _756.z = _328.z;\n    mrt = _756;\n    vec4 _358 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _358.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _370 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _400 = fa_tex_fix(param_20, param_21);\n    float _713 = fa_mesh_fs_params[14].x;\n    float _714 = fa_mesh_fs_params[14].y;\n    float _717 = fa_mesh_fs_params[14].z;\n    float _716 = fa_mesh_fs_params[15].w;\n    float _719 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _713 *= _370.y;\n            _714 *= _370.z;\n            _716 *= _358.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _717 *= mrt.x;\n            _719 *= mrt.w;\n        }\n    }\n    return Surface(_257.xyz, _257.w, _708, clamp(fa_mesh_fs_params[5].x * _328.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _328.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_370.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _400), _713, _714, fa_mesh_fs_params[15].xyz, _716, _717, fa_mesh_fs_params[14].w, _719, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * points.data[0].tint.w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _619 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _619 = -_619;\n    }\n    vec3 _532 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _619, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _547 = normalize(param_2.normal);\n    vec3 _562 = normalize(vec3(dot(fa_pre_r0, _547), dot(fa_pre_r1, _547), dot(fa_pre_r2, _547)));\n    float _574 = _562.z;\n    vec2 e = _562.xy / vec2((abs(_562.x) + abs(_562.y)) + abs(_574));\n    if (_574 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_217",
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
            "inst_name": "_384",
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_231",
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
            "storage_buffer": {
              "slot": 16,
              "stage": "vertex",
              "size": 32,
              "align": 16,
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          },
          {
            "storage_buffer": {
              "slot": 17,
              "stage": "fragment",
              "size": 32,
              "align": 16,
              "struct_name": "fa_points_buf",
              "inst_name": "points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 1
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_inst_base[4];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _100 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _100) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_100 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
            "inst_name": "_159",
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
            "inst_name": "_176",
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nstruct points_item\n{\n    vec4 pos;\n    vec4 tint;\n};\n\nlayout(binding = 0, std430) readonly buffer fa_vs_points_buf\n{\n    points_item data[];\n} fa_vs_points;\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_inst_base[4];\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _199 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_199 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_199 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_199 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _105 = cross(model[1].xyz, model[2].xyz);\n    float _110 = (dot(model[0].xyz, _105) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_105 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _110, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _110), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    if (fa_vs_points.data[gl_InstanceID].pos.w < 0.5)\n    {\n        v.world_pos = vec3(1000000000.0);\n        return;\n    }\n    v.world_pos += fa_vs_points.data[gl_InstanceID].pos.xyz;\n    v.color = fa_vs_points.data[gl_InstanceID].tint;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_base[0], fa_inst_base[1], fa_inst_base[2], fa_inst_base[3]) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "inst_name": "_164",
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
            "inst_name": "_208",
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
            "inst_name": "_288",
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
              "struct_name": "fa_vs_points_buf",
              "inst_name": "fa_vs_points",
              "inner_struct_name": "points_item",
              "readonly": true,
              "glsl_binding_n": 0
            }
          }
        ]
      }
    }
  }
}
