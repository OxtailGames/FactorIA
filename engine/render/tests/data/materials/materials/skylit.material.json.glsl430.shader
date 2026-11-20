{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "67b1186c6e51021b07dd68cec7aaad42a4febc7364ef358b4473bc1e089911c0",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    vec4 _167 = vec4(_270, 1.0);\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _167;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _167;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _757[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 6) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1387 = fa_linear_to_srgb(param);\n        c = _1387;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1395 = fa_srgb_to_linear(param_1);\n            c = _1395;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _142;\n    if (i.front_facing)\n    {\n        _142 = i.world_normal;\n    }\n    else\n    {\n        _142 = -i.world_normal;\n    }\n    vec3 _166 = normalize(i.world_tangent.xyz - (_142 * dot(_142, i.world_tangent.xyz)));\n    vec3 _194 = normalize(((_166 * m.x) + ((cross(_142, _166) * i.world_tangent.w) * m.y)) + (_142 * m.z));\n    vec3 _197;\n    if (i.front_facing)\n    {\n        _197 = _194;\n    }\n    else\n    {\n        _197 = -_194;\n    }\n    return _197;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1427 = fa_tex_fix(param_2, param_3);\n    vec4 _2385 = base_t;\n    _2385.x = _1427.x;\n    _2385.y = _1427.y;\n    _2385.z = _1427.z;\n    base_t = _2385;\n    vec4 _1441 = (_2385 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2328 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1474 = fa_tex_fix(param_6, param_7);\n        vec3 _1477 = (_1474 * 2.0) - vec3(1.0);\n        vec2 _1482 = _1477.xy * fa_mesh_fs_params[6].x;\n        vec3 _2393 = _1477;\n        _2393.x = _1482.x;\n        _2393.y = _1482.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2393;\n        _2328 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1511 = fa_tex_fix(param_12, param_13);\n    vec4 _2396 = mrt;\n    _2396.x = _1511.x;\n    _2396.y = _1511.y;\n    _2396.z = _1511.z;\n    mrt = _2396;\n    vec4 _1539 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1539.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1551 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1581 = fa_tex_fix(param_20, param_21);\n    float _2333 = fa_mesh_fs_params[14].x;\n    float _2334 = fa_mesh_fs_params[14].y;\n    float _2337 = fa_mesh_fs_params[14].z;\n    float _2336 = fa_mesh_fs_params[15].w;\n    float _2339 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2333 *= _1551.y;\n            _2334 *= _1551.z;\n            _2336 *= _1539.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2337 *= mrt.x;\n            _2339 *= mrt.w;\n        }\n    }\n    return Surface(_1441.xyz, _1441.w, _2328, clamp(fa_mesh_fs_params[5].x * _1511.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1511.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1551.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1581), _2333, _2334, fa_mesh_fs_params[15].xyz, _2336, _2337, fa_mesh_fs_params[14].w, _2339, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _682 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _690 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _693 = int(_682);\n    int _696 = int(_690);\n    float _706 = _690 - float(_696);\n    int _762 = (_693 * 9) + _696;\n    int _782 = ((_693 + 1) * 9) + _696;\n    return mix(mix(_757[_762], _757[_762 + 1], _706), mix(_757[_782], _757[_782 + 1], _706), _682 - float(_693));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2200 = false;\n    float _2201 = 1.0;\n    float _2202 = 1.0;\n    float _2203 = 1.0;\n    float _2204 = 0.0;\n    float _2205 = 0.0;\n    float _2206 = 0.0;\n    float _2207 = 0.0;\n    float _2209 = 1.0;\n    bool _2210 = false;\n    vec3 _2211 = vec3(0.0);\n    float _2212 = 1.0;\n    float _2213 = 1.0;\n    float _2214 = 1.0;\n    float _2215 = 0.0;\n    float _2216 = 0.0;\n    vec3 _2217 = vec3(1.0, 0.0, 0.0);\n    vec3 _2218 = vec3(0.0, 0.0, 1.0);\n    float _2219 = 1.0;\n    float _2220 = 1.0;\n    float _844 = clamp(s.specular, 0.0, 1.0);\n    float _849 = clamp(s.ior, 1.0, 3.0);\n    bool _854 = (_844 != 1.0) || (_849 != 1.5);\n    bool _864;\n    if (!_854)\n    {\n        _864 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _864 = _854;\n    }\n    if (_864)\n    {\n        float _872 = (_849 - 1.0) / (_849 + 1.0);\n        f0 = mix(min(vec3(_872 * _872) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _844, s.albedo, vec3(metallic));\n        _2201 = mix(_844, 1.0, metallic);\n        _2200 = true;\n    }\n    float _900 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_900 > 0.0)\n    {\n        float _908 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2204 = _900;\n        _2205 = _908;\n        float _915 = _908 * _908;\n        _2206 = _915;\n        _2207 = _915 * _915;\n        float _927 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2209 = _927;\n        _2202 = 1.0 - (_900 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _927, 0.0, 1.0), 5.0))));\n        _2200 = true;\n    }\n    vec3 _947 = max(s.sheen_color, vec3(0.0));\n    float _956 = max(_947.x, max(_947.y, _947.z));\n    if (_956 > 0.0)\n    {\n        float _964 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2210 = true;\n        _2211 = _947;\n        _2212 = _964;\n        _2213 = _964 * _964;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _964;\n        float _981 = fa_sheen_albedo(param, param_1);\n        _2215 = _981;\n        _2214 = 1.0 - min(_956 * _981, 1.0);\n        _2200 = true;\n    }\n    _2203 = _2202 * _2214;\n    float _1000 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1000 != 0.0)\n    {\n        vec3 _1015 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1015;\n        if (dot(_1015, _1015) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1029 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1029.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1029.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1029.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1033 = t;\n        vec3 _1034 = normalize(_1033);\n        t = _1034;\n        vec3 _1059 = normalize((_1034 * cos(s.anisotropy_rotation)) + ((cross(n, _1034) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2217 = _1059;\n        _2218 = cross(n, _1059);\n        float _1069 = roughness * roughness;\n        float _1075 = mix(_1069, 1.0, _1000 * _1000);\n        bool _1077 = _1000 > 0.0;\n        _2219 = _1077 ? _1075 : _1069;\n        _2220 = _1077 ? _1069 : _1075;\n        _2216 = _1000;\n        _2200 = true;\n    }\n    return FaLayers(_2200, _2201, _2202, _2203, _2204, _2205, _2206, _2207, i.world_normal, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _612 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _615 = _612.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_615 * _615, exp2((-9.27999973297119140625) * ndv)) * _615) + _612.y)) + _612.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _515 = rough * rough;\n    float _546 = 0.60000002384185791015625 * _515;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _515)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _546, 0.0500000007450580596923828125 + _546, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_515 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1110;\n        if (L.aniso >= 0.0)\n        {\n            _1110 = L.b;\n        }\n        else\n        {\n            _1110 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1110, v), _1110), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1143 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1143.x) + (vec3(L.f90) * _1143.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1198 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1198.x) + _1198.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _654 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _654.x) + vec3(_654.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _1227 = clamp(s.metallic, 0.0, 1.0);\n    float _1231 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _1238 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_1227));\n    vec3 f0 = _1238;\n    vec3 _1242 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _1242;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _1227;\n    float param_5 = _1231;\n    vec3 param_6 = _1238;\n    FaLayers _1259 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1259.on)\n    {\n        FaLayers param_7 = _1259;\n        vec3 param_8 = _1242;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _1231;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _1242;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _1231;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _225 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_225)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _243 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _245 = length(_243);\n        dist = _245;\n        l = _243 / vec3(max(_245, 9.9999997473787516355514526367188e-05));\n        float _261 = _245 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _267 = clamp(1.0 - (_261 * _261), 0.0, 1.0);\n        atten = _267 * _267;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _317;\n    if (_225)\n    {\n        _317 = 0;\n    }\n    else\n    {\n        _317 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _317);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _344 = coord.xyz / vec3(coord.w);\n    vec3 p = _344;\n    vec2 suv = (_344.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2360 = p;\n        _2360.z = (_2360.z * 0.5) + 0.5;\n        p = _2360;\n    }\n    else\n    {\n        vec2 _2363 = suv;\n        _2363.y = 1.0 - _2363.y;\n        suv = _2363;\n    }\n    bool _372 = suv.x < 0.0;\n    bool _379;\n    if (!_372)\n    {\n        _379 = suv.x > 1.0;\n    }\n    else\n    {\n        _379 = _372;\n    }\n    bool _386;\n    if (!_379)\n    {\n        _386 = suv.y < 0.0;\n    }\n    else\n    {\n        _386 = _379;\n    }\n    bool _393;\n    if (!_386)\n    {\n        _393 = suv.y > 1.0;\n    }\n    else\n    {\n        _393 = _386;\n    }\n    bool _400;\n    if (!_393)\n    {\n        _400 = p.z > 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    if (_400)\n    {\n        return 1.0;\n    }\n    float _415 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _415) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1301 = fa_light_sample(param, param_1);\n    vec3 _2313 = _1301.direction;\n    vec3 _2308 = _1301.color;\n    float _2315 = _1301.attenuation;\n    float _2310 = _1301.shadow;\n    int _2318 = _1301.type;\n    if ((_2318 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2313;\n        float _1315 = fa_shadow_factor(param_2, param_3);\n        _2310 = _1315;\n        _2308 = fa_lights[li * 1 + 32].xyz * (_2315 * _1315);\n    }\n    return LightSample(_2313, _2308, _2315, _2310, _1301._distance, _2318);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2030 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2030 = -_2030;\n    }\n    vec3 _1701 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2030, fa_world_tangent, fa_uv, fa_vertex_color, _1701, gl_FrontFacing);\n    Surface _1706 = fa_standard_surface(param);\n    vec3 _2069 = _1706.albedo;\n    float _2070 = _1706.alpha;\n    vec3 _2071 = _1706.normal;\n    float _2072 = _1706.metallic;\n    float _2073 = _1706.roughness;\n    float _2074 = _1706.occlusion;\n    vec3 _2075 = _1706.emission;\n    float _2076 = _1706.clearcoat;\n    float _2077 = _1706.clearcoat_roughness;\n    vec3 _2078 = _1706.sheen_color;\n    float _2079 = _1706.sheen_roughness;\n    float _2080 = _1706.anisotropy;\n    float _2081 = _1706.anisotropy_rotation;\n    float _2082 = _1706.specular;\n    float _2083 = _1706.ior;\n    vec3 _2084 = _1706.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2030, fa_world_tangent, fa_uv, fa_vertex_color, _1701, gl_FrontFacing);\n    Surface param_2 = _1706;\n    surface(param_1, param_2);\n    _2069 = param_2.albedo;\n    _2070 = param_2.alpha;\n    _2071 = param_2.normal;\n    _2072 = param_2.metallic;\n    _2073 = param_2.roughness;\n    _2074 = param_2.occlusion;\n    _2075 = param_2.emission;\n    _2076 = param_2.clearcoat;\n    _2077 = param_2.clearcoat_roughness;\n    _2078 = param_2.sheen_color;\n    _2079 = param_2.sheen_roughness;\n    _2080 = param_2.anisotropy;\n    _2081 = param_2.anisotropy_rotation;\n    _2082 = param_2.specular;\n    _2083 = param_2.ior;\n    _2084 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2069;\n    }\n    else\n    {\n        vec3 _1727 = _2071;\n        vec3 _1728 = normalize(_1727);\n        _2071 = _1728;\n        vec3 param_3 = _1728;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _2030, fa_world_tangent, fa_uv, fa_vertex_color, _1701, gl_FrontFacing);\n        Surface param_5 = Surface(_2069, _2070, _2071, _2072, _2073, _2074, _2075, _2076, _2077, _2078, _2079, _2080, _2081, _2082, _2083, _2084);\n        vec3 param_6 = fa_ambient_light(param_3);\n        vec3 lit = ambient(param_4, param_5, param_6);\n        int _1747 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1747)\n            {\n                break;\n            }\n            int param_7 = li;\n            vec3 param_8 = fa_world_pos;\n            vec3 param_9 = _2030;\n            SurfaceInput param_10 = SurfaceInput(fa_world_pos, _2030, fa_world_tangent, fa_uv, fa_vertex_color, _1701, gl_FrontFacing);\n            Surface param_11 = Surface(_2069, _2070, _2071, _2072, _2073, _2074, _2075, _2076, _2077, _2078, _2079, _2080, _2081, _2082, _2083, _2084);\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9);\n            lit += light(param_10, param_11, param_12);\n        }\n        result = lit;\n    }\n    result += _2075;\n    bool _1790 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1797;\n    if (!_1790)\n    {\n        _1797 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1797 = _1790;\n    }\n    if (_1797)\n    {\n        vec3 _1806 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1812 = dot(_1806, fa_mesh_fs_params[9].xyz);\n        bool _1816 = fa_mesh_fs_params[9].w > 0.5;\n        float _1817;\n        if (_1816)\n        {\n            _1817 = _1812;\n        }\n        else\n        {\n            _1817 = length(_1806);\n        }\n        float _1829 = _1817 - fa_mesh_fs_params[8].x;\n        if (_1829 > 0.0)\n        {\n            float _1838 = fa_mesh_fs_params[7].w * _1829;\n            float tau = _1838 * _1838;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1854;\n                if (_1816)\n                {\n                    _1854 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1812);\n                }\n                else\n                {\n                    _1854 = fa_mesh_fs_params[0].y;\n                }\n                float _1875 = mix(_1854, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1817, 0.0, 1.0));\n                float _1879 = fa_world_pos.y - _1875;\n                float _1884 = _1875 - fa_mesh_fs_params[8].z;\n                float _1889 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1892 = _1884 <= 0.0;\n                bool _1893 = !_1892;\n                bool _1899;\n                if (_1893)\n                {\n                    _1899 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1899 = _1892;\n                }\n                float _1900;\n                if (_1899)\n                {\n                    _1900 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1900 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1884, 80.0));\n                }\n                bool _1927;\n                if (_1893)\n                {\n                    _1927 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1927 = _1892;\n                }\n                float _1928;\n                if (_1927)\n                {\n                    _1928 = fa_mesh_fs_params[8].y * _1884;\n                }\n                else\n                {\n                    _1928 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1884, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1953 = _1889 <= 0.0;\n                bool _1960;\n                if (!_1953)\n                {\n                    _1960 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1960 = _1953;\n                }\n                float _1961;\n                if (_1960)\n                {\n                    _1961 = fa_mesh_fs_params[8].y * _1889;\n                }\n                else\n                {\n                    _1961 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1889, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1988;\n                if (abs(_1879) < 0.001000000047497451305389404296875)\n                {\n                    _1988 = _1900;\n                }\n                else\n                {\n                    _1988 = (_1961 - _1928) / _1879;\n                }\n                tau += (_1829 * max(_1988, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2070);\n}\n\n",
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
            "inst_name": "_131",
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
            "inst_name": "_214",
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
            "inst_name": "_331",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    vec4 _280 = vec4(_391, 1.0);\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _280;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _280;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _757[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 6) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1387 = fa_linear_to_srgb(param);\n        c = _1387;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1395 = fa_srgb_to_linear(param_1);\n            c = _1395;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _142;\n    if (i.front_facing)\n    {\n        _142 = i.world_normal;\n    }\n    else\n    {\n        _142 = -i.world_normal;\n    }\n    vec3 _166 = normalize(i.world_tangent.xyz - (_142 * dot(_142, i.world_tangent.xyz)));\n    vec3 _194 = normalize(((_166 * m.x) + ((cross(_142, _166) * i.world_tangent.w) * m.y)) + (_142 * m.z));\n    vec3 _197;\n    if (i.front_facing)\n    {\n        _197 = _194;\n    }\n    else\n    {\n        _197 = -_194;\n    }\n    return _197;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1427 = fa_tex_fix(param_2, param_3);\n    vec4 _2385 = base_t;\n    _2385.x = _1427.x;\n    _2385.y = _1427.y;\n    _2385.z = _1427.z;\n    base_t = _2385;\n    vec4 _1441 = (_2385 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2328 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1474 = fa_tex_fix(param_6, param_7);\n        vec3 _1477 = (_1474 * 2.0) - vec3(1.0);\n        vec2 _1482 = _1477.xy * fa_mesh_fs_params[6].x;\n        vec3 _2393 = _1477;\n        _2393.x = _1482.x;\n        _2393.y = _1482.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2393;\n        _2328 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1511 = fa_tex_fix(param_12, param_13);\n    vec4 _2396 = mrt;\n    _2396.x = _1511.x;\n    _2396.y = _1511.y;\n    _2396.z = _1511.z;\n    mrt = _2396;\n    vec4 _1539 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1539.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1551 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1581 = fa_tex_fix(param_20, param_21);\n    float _2333 = fa_mesh_fs_params[14].x;\n    float _2334 = fa_mesh_fs_params[14].y;\n    float _2337 = fa_mesh_fs_params[14].z;\n    float _2336 = fa_mesh_fs_params[15].w;\n    float _2339 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2333 *= _1551.y;\n            _2334 *= _1551.z;\n            _2336 *= _1539.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2337 *= mrt.x;\n            _2339 *= mrt.w;\n        }\n    }\n    return Surface(_1441.xyz, _1441.w, _2328, clamp(fa_mesh_fs_params[5].x * _1511.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1511.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1551.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1581), _2333, _2334, fa_mesh_fs_params[15].xyz, _2336, _2337, fa_mesh_fs_params[14].w, _2339, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _682 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _690 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _693 = int(_682);\n    int _696 = int(_690);\n    float _706 = _690 - float(_696);\n    int _762 = (_693 * 9) + _696;\n    int _782 = ((_693 + 1) * 9) + _696;\n    return mix(mix(_757[_762], _757[_762 + 1], _706), mix(_757[_782], _757[_782 + 1], _706), _682 - float(_693));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2200 = false;\n    float _2201 = 1.0;\n    float _2202 = 1.0;\n    float _2203 = 1.0;\n    float _2204 = 0.0;\n    float _2205 = 0.0;\n    float _2206 = 0.0;\n    float _2207 = 0.0;\n    float _2209 = 1.0;\n    bool _2210 = false;\n    vec3 _2211 = vec3(0.0);\n    float _2212 = 1.0;\n    float _2213 = 1.0;\n    float _2214 = 1.0;\n    float _2215 = 0.0;\n    float _2216 = 0.0;\n    vec3 _2217 = vec3(1.0, 0.0, 0.0);\n    vec3 _2218 = vec3(0.0, 0.0, 1.0);\n    float _2219 = 1.0;\n    float _2220 = 1.0;\n    float _844 = clamp(s.specular, 0.0, 1.0);\n    float _849 = clamp(s.ior, 1.0, 3.0);\n    bool _854 = (_844 != 1.0) || (_849 != 1.5);\n    bool _864;\n    if (!_854)\n    {\n        _864 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _864 = _854;\n    }\n    if (_864)\n    {\n        float _872 = (_849 - 1.0) / (_849 + 1.0);\n        f0 = mix(min(vec3(_872 * _872) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _844, s.albedo, vec3(metallic));\n        _2201 = mix(_844, 1.0, metallic);\n        _2200 = true;\n    }\n    float _900 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_900 > 0.0)\n    {\n        float _908 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2204 = _900;\n        _2205 = _908;\n        float _915 = _908 * _908;\n        _2206 = _915;\n        _2207 = _915 * _915;\n        float _927 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2209 = _927;\n        _2202 = 1.0 - (_900 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _927, 0.0, 1.0), 5.0))));\n        _2200 = true;\n    }\n    vec3 _947 = max(s.sheen_color, vec3(0.0));\n    float _956 = max(_947.x, max(_947.y, _947.z));\n    if (_956 > 0.0)\n    {\n        float _964 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2210 = true;\n        _2211 = _947;\n        _2212 = _964;\n        _2213 = _964 * _964;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _964;\n        float _981 = fa_sheen_albedo(param, param_1);\n        _2215 = _981;\n        _2214 = 1.0 - min(_956 * _981, 1.0);\n        _2200 = true;\n    }\n    _2203 = _2202 * _2214;\n    float _1000 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1000 != 0.0)\n    {\n        vec3 _1015 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1015;\n        if (dot(_1015, _1015) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1029 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1029.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1029.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1029.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1033 = t;\n        vec3 _1034 = normalize(_1033);\n        t = _1034;\n        vec3 _1059 = normalize((_1034 * cos(s.anisotropy_rotation)) + ((cross(n, _1034) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2217 = _1059;\n        _2218 = cross(n, _1059);\n        float _1069 = roughness * roughness;\n        float _1075 = mix(_1069, 1.0, _1000 * _1000);\n        bool _1077 = _1000 > 0.0;\n        _2219 = _1077 ? _1075 : _1069;\n        _2220 = _1077 ? _1069 : _1075;\n        _2216 = _1000;\n        _2200 = true;\n    }\n    return FaLayers(_2200, _2201, _2202, _2203, _2204, _2205, _2206, _2207, i.world_normal, _2209, _2210, _2211, _2212, _2213, _2214, _2215, _2216, _2217, _2218, _2219, _2220);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _612 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _615 = _612.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_615 * _615, exp2((-9.27999973297119140625) * ndv)) * _615) + _612.y)) + _612.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _515 = rough * rough;\n    float _546 = 0.60000002384185791015625 * _515;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _515)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _546, 0.0500000007450580596923828125 + _546, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_515 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1110;\n        if (L.aniso >= 0.0)\n        {\n            _1110 = L.b;\n        }\n        else\n        {\n            _1110 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1110, v), _1110), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1143 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1143.x) + (vec3(L.f90) * _1143.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1198 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1198.x) + _1198.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _654 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _654.x) + vec3(_654.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _1227 = clamp(s.metallic, 0.0, 1.0);\n    float _1231 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _1238 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_1227));\n    vec3 f0 = _1238;\n    vec3 _1242 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _1242;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _1227;\n    float param_5 = _1231;\n    vec3 param_6 = _1238;\n    FaLayers _1259 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1259.on)\n    {\n        FaLayers param_7 = _1259;\n        vec3 param_8 = _1242;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _1231;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _1242;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _1231;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _225 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_225)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _243 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _245 = length(_243);\n        dist = _245;\n        l = _243 / vec3(max(_245, 9.9999997473787516355514526367188e-05));\n        float _261 = _245 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _267 = clamp(1.0 - (_261 * _261), 0.0, 1.0);\n        atten = _267 * _267;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _317;\n    if (_225)\n    {\n        _317 = 0;\n    }\n    else\n    {\n        _317 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _317);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _344 = coord.xyz / vec3(coord.w);\n    vec3 p = _344;\n    vec2 suv = (_344.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2360 = p;\n        _2360.z = (_2360.z * 0.5) + 0.5;\n        p = _2360;\n    }\n    else\n    {\n        vec2 _2363 = suv;\n        _2363.y = 1.0 - _2363.y;\n        suv = _2363;\n    }\n    bool _372 = suv.x < 0.0;\n    bool _379;\n    if (!_372)\n    {\n        _379 = suv.x > 1.0;\n    }\n    else\n    {\n        _379 = _372;\n    }\n    bool _386;\n    if (!_379)\n    {\n        _386 = suv.y < 0.0;\n    }\n    else\n    {\n        _386 = _379;\n    }\n    bool _393;\n    if (!_386)\n    {\n        _393 = suv.y > 1.0;\n    }\n    else\n    {\n        _393 = _386;\n    }\n    bool _400;\n    if (!_393)\n    {\n        _400 = p.z > 1.0;\n    }\n    else\n    {\n        _400 = _393;\n    }\n    if (_400)\n    {\n        return 1.0;\n    }\n    float _415 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _415) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1301 = fa_light_sample(param, param_1);\n    vec3 _2313 = _1301.direction;\n    vec3 _2308 = _1301.color;\n    float _2315 = _1301.attenuation;\n    float _2310 = _1301.shadow;\n    int _2318 = _1301.type;\n    if ((_2318 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2313;\n        float _1315 = fa_shadow_factor(param_2, param_3);\n        _2310 = _1315;\n        _2308 = fa_lights[li * 1 + 32].xyz * (_2315 * _1315);\n    }\n    return LightSample(_2313, _2308, _2315, _2310, _1301._distance, _2318);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2030 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2030 = -_2030;\n    }\n    vec3 _1701 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2030, fa_world_tangent, fa_uv, fa_vertex_color, _1701, gl_FrontFacing);\n    Surface _1706 = fa_standard_surface(param);\n    vec3 _2069 = _1706.albedo;\n    float _2070 = _1706.alpha;\n    vec3 _2071 = _1706.normal;\n    float _2072 = _1706.metallic;\n    float _2073 = _1706.roughness;\n    float _2074 = _1706.occlusion;\n    vec3 _2075 = _1706.emission;\n    float _2076 = _1706.clearcoat;\n    float _2077 = _1706.clearcoat_roughness;\n    vec3 _2078 = _1706.sheen_color;\n    float _2079 = _1706.sheen_roughness;\n    float _2080 = _1706.anisotropy;\n    float _2081 = _1706.anisotropy_rotation;\n    float _2082 = _1706.specular;\n    float _2083 = _1706.ior;\n    vec3 _2084 = _1706.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2030, fa_world_tangent, fa_uv, fa_vertex_color, _1701, gl_FrontFacing);\n    Surface param_2 = _1706;\n    surface(param_1, param_2);\n    _2069 = param_2.albedo;\n    _2070 = param_2.alpha;\n    _2071 = param_2.normal;\n    _2072 = param_2.metallic;\n    _2073 = param_2.roughness;\n    _2074 = param_2.occlusion;\n    _2075 = param_2.emission;\n    _2076 = param_2.clearcoat;\n    _2077 = param_2.clearcoat_roughness;\n    _2078 = param_2.sheen_color;\n    _2079 = param_2.sheen_roughness;\n    _2080 = param_2.anisotropy;\n    _2081 = param_2.anisotropy_rotation;\n    _2082 = param_2.specular;\n    _2083 = param_2.ior;\n    _2084 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2069;\n    }\n    else\n    {\n        vec3 _1727 = _2071;\n        vec3 _1728 = normalize(_1727);\n        _2071 = _1728;\n        vec3 param_3 = _1728;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _2030, fa_world_tangent, fa_uv, fa_vertex_color, _1701, gl_FrontFacing);\n        Surface param_5 = Surface(_2069, _2070, _2071, _2072, _2073, _2074, _2075, _2076, _2077, _2078, _2079, _2080, _2081, _2082, _2083, _2084);\n        vec3 param_6 = fa_ambient_light(param_3);\n        vec3 lit = ambient(param_4, param_5, param_6);\n        int _1747 = int(fa_mesh_fs_params[10].x);\n        for (int li = 0; li < 32; li++)\n        {\n            if (li >= _1747)\n            {\n                break;\n            }\n            int param_7 = li;\n            vec3 param_8 = fa_world_pos;\n            vec3 param_9 = _2030;\n            SurfaceInput param_10 = SurfaceInput(fa_world_pos, _2030, fa_world_tangent, fa_uv, fa_vertex_color, _1701, gl_FrontFacing);\n            Surface param_11 = Surface(_2069, _2070, _2071, _2072, _2073, _2074, _2075, _2076, _2077, _2078, _2079, _2080, _2081, _2082, _2083, _2084);\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9);\n            lit += light(param_10, param_11, param_12);\n        }\n        result = lit;\n    }\n    result += _2075;\n    bool _1790 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1797;\n    if (!_1790)\n    {\n        _1797 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1797 = _1790;\n    }\n    if (_1797)\n    {\n        vec3 _1806 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1812 = dot(_1806, fa_mesh_fs_params[9].xyz);\n        bool _1816 = fa_mesh_fs_params[9].w > 0.5;\n        float _1817;\n        if (_1816)\n        {\n            _1817 = _1812;\n        }\n        else\n        {\n            _1817 = length(_1806);\n        }\n        float _1829 = _1817 - fa_mesh_fs_params[8].x;\n        if (_1829 > 0.0)\n        {\n            float _1838 = fa_mesh_fs_params[7].w * _1829;\n            float tau = _1838 * _1838;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1854;\n                if (_1816)\n                {\n                    _1854 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1812);\n                }\n                else\n                {\n                    _1854 = fa_mesh_fs_params[0].y;\n                }\n                float _1875 = mix(_1854, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1817, 0.0, 1.0));\n                float _1879 = fa_world_pos.y - _1875;\n                float _1884 = _1875 - fa_mesh_fs_params[8].z;\n                float _1889 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1892 = _1884 <= 0.0;\n                bool _1893 = !_1892;\n                bool _1899;\n                if (_1893)\n                {\n                    _1899 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1899 = _1892;\n                }\n                float _1900;\n                if (_1899)\n                {\n                    _1900 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1900 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1884, 80.0));\n                }\n                bool _1927;\n                if (_1893)\n                {\n                    _1927 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1927 = _1892;\n                }\n                float _1928;\n                if (_1927)\n                {\n                    _1928 = fa_mesh_fs_params[8].y * _1884;\n                }\n                else\n                {\n                    _1928 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1884, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1953 = _1889 <= 0.0;\n                bool _1960;\n                if (!_1953)\n                {\n                    _1960 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1960 = _1953;\n                }\n                float _1961;\n                if (_1960)\n                {\n                    _1961 = fa_mesh_fs_params[8].y * _1889;\n                }\n                else\n                {\n                    _1961 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1889, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1988;\n                if (abs(_1879) < 0.001000000047497451305389404296875)\n                {\n                    _1988 = _1900;\n                }\n                else\n                {\n                    _1988 = (_1961 - _1928) / _1879;\n                }\n                tau += (_1829 * max(_1988, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2070);\n}\n\n",
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
            "inst_name": "_136",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_214",
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
            "inst_name": "_331",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _780 = base_t;\n    _780.x = _225.x;\n    _780.y = _225.y;\n    _780.z = _225.z;\n    base_t = _780;\n    vec4 _241 = (_780 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _743 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _788 = _279;\n        _788.x = _284.x;\n        _788.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _788;\n        _743 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _791 = mrt;\n    _791.x = _313.x;\n    _791.y = _313.y;\n    _791.z = _313.z;\n    mrt = _791;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _748 = fa_mesh_fs_params[14].x;\n    float _749 = fa_mesh_fs_params[14].y;\n    float _752 = fa_mesh_fs_params[14].z;\n    float _751 = fa_mesh_fs_params[15].w;\n    float _754 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _748 *= _355.y;\n            _749 *= _355.z;\n            _751 *= _343.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _752 *= mrt.x;\n            _754 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _743, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _748, _749, fa_mesh_fs_params[15].xyz, _751, _752, fa_mesh_fs_params[14].w, _754, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _654 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _654 = -_654;\n    }\n    vec3 _517 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _654, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _654, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _532 = normalize(param_2.normal);\n    vec3 _547 = normalize(vec3(dot(fa_pre_r0, _532), dot(fa_pre_r1, _532), dot(fa_pre_r2, _532)));\n    float _559 = _547.z;\n    vec2 e = _547.xy / vec2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_131",
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
            "inst_name": "_213",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _780 = base_t;\n    _780.x = _225.x;\n    _780.y = _225.y;\n    _780.z = _225.z;\n    base_t = _780;\n    vec4 _241 = (_780 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _743 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _788 = _279;\n        _788.x = _284.x;\n        _788.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _788;\n        _743 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _791 = mrt;\n    _791.x = _313.x;\n    _791.y = _313.y;\n    _791.z = _313.z;\n    mrt = _791;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _748 = fa_mesh_fs_params[14].x;\n    float _749 = fa_mesh_fs_params[14].y;\n    float _752 = fa_mesh_fs_params[14].z;\n    float _751 = fa_mesh_fs_params[15].w;\n    float _754 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _748 *= _355.y;\n            _749 *= _355.z;\n            _751 *= _343.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _752 *= mrt.x;\n            _754 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _743, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _748, _749, fa_mesh_fs_params[15].xyz, _751, _752, fa_mesh_fs_params[14].w, _754, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _654 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _654 = -_654;\n    }\n    vec3 _517 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _654, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _654, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _532 = normalize(param_2.normal);\n    vec3 _547 = normalize(vec3(dot(fa_pre_r0, _532), dot(fa_pre_r1, _532), dot(fa_pre_r2, _532)));\n    float _559 = _547.z;\n    vec2 e = _547.xy / vec2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_136",
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
            "size": 288,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_213",
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
    }
  }
}
