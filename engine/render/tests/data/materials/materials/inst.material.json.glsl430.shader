{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "67b1186c6e51021b07dd68cec7aaad42a4febc7364ef358b4473bc1e089911c0",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out vec4 fa_shadow_pos;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    vec4 _193 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _193;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _193;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _796[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 7) in vec4 fa_shadow_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1728 = fa_linear_to_srgb(param);\n        c = _1728;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1736 = fa_srgb_to_linear(param_1);\n            c = _1736;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _180;\n    if (i.front_facing)\n    {\n        _180 = i.world_normal;\n    }\n    else\n    {\n        _180 = -i.world_normal;\n    }\n    vec3 _204 = normalize(i.world_tangent.xyz - (_180 * dot(_180, i.world_tangent.xyz)));\n    vec3 _232 = normalize(((_204 * m.x) + ((cross(_180, _204) * i.world_tangent.w) * m.y)) + (_180 * m.z));\n    vec3 _235;\n    if (i.front_facing)\n    {\n        _235 = _232;\n    }\n    else\n    {\n        _235 = -_232;\n    }\n    return _235;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1767 = fa_tex_fix(param_2, param_3);\n    vec4 _2924 = base_t;\n    _2924.x = _1767.x;\n    _2924.y = _1767.y;\n    _2924.z = _1767.z;\n    base_t = _2924;\n    vec4 _1781 = (_2924 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2867 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1814 = fa_tex_fix(param_6, param_7);\n        vec3 _1817 = (_1814 * 2.0) - vec3(1.0);\n        vec2 _1822 = _1817.xy * fa_mesh_fs_params[6].x;\n        vec3 _2932 = _1817;\n        _2932.x = _1822.x;\n        _2932.y = _1822.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2932;\n        _2867 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1851 = fa_tex_fix(param_12, param_13);\n    vec4 _2935 = mrt;\n    _2935.x = _1851.x;\n    _2935.y = _1851.y;\n    _2935.z = _1851.z;\n    mrt = _2935;\n    vec4 _1879 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1879.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1891 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1921 = fa_tex_fix(param_20, param_21);\n    float _2872 = fa_mesh_fs_params[14].x;\n    float _2873 = fa_mesh_fs_params[14].y;\n    float _2876 = fa_mesh_fs_params[14].z;\n    float _2875 = fa_mesh_fs_params[15].w;\n    float _2878 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2872 *= _1891.y;\n            _2873 *= _1891.z;\n            _2875 *= _1879.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2876 *= mrt.x;\n            _2878 *= mrt.w;\n        }\n    }\n    return Surface(_1781.xyz, _1781.w, _2867, clamp(fa_mesh_fs_params[5].x * _1851.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1851.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1891.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1921), _2872, _2873, fa_mesh_fs_params[15].xyz, _2875, _2876, fa_mesh_fs_params[14].w, _2878, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _721 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _729 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _732 = int(_721);\n    int _735 = int(_729);\n    float _745 = _729 - float(_735);\n    int _801 = (_732 * 9) + _735;\n    int _821 = ((_732 + 1) * 9) + _735;\n    return mix(mix(_796[_801], _796[_801 + 1], _745), mix(_796[_821], _796[_821 + 1], _745), _721 - float(_732));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2803 = false;\n    float _2804 = 1.0;\n    float _2805 = 1.0;\n    float _2806 = 1.0;\n    float _2807 = 0.0;\n    float _2808 = 0.0;\n    float _2809 = 0.0;\n    float _2810 = 0.0;\n    float _2812 = 1.0;\n    bool _2813 = false;\n    vec3 _2814 = vec3(0.0);\n    float _2815 = 1.0;\n    float _2816 = 1.0;\n    float _2817 = 1.0;\n    float _2818 = 0.0;\n    float _2819 = 0.0;\n    vec3 _2820 = vec3(1.0, 0.0, 0.0);\n    vec3 _2821 = vec3(0.0, 0.0, 1.0);\n    float _2822 = 1.0;\n    float _2823 = 1.0;\n    float _883 = clamp(s.specular, 0.0, 1.0);\n    float _888 = clamp(s.ior, 1.0, 3.0);\n    bool _893 = (_883 != 1.0) || (_888 != 1.5);\n    bool _903;\n    if (!_893)\n    {\n        _903 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _903 = _893;\n    }\n    if (_903)\n    {\n        float _911 = (_888 - 1.0) / (_888 + 1.0);\n        f0 = mix(min(vec3(_911 * _911) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _883, s.albedo, vec3(metallic));\n        _2804 = mix(_883, 1.0, metallic);\n        _2803 = true;\n    }\n    float _939 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_939 > 0.0)\n    {\n        float _947 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2807 = _939;\n        _2808 = _947;\n        float _954 = _947 * _947;\n        _2809 = _954;\n        _2810 = _954 * _954;\n        float _966 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2812 = _966;\n        _2805 = 1.0 - (_939 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _966, 0.0, 1.0), 5.0))));\n        _2803 = true;\n    }\n    vec3 _986 = max(s.sheen_color, vec3(0.0));\n    float _995 = max(_986.x, max(_986.y, _986.z));\n    if (_995 > 0.0)\n    {\n        float _1003 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2813 = true;\n        _2814 = _986;\n        _2815 = _1003;\n        _2816 = _1003 * _1003;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1003;\n        float _1020 = fa_sheen_albedo(param, param_1);\n        _2818 = _1020;\n        _2817 = 1.0 - min(_995 * _1020, 1.0);\n        _2803 = true;\n    }\n    _2806 = _2805 * _2817;\n    float _1039 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1039 != 0.0)\n    {\n        vec3 _1054 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1054;\n        if (dot(_1054, _1054) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1068 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1068.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1068.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1068.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1072 = t;\n        vec3 _1073 = normalize(_1072);\n        t = _1073;\n        vec3 _1098 = normalize((_1073 * cos(s.anisotropy_rotation)) + ((cross(n, _1073) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2820 = _1098;\n        _2821 = cross(n, _1098);\n        float _1108 = roughness * roughness;\n        float _1114 = mix(_1108, 1.0, _1039 * _1039);\n        bool _1116 = _1039 > 0.0;\n        _2822 = _1116 ? _1114 : _1108;\n        _2823 = _1116 ? _1108 : _1114;\n        _2819 = _1039;\n        _2803 = true;\n    }\n    return FaLayers(_2803, _2804, _2805, _2806, _2807, _2808, _2809, _2810, i.world_normal, _2812, _2813, _2814, _2815, _2816, _2817, _2818, _2819, _2820, _2821, _2822, _2823);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _263 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_263)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _281 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _283 = length(_281);\n        dist = _283;\n        l = _281 / vec3(max(_283, 9.9999997473787516355514526367188e-05));\n        float _299 = _283 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _305 = clamp(1.0 - (_299 * _299), 0.0, 1.0);\n        atten = _305 * _305;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _356;\n    if (_263)\n    {\n        _356 = 0;\n    }\n    else\n    {\n        _356 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _356);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _383 = coord.xyz / vec3(coord.w);\n    vec3 p = _383;\n    vec2 suv = (_383.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2899 = p;\n        _2899.z = (_2899.z * 0.5) + 0.5;\n        p = _2899;\n    }\n    else\n    {\n        vec2 _2902 = suv;\n        _2902.y = 1.0 - _2902.y;\n        suv = _2902;\n    }\n    bool _411 = suv.x < 0.0;\n    bool _418;\n    if (!_411)\n    {\n        _418 = suv.x > 1.0;\n    }\n    else\n    {\n        _418 = _411;\n    }\n    bool _425;\n    if (!_418)\n    {\n        _425 = suv.y < 0.0;\n    }\n    else\n    {\n        _425 = _418;\n    }\n    bool _432;\n    if (!_425)\n    {\n        _432 = suv.y > 1.0;\n    }\n    else\n    {\n        _432 = _425;\n    }\n    bool _439;\n    if (!_432)\n    {\n        _439 = p.z > 1.0;\n    }\n    else\n    {\n        _439 = _432;\n    }\n    if (_439)\n    {\n        return 1.0;\n    }\n    float _454 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _454) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1620 = fa_light_sample(param, param_1);\n    vec3 _2852 = _1620.direction;\n    vec3 _2847 = _1620.color;\n    float _2854 = _1620.attenuation;\n    float _2849 = _1620.shadow;\n    int _2857 = _1620.type;\n    if ((_2857 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2852;\n        float _1634 = fa_shadow_factor(param_2, param_3);\n        _2849 = _1634;\n        _2847 = fa_lights[li * 1 + 32].xyz * (_2854 * _1634);\n    }\n    return LightSample(_2852, _2847, _2854, _2849, _1620._distance, _2857);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1266 = tdh / at;\n    float _1270 = bdh / ab;\n    float _1282 = ((_1266 * _1266) + (_1270 * _1270)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _1282) * _1282);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1364 = 1.0 / alpha;\n    return ((2.0 + _1364) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _1364)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1397 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1476 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1476) * _1476);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1397);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1397));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1549 = max(dot(L.nc, l), 0.0);\n        float _1555 = max(dot(L.nc, h), 0.0);\n        float _1564 = ((_1555 * _1555) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1564) * _1564)) * (0.5 / max(mix((2.0 * _1549) * L.coat_ndv, _1549 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1549)) * _1549);\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _651 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _654 = _651.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_654 * _654, exp2((-9.27999973297119140625) * ndv)) * _654) + _651.y)) + _651.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _554 = rough * rough;\n    float _585 = 0.60000002384185791015625 * _554;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _554)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _585, 0.0500000007450580596923828125 + _585, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_554 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1149;\n        if (L.aniso >= 0.0)\n        {\n            _1149 = L.b;\n        }\n        else\n        {\n            _1149 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1149, v), _1149), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1182 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1182.x) + (vec3(L.f90) * _1182.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1237 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1237.x) + _1237.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _693 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _693.x) + vec3(_693.y));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2582 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2582 = -_2582;\n    }\n    vec3 _2041 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing);\n    Surface _2046 = fa_standard_surface(param);\n    vec3 _2613 = _2046.albedo;\n    float _2614 = _2046.alpha;\n    vec3 _2615 = _2046.normal;\n    float _2616 = _2046.metallic;\n    float _2617 = _2046.roughness;\n    float _2618 = _2046.occlusion;\n    vec3 _2619 = _2046.emission;\n    float _2620 = _2046.clearcoat;\n    float _2621 = _2046.clearcoat_roughness;\n    vec3 _2622 = _2046.sheen_color;\n    float _2623 = _2046.sheen_roughness;\n    float _2624 = _2046.anisotropy;\n    float _2625 = _2046.anisotropy_rotation;\n    float _2626 = _2046.specular;\n    float _2627 = _2046.ior;\n    vec3 _2628 = _2046.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing);\n    Surface param_2 = _2046;\n    surface(param_1, param_2);\n    _2613 = param_2.albedo;\n    _2614 = param_2.alpha;\n    _2615 = param_2.normal;\n    _2616 = param_2.metallic;\n    _2617 = param_2.roughness;\n    _2618 = param_2.occlusion;\n    _2619 = param_2.emission;\n    _2620 = param_2.clearcoat;\n    _2621 = param_2.clearcoat_roughness;\n    _2622 = param_2.sheen_color;\n    _2623 = param_2.sheen_roughness;\n    _2624 = param_2.anisotropy;\n    _2625 = param_2.anisotropy_rotation;\n    _2626 = param_2.specular;\n    _2627 = param_2.ior;\n    _2628 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2613;\n    }\n    else\n    {\n        vec3 _2068 = normalize(_2615);\n        float _2075 = clamp(_2616, 0.0, 1.0);\n        float _2079 = clamp(_2617, 0.0500000007450580596923828125, 1.0);\n        float _2083 = _2079 * _2079;\n        float _2087 = _2083 * _2083;\n        float _2092 = max(dot(_2068, _2041), 9.9999997473787516355514526367188e-05);\n        vec3 _2098 = _2613 * (1.0 - _2075);\n        vec3 _2105 = mix(vec3(0.039999999105930328369140625), _2613, vec3(_2075));\n        vec3 f0 = _2105;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing);\n        Surface param_4 = Surface(_2613, _2614, _2615, _2616, _2617, _2618, _2619, _2620, _2621, _2622, _2623, _2624, _2625, _2626, _2627, _2628);\n        vec3 param_5 = _2068;\n        vec3 param_6 = _2041;\n        float param_7 = _2075;\n        float param_8 = _2079;\n        vec3 param_9 = _2105;\n        FaLayers _2121 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        vec3 param_10 = _2068;\n        vec3 lit = (fa_ambient_light(param_10) * _2098) * _2618;\n        if (_2121.on)\n        {\n            lit *= _2121.base_scale;\n        }\n        int _2143 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2143)\n            {\n                break;\n            }\n            int param_11 = li;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _2582;\n            LightSample _2167 = fa_light_shadowed(param_11, param_12, param_13);\n            vec3 _2787 = _2167.direction;\n            float _2175 = max(dot(_2068, _2787), 0.0);\n            float _2181 = _2167.attenuation * _2167.shadow;\n            vec3 _2186 = normalize(_2787 + _2041);\n            float _2191 = max(dot(_2068, _2186), 0.0);\n            float _2196 = max(dot(_2041, _2186), 0.0);\n            if (_2121.on)\n            {\n                FaLayers param_14 = _2121;\n                vec3 param_15 = _2098;\n                vec3 param_16 = f0;\n                vec3 param_17 = _2068;\n                vec3 param_18 = _2041;\n                vec3 param_19 = _2787;\n                vec3 param_20 = _2186;\n                float param_21 = _2175;\n                float param_22 = _2092;\n                float param_23 = _2191;\n                float param_24 = _2196;\n                float param_25 = _2083;\n                float param_26 = _2087;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (fa_lights[li * 1 + 32].xyz * _2181));\n            }\n            else\n            {\n                float _2245 = ((_2191 * _2191) * (_2087 - 1.0)) + 1.0;\n                lit += (((_2098 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _2196, 5.0))) * (((_2087 / ((3.1415927410125732421875 * _2245) * _2245)) * (0.5 / max(mix((2.0 * _2175) * _2092, _2175 + _2092, _2083), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2175))) * fa_lights[li * 1 + 32].xyz) * (_2175 * _2181));\n            }\n        }\n        if (_2121.on)\n        {\n            FaLayers param_27 = _2121;\n            vec3 param_28 = _2068;\n            vec3 param_29 = _2041;\n            vec3 param_30 = f0;\n            float param_31 = _2079;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2618);\n        }\n        else\n        {\n            vec3 param_32 = _2068;\n            vec3 param_33 = _2041;\n            vec3 param_34 = f0;\n            float param_35 = _2079;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2618);\n        }\n        result = lit;\n    }\n    result += _2619;\n    bool _2343 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2350;\n    if (!_2343)\n    {\n        _2350 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2350 = _2343;\n    }\n    if (_2350)\n    {\n        vec3 _2359 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2365 = dot(_2359, fa_mesh_fs_params[9].xyz);\n        bool _2369 = fa_mesh_fs_params[9].w > 0.5;\n        float _2370;\n        if (_2369)\n        {\n            _2370 = _2365;\n        }\n        else\n        {\n            _2370 = length(_2359);\n        }\n        float _2382 = _2370 - fa_mesh_fs_params[8].x;\n        if (_2382 > 0.0)\n        {\n            float _2391 = fa_mesh_fs_params[7].w * _2382;\n            float tau = _2391 * _2391;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2407;\n                if (_2369)\n                {\n                    _2407 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2365);\n                }\n                else\n                {\n                    _2407 = fa_mesh_fs_params[0].y;\n                }\n                float _2428 = mix(_2407, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2370, 0.0, 1.0));\n                float _2432 = fa_world_pos.y - _2428;\n                float _2437 = _2428 - fa_mesh_fs_params[8].z;\n                float _2442 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2445 = _2437 <= 0.0;\n                bool _2446 = !_2445;\n                bool _2452;\n                if (_2446)\n                {\n                    _2452 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2452 = _2445;\n                }\n                float _2453;\n                if (_2452)\n                {\n                    _2453 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2453 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2437, 80.0));\n                }\n                bool _2480;\n                if (_2446)\n                {\n                    _2480 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2480 = _2445;\n                }\n                float _2481;\n                if (_2480)\n                {\n                    _2481 = fa_mesh_fs_params[8].y * _2437;\n                }\n                else\n                {\n                    _2481 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2437, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2506 = _2442 <= 0.0;\n                bool _2513;\n                if (!_2506)\n                {\n                    _2513 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2513 = _2506;\n                }\n                float _2514;\n                if (_2513)\n                {\n                    _2514 = fa_mesh_fs_params[8].y * _2442;\n                }\n                else\n                {\n                    _2514 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2442, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2541;\n                if (abs(_2432) < 0.001000000047497451305389404296875)\n                {\n                    _2541 = _2453;\n                }\n                else\n                {\n                    _2541 = (_2514 - _2481) / _2432;\n                }\n                tau += (_2382 * max(_2541, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2614);\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_252",
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
            "inst_name": "_370",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 18,
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
            "inst_name": "_1664",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out vec4 fa_shadow_pos;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    vec4 _306 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _306;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _306;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _796[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 7) in vec4 fa_shadow_pos;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1728 = fa_linear_to_srgb(param);\n        c = _1728;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1736 = fa_srgb_to_linear(param_1);\n            c = _1736;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _180;\n    if (i.front_facing)\n    {\n        _180 = i.world_normal;\n    }\n    else\n    {\n        _180 = -i.world_normal;\n    }\n    vec3 _204 = normalize(i.world_tangent.xyz - (_180 * dot(_180, i.world_tangent.xyz)));\n    vec3 _232 = normalize(((_204 * m.x) + ((cross(_180, _204) * i.world_tangent.w) * m.y)) + (_180 * m.z));\n    vec3 _235;\n    if (i.front_facing)\n    {\n        _235 = _232;\n    }\n    else\n    {\n        _235 = -_232;\n    }\n    return _235;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1767 = fa_tex_fix(param_2, param_3);\n    vec4 _2924 = base_t;\n    _2924.x = _1767.x;\n    _2924.y = _1767.y;\n    _2924.z = _1767.z;\n    base_t = _2924;\n    vec4 _1781 = (_2924 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2867 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1814 = fa_tex_fix(param_6, param_7);\n        vec3 _1817 = (_1814 * 2.0) - vec3(1.0);\n        vec2 _1822 = _1817.xy * fa_mesh_fs_params[6].x;\n        vec3 _2932 = _1817;\n        _2932.x = _1822.x;\n        _2932.y = _1822.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2932;\n        _2867 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1851 = fa_tex_fix(param_12, param_13);\n    vec4 _2935 = mrt;\n    _2935.x = _1851.x;\n    _2935.y = _1851.y;\n    _2935.z = _1851.z;\n    mrt = _2935;\n    vec4 _1879 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1879.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1891 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1921 = fa_tex_fix(param_20, param_21);\n    float _2872 = fa_mesh_fs_params[14].x;\n    float _2873 = fa_mesh_fs_params[14].y;\n    float _2876 = fa_mesh_fs_params[14].z;\n    float _2875 = fa_mesh_fs_params[15].w;\n    float _2878 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2872 *= _1891.y;\n            _2873 *= _1891.z;\n            _2875 *= _1879.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2876 *= mrt.x;\n            _2878 *= mrt.w;\n        }\n    }\n    return Surface(_1781.xyz, _1781.w, _2867, clamp(fa_mesh_fs_params[5].x * _1851.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1851.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1891.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1921), _2872, _2873, fa_mesh_fs_params[15].xyz, _2875, _2876, fa_mesh_fs_params[14].w, _2878, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _721 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _729 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _732 = int(_721);\n    int _735 = int(_729);\n    float _745 = _729 - float(_735);\n    int _801 = (_732 * 9) + _735;\n    int _821 = ((_732 + 1) * 9) + _735;\n    return mix(mix(_796[_801], _796[_801 + 1], _745), mix(_796[_821], _796[_821 + 1], _745), _721 - float(_732));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2803 = false;\n    float _2804 = 1.0;\n    float _2805 = 1.0;\n    float _2806 = 1.0;\n    float _2807 = 0.0;\n    float _2808 = 0.0;\n    float _2809 = 0.0;\n    float _2810 = 0.0;\n    float _2812 = 1.0;\n    bool _2813 = false;\n    vec3 _2814 = vec3(0.0);\n    float _2815 = 1.0;\n    float _2816 = 1.0;\n    float _2817 = 1.0;\n    float _2818 = 0.0;\n    float _2819 = 0.0;\n    vec3 _2820 = vec3(1.0, 0.0, 0.0);\n    vec3 _2821 = vec3(0.0, 0.0, 1.0);\n    float _2822 = 1.0;\n    float _2823 = 1.0;\n    float _883 = clamp(s.specular, 0.0, 1.0);\n    float _888 = clamp(s.ior, 1.0, 3.0);\n    bool _893 = (_883 != 1.0) || (_888 != 1.5);\n    bool _903;\n    if (!_893)\n    {\n        _903 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _903 = _893;\n    }\n    if (_903)\n    {\n        float _911 = (_888 - 1.0) / (_888 + 1.0);\n        f0 = mix(min(vec3(_911 * _911) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _883, s.albedo, vec3(metallic));\n        _2804 = mix(_883, 1.0, metallic);\n        _2803 = true;\n    }\n    float _939 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_939 > 0.0)\n    {\n        float _947 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2807 = _939;\n        _2808 = _947;\n        float _954 = _947 * _947;\n        _2809 = _954;\n        _2810 = _954 * _954;\n        float _966 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2812 = _966;\n        _2805 = 1.0 - (_939 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _966, 0.0, 1.0), 5.0))));\n        _2803 = true;\n    }\n    vec3 _986 = max(s.sheen_color, vec3(0.0));\n    float _995 = max(_986.x, max(_986.y, _986.z));\n    if (_995 > 0.0)\n    {\n        float _1003 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2813 = true;\n        _2814 = _986;\n        _2815 = _1003;\n        _2816 = _1003 * _1003;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1003;\n        float _1020 = fa_sheen_albedo(param, param_1);\n        _2818 = _1020;\n        _2817 = 1.0 - min(_995 * _1020, 1.0);\n        _2803 = true;\n    }\n    _2806 = _2805 * _2817;\n    float _1039 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1039 != 0.0)\n    {\n        vec3 _1054 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1054;\n        if (dot(_1054, _1054) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1068 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1068.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1068.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1068.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1072 = t;\n        vec3 _1073 = normalize(_1072);\n        t = _1073;\n        vec3 _1098 = normalize((_1073 * cos(s.anisotropy_rotation)) + ((cross(n, _1073) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2820 = _1098;\n        _2821 = cross(n, _1098);\n        float _1108 = roughness * roughness;\n        float _1114 = mix(_1108, 1.0, _1039 * _1039);\n        bool _1116 = _1039 > 0.0;\n        _2822 = _1116 ? _1114 : _1108;\n        _2823 = _1116 ? _1108 : _1114;\n        _2819 = _1039;\n        _2803 = true;\n    }\n    return FaLayers(_2803, _2804, _2805, _2806, _2807, _2808, _2809, _2810, i.world_normal, _2812, _2813, _2814, _2815, _2816, _2817, _2818, _2819, _2820, _2821, _2822, _2823);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _263 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_263)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _281 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _283 = length(_281);\n        dist = _283;\n        l = _281 / vec3(max(_283, 9.9999997473787516355514526367188e-05));\n        float _299 = _283 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _305 = clamp(1.0 - (_299 * _299), 0.0, 1.0);\n        atten = _305 * _305;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _356;\n    if (_263)\n    {\n        _356 = 0;\n    }\n    else\n    {\n        _356 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _356);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _383 = coord.xyz / vec3(coord.w);\n    vec3 p = _383;\n    vec2 suv = (_383.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2899 = p;\n        _2899.z = (_2899.z * 0.5) + 0.5;\n        p = _2899;\n    }\n    else\n    {\n        vec2 _2902 = suv;\n        _2902.y = 1.0 - _2902.y;\n        suv = _2902;\n    }\n    bool _411 = suv.x < 0.0;\n    bool _418;\n    if (!_411)\n    {\n        _418 = suv.x > 1.0;\n    }\n    else\n    {\n        _418 = _411;\n    }\n    bool _425;\n    if (!_418)\n    {\n        _425 = suv.y < 0.0;\n    }\n    else\n    {\n        _425 = _418;\n    }\n    bool _432;\n    if (!_425)\n    {\n        _432 = suv.y > 1.0;\n    }\n    else\n    {\n        _432 = _425;\n    }\n    bool _439;\n    if (!_432)\n    {\n        _439 = p.z > 1.0;\n    }\n    else\n    {\n        _439 = _432;\n    }\n    if (_439)\n    {\n        return 1.0;\n    }\n    float _454 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _454) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1620 = fa_light_sample(param, param_1);\n    vec3 _2852 = _1620.direction;\n    vec3 _2847 = _1620.color;\n    float _2854 = _1620.attenuation;\n    float _2849 = _1620.shadow;\n    int _2857 = _1620.type;\n    if ((_2857 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2852;\n        float _1634 = fa_shadow_factor(param_2, param_3);\n        _2849 = _1634;\n        _2847 = fa_lights[li * 1 + 32].xyz * (_2854 * _1634);\n    }\n    return LightSample(_2852, _2847, _2854, _2849, _1620._distance, _2857);\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _1266 = tdh / at;\n    float _1270 = bdh / ab;\n    float _1282 = ((_1266 * _1266) + (_1270 * _1270)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _1282) * _1282);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _1364 = 1.0 / alpha;\n    return ((2.0 + _1364) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _1364)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _1397 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _1476 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _1476) * _1476);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _1397);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _1397));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        float _1549 = max(dot(L.nc, l), 0.0);\n        float _1555 = max(dot(L.nc, h), 0.0);\n        float _1564 = ((_1555 * _1555) * (L.coat_a2 - 1.0)) + 1.0;\n        result += vec3((((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _1564) * _1564)) * (0.5 / max(mix((2.0 * _1549) * L.coat_ndv, _1549 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1549)) * _1549);\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _651 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _654 = _651.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_654 * _654, exp2((-9.27999973297119140625) * ndv)) * _654) + _651.y)) + _651.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _554 = rough * rough;\n    float _585 = 0.60000002384185791015625 * _554;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _554)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _585, 0.0500000007450580596923828125 + _585, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_554 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1149;\n        if (L.aniso >= 0.0)\n        {\n            _1149 = L.b;\n        }\n        else\n        {\n            _1149 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1149, v), _1149), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1182 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1182.x) + (vec3(L.f90) * _1182.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1237 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1237.x) + _1237.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _693 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _693.x) + vec3(_693.y));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2582 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2582 = -_2582;\n    }\n    vec3 _2041 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing);\n    Surface _2046 = fa_standard_surface(param);\n    vec3 _2613 = _2046.albedo;\n    float _2614 = _2046.alpha;\n    vec3 _2615 = _2046.normal;\n    float _2616 = _2046.metallic;\n    float _2617 = _2046.roughness;\n    float _2618 = _2046.occlusion;\n    vec3 _2619 = _2046.emission;\n    float _2620 = _2046.clearcoat;\n    float _2621 = _2046.clearcoat_roughness;\n    vec3 _2622 = _2046.sheen_color;\n    float _2623 = _2046.sheen_roughness;\n    float _2624 = _2046.anisotropy;\n    float _2625 = _2046.anisotropy_rotation;\n    float _2626 = _2046.specular;\n    float _2627 = _2046.ior;\n    vec3 _2628 = _2046.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing);\n    Surface param_2 = _2046;\n    surface(param_1, param_2);\n    _2613 = param_2.albedo;\n    _2614 = param_2.alpha;\n    _2615 = param_2.normal;\n    _2616 = param_2.metallic;\n    _2617 = param_2.roughness;\n    _2618 = param_2.occlusion;\n    _2619 = param_2.emission;\n    _2620 = param_2.clearcoat;\n    _2621 = param_2.clearcoat_roughness;\n    _2622 = param_2.sheen_color;\n    _2623 = param_2.sheen_roughness;\n    _2624 = param_2.anisotropy;\n    _2625 = param_2.anisotropy_rotation;\n    _2626 = param_2.specular;\n    _2627 = param_2.ior;\n    _2628 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2613;\n    }\n    else\n    {\n        vec3 _2068 = normalize(_2615);\n        float _2075 = clamp(_2616, 0.0, 1.0);\n        float _2079 = clamp(_2617, 0.0500000007450580596923828125, 1.0);\n        float _2083 = _2079 * _2079;\n        float _2087 = _2083 * _2083;\n        float _2092 = max(dot(_2068, _2041), 9.9999997473787516355514526367188e-05);\n        vec3 _2098 = _2613 * (1.0 - _2075);\n        vec3 _2105 = mix(vec3(0.039999999105930328369140625), _2613, vec3(_2075));\n        vec3 f0 = _2105;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _2582, fa_world_tangent, fa_uv, fa_vertex_color, _2041, gl_FrontFacing);\n        Surface param_4 = Surface(_2613, _2614, _2615, _2616, _2617, _2618, _2619, _2620, _2621, _2622, _2623, _2624, _2625, _2626, _2627, _2628);\n        vec3 param_5 = _2068;\n        vec3 param_6 = _2041;\n        float param_7 = _2075;\n        float param_8 = _2079;\n        vec3 param_9 = _2105;\n        FaLayers _2121 = fa_layers_setup(param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n        f0 = param_9;\n        vec3 param_10 = _2068;\n        vec3 lit = (fa_ambient_light(param_10) * _2098) * _2618;\n        if (_2121.on)\n        {\n            lit *= _2121.base_scale;\n        }\n        int _2143 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _2143)\n            {\n                break;\n            }\n            int param_11 = li;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _2582;\n            LightSample _2167 = fa_light_shadowed(param_11, param_12, param_13);\n            vec3 _2787 = _2167.direction;\n            float _2175 = max(dot(_2068, _2787), 0.0);\n            float _2181 = _2167.attenuation * _2167.shadow;\n            vec3 _2186 = normalize(_2787 + _2041);\n            float _2191 = max(dot(_2068, _2186), 0.0);\n            float _2196 = max(dot(_2041, _2186), 0.0);\n            if (_2121.on)\n            {\n                FaLayers param_14 = _2121;\n                vec3 param_15 = _2098;\n                vec3 param_16 = f0;\n                vec3 param_17 = _2068;\n                vec3 param_18 = _2041;\n                vec3 param_19 = _2787;\n                vec3 param_20 = _2186;\n                float param_21 = _2175;\n                float param_22 = _2092;\n                float param_23 = _2191;\n                float param_24 = _2196;\n                float param_25 = _2083;\n                float param_26 = _2087;\n                lit += (fa_layers_light(param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21, param_22, param_23, param_24, param_25, param_26) * (fa_lights[li * 1 + 32].xyz * _2181));\n            }\n            else\n            {\n                float _2245 = ((_2191 * _2191) * (_2087 - 1.0)) + 1.0;\n                lit += (((_2098 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _2196, 5.0))) * (((_2087 / ((3.1415927410125732421875 * _2245) * _2245)) * (0.5 / max(mix((2.0 * _2175) * _2092, _2175 + _2092, _2083), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _2175))) * fa_lights[li * 1 + 32].xyz) * (_2175 * _2181));\n            }\n        }\n        if (_2121.on)\n        {\n            FaLayers param_27 = _2121;\n            vec3 param_28 = _2068;\n            vec3 param_29 = _2041;\n            vec3 param_30 = f0;\n            float param_31 = _2079;\n            lit += (fa_layers_ibl(param_27, param_28, param_29, param_30, param_31) * _2618);\n        }\n        else\n        {\n            vec3 param_32 = _2068;\n            vec3 param_33 = _2041;\n            vec3 param_34 = f0;\n            float param_35 = _2079;\n            lit += (fa_sky_reflection(param_32, param_33, param_34, param_35) * _2618);\n        }\n        result = lit;\n    }\n    result += _2619;\n    bool _2343 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2350;\n    if (!_2343)\n    {\n        _2350 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2350 = _2343;\n    }\n    if (_2350)\n    {\n        vec3 _2359 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2365 = dot(_2359, fa_mesh_fs_params[9].xyz);\n        bool _2369 = fa_mesh_fs_params[9].w > 0.5;\n        float _2370;\n        if (_2369)\n        {\n            _2370 = _2365;\n        }\n        else\n        {\n            _2370 = length(_2359);\n        }\n        float _2382 = _2370 - fa_mesh_fs_params[8].x;\n        if (_2382 > 0.0)\n        {\n            float _2391 = fa_mesh_fs_params[7].w * _2382;\n            float tau = _2391 * _2391;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2407;\n                if (_2369)\n                {\n                    _2407 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2365);\n                }\n                else\n                {\n                    _2407 = fa_mesh_fs_params[0].y;\n                }\n                float _2428 = mix(_2407, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2370, 0.0, 1.0));\n                float _2432 = fa_world_pos.y - _2428;\n                float _2437 = _2428 - fa_mesh_fs_params[8].z;\n                float _2442 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2445 = _2437 <= 0.0;\n                bool _2446 = !_2445;\n                bool _2452;\n                if (_2446)\n                {\n                    _2452 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2452 = _2445;\n                }\n                float _2453;\n                if (_2452)\n                {\n                    _2453 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2453 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2437, 80.0));\n                }\n                bool _2480;\n                if (_2446)\n                {\n                    _2480 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2480 = _2445;\n                }\n                float _2481;\n                if (_2480)\n                {\n                    _2481 = fa_mesh_fs_params[8].y * _2437;\n                }\n                else\n                {\n                    _2481 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2437, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2506 = _2442 <= 0.0;\n                bool _2513;\n                if (!_2506)\n                {\n                    _2513 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2513 = _2506;\n                }\n                float _2514;\n                if (_2513)\n                {\n                    _2514 = fa_mesh_fs_params[8].y * _2442;\n                }\n                else\n                {\n                    _2514 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2442, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2541;\n                if (abs(_2432) < 0.001000000047497451305389404296875)\n                {\n                    _2541 = _2453;\n                }\n                else\n                {\n                    _2541 = (_2514 - _2481) / _2432;\n                }\n                tau += (_2382 * max(_2541, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2614);\n}\n\n",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_252",
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
            "inst_name": "_370",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 18,
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
            "inst_name": "_1664",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _767 = base_t;\n    _767.x = _264.x;\n    _767.y = _264.y;\n    _767.z = _264.z;\n    base_t = _767;\n    vec4 _280 = (_767 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _730 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _775 = _317;\n        _775.x = _322.x;\n        _775.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _775;\n        _730 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _778 = mrt;\n    _778.x = _351.x;\n    _778.y = _351.y;\n    _778.z = _351.z;\n    mrt = _778;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _735 = fa_mesh_fs_params[14].x;\n    float _736 = fa_mesh_fs_params[14].y;\n    float _739 = fa_mesh_fs_params[14].z;\n    float _738 = fa_mesh_fs_params[15].w;\n    float _741 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _735 *= _393.y;\n            _736 *= _393.z;\n            _738 *= _381.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _739 *= mrt.x;\n            _741 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _730, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _735, _736, fa_mesh_fs_params[15].xyz, _738, _739, fa_mesh_fs_params[14].w, _741, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _641 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _641 = -_641;\n    }\n    vec3 _554 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _569 = normalize(param_2.normal);\n    vec3 _584 = normalize(vec3(dot(fa_pre_r0, _569), dot(fa_pre_r1, _569), dot(fa_pre_r2, _569)));\n    float _596 = _584.z;\n    vec2 e = _584.xy / vec2((abs(_584.x) + abs(_584.y)) + abs(_596));\n    if (_596 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _767 = base_t;\n    _767.x = _264.x;\n    _767.y = _264.y;\n    _767.z = _264.z;\n    base_t = _767;\n    vec4 _280 = (_767 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _730 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _775 = _317;\n        _775.x = _322.x;\n        _775.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _775;\n        _730 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _778 = mrt;\n    _778.x = _351.x;\n    _778.y = _351.y;\n    _778.z = _351.z;\n    mrt = _778;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _735 = fa_mesh_fs_params[14].x;\n    float _736 = fa_mesh_fs_params[14].y;\n    float _739 = fa_mesh_fs_params[14].z;\n    float _738 = fa_mesh_fs_params[15].w;\n    float _741 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _735 *= _393.y;\n            _736 *= _393.z;\n            _738 *= _381.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _739 *= mrt.x;\n            _741 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _730, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _735, _736, fa_mesh_fs_params[15].xyz, _738, _739, fa_mesh_fs_params[14].w, _741, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _641 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _641 = -_641;\n    }\n    vec3 _554 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _554, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _569 = normalize(param_2.normal);\n    vec3 _584 = normalize(vec3(dot(fa_pre_r0, _569), dot(fa_pre_r1, _569), dot(fa_pre_r2, _569)));\n    float _596 = _584.z;\n    vec2 e = _584.xy / vec2((abs(_584.x) + abs(_584.y)) + abs(_596));\n    if (_596 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
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
