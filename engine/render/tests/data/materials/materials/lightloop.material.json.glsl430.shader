{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "67b1186c6e51021b07dd68cec7aaad42a4febc7364ef358b4473bc1e089911c0",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _273 = _160.world_pos;\n    vec4 _167 = vec4(_273, 1.0);\n    fa_world_pos = _273;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _167;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _167;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _743[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 6) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1518 = fa_linear_to_srgb(param);\n        c = _1518;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1526 = fa_srgb_to_linear(param_1);\n            c = _1526;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _145;\n    if (i.front_facing)\n    {\n        _145 = i.world_normal;\n    }\n    else\n    {\n        _145 = -i.world_normal;\n    }\n    vec3 _169 = normalize(i.world_tangent.xyz - (_145 * dot(_145, i.world_tangent.xyz)));\n    vec3 _197 = normalize(((_169 * m.x) + ((cross(_145, _169) * i.world_tangent.w) * m.y)) + (_145 * m.z));\n    vec3 _200;\n    if (i.front_facing)\n    {\n        _200 = _197;\n    }\n    else\n    {\n        _200 = -_197;\n    }\n    return _200;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1558 = fa_tex_fix(param_2, param_3);\n    vec4 _2452 = base_t;\n    _2452.x = _1558.x;\n    _2452.y = _1558.y;\n    _2452.z = _1558.z;\n    base_t = _2452;\n    vec4 _1572 = (_2452 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2395 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1605 = fa_tex_fix(param_6, param_7);\n        vec3 _1608 = (_1605 * 2.0) - vec3(1.0);\n        vec2 _1613 = _1608.xy * fa_mesh_fs_params[6].x;\n        vec3 _2460 = _1608;\n        _2460.x = _1613.x;\n        _2460.y = _1613.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2460;\n        _2395 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1642 = fa_tex_fix(param_12, param_13);\n    vec4 _2463 = mrt;\n    _2463.x = _1642.x;\n    _2463.y = _1642.y;\n    _2463.z = _1642.z;\n    mrt = _2463;\n    vec4 _1670 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1670.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1682 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1712 = fa_tex_fix(param_20, param_21);\n    float _2400 = fa_mesh_fs_params[14].x;\n    float _2401 = fa_mesh_fs_params[14].y;\n    float _2404 = fa_mesh_fs_params[14].z;\n    float _2403 = fa_mesh_fs_params[15].w;\n    float _2406 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2400 *= _1682.y;\n            _2401 *= _1682.z;\n            _2403 *= _1670.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2404 *= mrt.x;\n            _2406 *= mrt.w;\n        }\n    }\n    return Surface(_1572.xyz, _1572.w, _2395, clamp(fa_mesh_fs_params[5].x * _1642.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1642.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1682.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1712), _2400, _2401, fa_mesh_fs_params[15].xyz, _2403, _2404, fa_mesh_fs_params[14].w, _2406, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _228 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_228)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _246 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _248 = length(_246);\n        dist = _248;\n        l = _246 / vec3(max(_248, 9.9999997473787516355514526367188e-05));\n        float _264 = _248 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _270 = clamp(1.0 - (_264 * _264), 0.0, 1.0);\n        atten = _270 * _270;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _321;\n    if (_228)\n    {\n        _321 = 0;\n    }\n    else\n    {\n        _321 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _321);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1359 = n < 0;\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = n >= fa_light_count();\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    if (_1366)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    vec3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _348 = coord.xyz / vec3(coord.w);\n    vec3 p = _348;\n    vec2 suv = (_348.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2427 = p;\n        _2427.z = (_2427.z * 0.5) + 0.5;\n        p = _2427;\n    }\n    else\n    {\n        vec2 _2430 = suv;\n        _2430.y = 1.0 - _2430.y;\n        suv = _2430;\n    }\n    bool _376 = suv.x < 0.0;\n    bool _383;\n    if (!_376)\n    {\n        _383 = suv.x > 1.0;\n    }\n    else\n    {\n        _383 = _376;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = suv.y < 0.0;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = suv.y > 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _404;\n    if (!_397)\n    {\n        _404 = p.z > 1.0;\n    }\n    else\n    {\n        _404 = _397;\n    }\n    if (_404)\n    {\n        return 1.0;\n    }\n    float _419 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _419) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1297 = fa_light_sample(param, param_1);\n    vec3 _2371 = _1297.direction;\n    vec3 _2366 = _1297.color;\n    float _2373 = _1297.attenuation;\n    float _2368 = _1297.shadow;\n    int _2376 = _1297.type;\n    if ((_2376 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2371;\n        float _1311 = fa_shadow_factor(param_2, param_3);\n        _2368 = _1311;\n        _2366 = fa_lights[li * 1 + 32].xyz * (_2373 * _1311);\n    }\n    return LightSample(_2371, _2366, _2373, _2368, _1297._distance, _2376);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1335 = n < 0;\n    bool _1342;\n    if (!_1335)\n    {\n        _1342 = n >= fa_light_count();\n    }\n    else\n    {\n        _1342 = _1335;\n    }\n    if (_1342)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    vec3 param_1 = i.world_pos;\n    vec3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _668 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _676 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _679 = int(_668);\n    int _682 = int(_676);\n    float _692 = _676 - float(_682);\n    int _748 = (_679 * 9) + _682;\n    int _768 = ((_679 + 1) * 9) + _682;\n    return mix(mix(_743[_748], _743[_748 + 1], _692), mix(_743[_768], _743[_768 + 1], _692), _668 - float(_679));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2245 = false;\n    float _2246 = 1.0;\n    float _2247 = 1.0;\n    float _2248 = 1.0;\n    float _2249 = 0.0;\n    float _2250 = 0.0;\n    float _2251 = 0.0;\n    float _2252 = 0.0;\n    float _2254 = 1.0;\n    bool _2255 = false;\n    vec3 _2256 = vec3(0.0);\n    float _2257 = 1.0;\n    float _2258 = 1.0;\n    float _2259 = 1.0;\n    float _2260 = 0.0;\n    float _2261 = 0.0;\n    vec3 _2262 = vec3(1.0, 0.0, 0.0);\n    vec3 _2263 = vec3(0.0, 0.0, 1.0);\n    float _2264 = 1.0;\n    float _2265 = 1.0;\n    float _830 = clamp(s.specular, 0.0, 1.0);\n    float _835 = clamp(s.ior, 1.0, 3.0);\n    bool _840 = (_830 != 1.0) || (_835 != 1.5);\n    bool _850;\n    if (!_840)\n    {\n        _850 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _850 = _840;\n    }\n    if (_850)\n    {\n        float _858 = (_835 - 1.0) / (_835 + 1.0);\n        f0 = mix(min(vec3(_858 * _858) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _830, s.albedo, vec3(metallic));\n        _2246 = mix(_830, 1.0, metallic);\n        _2245 = true;\n    }\n    float _886 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_886 > 0.0)\n    {\n        float _894 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2249 = _886;\n        _2250 = _894;\n        float _901 = _894 * _894;\n        _2251 = _901;\n        _2252 = _901 * _901;\n        float _913 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2254 = _913;\n        _2247 = 1.0 - (_886 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _913, 0.0, 1.0), 5.0))));\n        _2245 = true;\n    }\n    vec3 _933 = max(s.sheen_color, vec3(0.0));\n    float _942 = max(_933.x, max(_933.y, _933.z));\n    if (_942 > 0.0)\n    {\n        float _950 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2255 = true;\n        _2256 = _933;\n        _2257 = _950;\n        _2258 = _950 * _950;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _950;\n        float _967 = fa_sheen_albedo(param, param_1);\n        _2260 = _967;\n        _2259 = 1.0 - min(_942 * _967, 1.0);\n        _2245 = true;\n    }\n    _2248 = _2247 * _2259;\n    float _986 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_986 != 0.0)\n    {\n        vec3 _1001 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1001;\n        if (dot(_1001, _1001) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1015 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1015.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1015.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1015.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1019 = t;\n        vec3 _1020 = normalize(_1019);\n        t = _1020;\n        vec3 _1045 = normalize((_1020 * cos(s.anisotropy_rotation)) + ((cross(n, _1020) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2262 = _1045;\n        _2263 = cross(n, _1045);\n        float _1055 = roughness * roughness;\n        float _1061 = mix(_1055, 1.0, _986 * _986);\n        bool _1063 = _986 > 0.0;\n        _2264 = _1063 ? _1061 : _1055;\n        _2265 = _1063 ? _1055 : _1061;\n        _2261 = _986;\n        _2245 = true;\n    }\n    return FaLayers(_2245, _2246, _2247, _2248, _2249, _2250, _2251, _2252, i.world_normal, _2254, _2255, _2256, _2257, _2258, _2259, _2260, _2261, _2262, _2263, _2264, _2265);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _598 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _601 = _598.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_601 * _601, exp2((-9.27999973297119140625) * ndv)) * _601) + _598.y)) + _598.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _519 = rough * rough;\n    float _550 = 0.60000002384185791015625 * _519;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _519)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _550, 0.0500000007450580596923828125 + _550, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_519 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1096;\n        if (L.aniso >= 0.0)\n        {\n            _1096 = L.b;\n        }\n        else\n        {\n            _1096 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1096, v), _1096), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1129 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1129.x) + (vec3(L.f90) * _1129.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1184 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1184.x) + _1184.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _640 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _640.x) + vec3(_640.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _1223 = clamp(s.metallic, 0.0, 1.0);\n    float _1227 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _1234 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_1223));\n    vec3 f0 = _1234;\n    vec3 _1238 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _1238;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _1223;\n    float param_5 = _1227;\n    vec3 param_6 = _1234;\n    FaLayers _1255 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1255.on)\n    {\n        FaLayers param_7 = _1255;\n        vec3 param_8 = _1238;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _1227;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _1238;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _1227;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1403 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1403 > bestPower)\n        {\n            bestPower = _1403;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1432 = fa_light(param_2, param_3);\n        float _1440;\n        if (dot(s.normal, _1432.direction) > 0.5)\n        {\n            _1440 = 1.0;\n        }\n        else\n        {\n            _1440 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _1432.color) * _1440);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2119 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2119 = -_2119;\n    }\n    vec3 _1832 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2119, fa_world_tangent, fa_uv, fa_vertex_color, _1832, gl_FrontFacing);\n    Surface _1837 = fa_standard_surface(param);\n    vec3 _2150 = _1837.albedo;\n    float _2151 = _1837.alpha;\n    vec3 _2152 = _1837.normal;\n    float _2153 = _1837.metallic;\n    float _2154 = _1837.roughness;\n    float _2155 = _1837.occlusion;\n    vec3 _2156 = _1837.emission;\n    float _2157 = _1837.clearcoat;\n    float _2158 = _1837.clearcoat_roughness;\n    vec3 _2159 = _1837.sheen_color;\n    float _2160 = _1837.sheen_roughness;\n    float _2161 = _1837.anisotropy;\n    float _2162 = _1837.anisotropy_rotation;\n    float _2163 = _1837.specular;\n    float _2164 = _1837.ior;\n    vec3 _2165 = _1837.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2119, fa_world_tangent, fa_uv, fa_vertex_color, _1832, gl_FrontFacing);\n    Surface param_2 = _1837;\n    surface(param_1, param_2);\n    _2150 = param_2.albedo;\n    _2151 = param_2.alpha;\n    _2152 = param_2.normal;\n    _2153 = param_2.metallic;\n    _2154 = param_2.roughness;\n    _2155 = param_2.occlusion;\n    _2156 = param_2.emission;\n    _2157 = param_2.clearcoat;\n    _2158 = param_2.clearcoat_roughness;\n    _2159 = param_2.sheen_color;\n    _2160 = param_2.sheen_roughness;\n    _2161 = param_2.anisotropy;\n    _2162 = param_2.anisotropy_rotation;\n    _2163 = param_2.specular;\n    _2164 = param_2.ior;\n    _2165 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2150;\n    }\n    else\n    {\n        vec3 _1858 = _2152;\n        vec3 _1859 = normalize(_1858);\n        _2152 = _1859;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _2119, fa_world_tangent, fa_uv, fa_vertex_color, _1832, gl_FrontFacing);\n        Surface param_4 = Surface(_2150, _2151, _1859, _2153, _2154, _2155, _2156, _2157, _2158, _2159, _2160, _2161, _2162, _2163, _2164, _2165);\n        result = lighting(param_3, param_4);\n    }\n    result += _2156;\n    bool _1878 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1885;\n    if (!_1878)\n    {\n        _1885 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1885 = _1878;\n    }\n    if (_1885)\n    {\n        vec3 _1894 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1900 = dot(_1894, fa_mesh_fs_params[9].xyz);\n        bool _1904 = fa_mesh_fs_params[9].w > 0.5;\n        float _1905;\n        if (_1904)\n        {\n            _1905 = _1900;\n        }\n        else\n        {\n            _1905 = length(_1894);\n        }\n        float _1917 = _1905 - fa_mesh_fs_params[8].x;\n        if (_1917 > 0.0)\n        {\n            float _1926 = fa_mesh_fs_params[7].w * _1917;\n            float tau = _1926 * _1926;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1942;\n                if (_1904)\n                {\n                    _1942 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1900);\n                }\n                else\n                {\n                    _1942 = fa_mesh_fs_params[0].y;\n                }\n                float _1963 = mix(_1942, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1905, 0.0, 1.0));\n                float _1967 = fa_world_pos.y - _1963;\n                float _1972 = _1963 - fa_mesh_fs_params[8].z;\n                float _1977 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1980 = _1972 <= 0.0;\n                bool _1981 = !_1980;\n                bool _1987;\n                if (_1981)\n                {\n                    _1987 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1987 = _1980;\n                }\n                float _1988;\n                if (_1987)\n                {\n                    _1988 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1988 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1972, 80.0));\n                }\n                bool _2015;\n                if (_1981)\n                {\n                    _2015 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2015 = _1980;\n                }\n                float _2016;\n                if (_2015)\n                {\n                    _2016 = fa_mesh_fs_params[8].y * _1972;\n                }\n                else\n                {\n                    _2016 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1972, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2041 = _1977 <= 0.0;\n                bool _2048;\n                if (!_2041)\n                {\n                    _2048 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2048 = _2041;\n                }\n                float _2049;\n                if (_2048)\n                {\n                    _2049 = fa_mesh_fs_params[8].y * _1977;\n                }\n                else\n                {\n                    _2049 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1977, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2076;\n                if (abs(_1967) < 0.001000000047497451305389404296875)\n                {\n                    _2076 = _1988;\n                }\n                else\n                {\n                    _2076 = (_2049 - _2016) / _1967;\n                }\n                tau += (_1917 * max(_2076, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2151);\n}\n\n",
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
            "inst_name": "_217",
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
            "inst_name": "_335",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1446",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out vec4 fa_shadow_pos;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _394 = _273.world_pos;\n    vec4 _280 = vec4(_394, 1.0);\n    fa_world_pos = _394;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_shadow_pos = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * _280;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _280;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _743[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_mesh_fs_params[18];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 6) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 5) in vec4 fa_shadow_pos;\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1518 = fa_linear_to_srgb(param);\n        c = _1518;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1526 = fa_srgb_to_linear(param_1);\n            c = _1526;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _145;\n    if (i.front_facing)\n    {\n        _145 = i.world_normal;\n    }\n    else\n    {\n        _145 = -i.world_normal;\n    }\n    vec3 _169 = normalize(i.world_tangent.xyz - (_145 * dot(_145, i.world_tangent.xyz)));\n    vec3 _197 = normalize(((_169 * m.x) + ((cross(_145, _169) * i.world_tangent.w) * m.y)) + (_145 * m.z));\n    vec3 _200;\n    if (i.front_facing)\n    {\n        _200 = _197;\n    }\n    else\n    {\n        _200 = -_197;\n    }\n    return _200;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1558 = fa_tex_fix(param_2, param_3);\n    vec4 _2452 = base_t;\n    _2452.x = _1558.x;\n    _2452.y = _1558.y;\n    _2452.z = _1558.z;\n    base_t = _2452;\n    vec4 _1572 = (_2452 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2395 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1605 = fa_tex_fix(param_6, param_7);\n        vec3 _1608 = (_1605 * 2.0) - vec3(1.0);\n        vec2 _1613 = _1608.xy * fa_mesh_fs_params[6].x;\n        vec3 _2460 = _1608;\n        _2460.x = _1613.x;\n        _2460.y = _1613.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2460;\n        _2395 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1642 = fa_tex_fix(param_12, param_13);\n    vec4 _2463 = mrt;\n    _2463.x = _1642.x;\n    _2463.y = _1642.y;\n    _2463.z = _1642.z;\n    mrt = _2463;\n    vec4 _1670 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1670.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1682 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1712 = fa_tex_fix(param_20, param_21);\n    float _2400 = fa_mesh_fs_params[14].x;\n    float _2401 = fa_mesh_fs_params[14].y;\n    float _2404 = fa_mesh_fs_params[14].z;\n    float _2403 = fa_mesh_fs_params[15].w;\n    float _2406 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _2400 *= _1682.y;\n            _2401 *= _1682.z;\n            _2403 *= _1670.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _2404 *= mrt.x;\n            _2406 *= mrt.w;\n        }\n    }\n    return Surface(_1572.xyz, _1572.w, _2395, clamp(fa_mesh_fs_params[5].x * _1642.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1642.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1682.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1712), _2400, _2401, fa_mesh_fs_params[15].xyz, _2403, _2404, fa_mesh_fs_params[14].w, _2406, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _228 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_228)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _246 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _248 = length(_246);\n        dist = _248;\n        l = _246 / vec3(max(_248, 9.9999997473787516355514526367188e-05));\n        float _264 = _248 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _270 = clamp(1.0 - (_264 * _264), 0.0, 1.0);\n        atten = _270 * _270;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _321;\n    if (_228)\n    {\n        _321 = 0;\n    }\n    else\n    {\n        _321 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _321);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _1359 = n < 0;\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = n >= fa_light_count();\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    if (_1366)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    vec3 param_1 = i.world_pos;\n    return fa_light_sample(param, param_1);\n}\n\nfloat fa_shadow_pcf(vec4 coord, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    vec3 _348 = coord.xyz / vec3(coord.w);\n    vec3 p = _348;\n    vec2 suv = (_348.xy * 0.5) + vec2(0.5);\n    if (fa_mesh_fs_params[10].z > 0.5)\n    {\n        vec3 _2427 = p;\n        _2427.z = (_2427.z * 0.5) + 0.5;\n        p = _2427;\n    }\n    else\n    {\n        vec2 _2430 = suv;\n        _2430.y = 1.0 - _2430.y;\n        suv = _2430;\n    }\n    bool _376 = suv.x < 0.0;\n    bool _383;\n    if (!_376)\n    {\n        _383 = suv.x > 1.0;\n    }\n    else\n    {\n        _383 = _376;\n    }\n    bool _390;\n    if (!_383)\n    {\n        _390 = suv.y < 0.0;\n    }\n    else\n    {\n        _390 = _383;\n    }\n    bool _397;\n    if (!_390)\n    {\n        _397 = suv.y > 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _404;\n    if (!_397)\n    {\n        _404 = p.z > 1.0;\n    }\n    else\n    {\n        _404 = _397;\n    }\n    if (_404)\n    {\n        return 1.0;\n    }\n    float _419 = fa_mesh_fs_params[5].w * (1.0 + (2.0 * (1.0 - clamp(dot(n, l), 0.0, 1.0))));\n    float lit = 0.0;\n    for (int ix = -1; ix <= 1; ix++)\n    {\n        for (int iy = -1; iy <= 1; iy++)\n        {\n            lit += float((p.z - _419) <= textureLod(fa_shadow_tex_fa_shadow_smp, suv + (vec2(float(ix), float(iy)) * fa_mesh_fs_params[10].y), 0.0).x);\n        }\n    }\n    return lit * 0.111111111938953399658203125;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec4 param = fa_shadow_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_pcf(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1297 = fa_light_sample(param, param_1);\n    vec3 _2371 = _1297.direction;\n    vec3 _2366 = _1297.color;\n    float _2373 = _1297.attenuation;\n    float _2368 = _1297.shadow;\n    int _2376 = _1297.type;\n    if ((_2376 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2371;\n        float _1311 = fa_shadow_factor(param_2, param_3);\n        _2368 = _1311;\n        _2366 = fa_lights[li * 1 + 32].xyz * (_2373 * _1311);\n    }\n    return LightSample(_2371, _2366, _2373, _2368, _1297._distance, _2376);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _1335 = n < 0;\n    bool _1342;\n    if (!_1335)\n    {\n        _1342 = n >= fa_light_count();\n    }\n    else\n    {\n        _1342 = _1335;\n    }\n    if (_1342)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    vec3 param_1 = i.world_pos;\n    vec3 param_2 = i.world_normal;\n    return fa_light_shadowed(param, param_1, param_2);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _668 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _676 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _679 = int(_668);\n    int _682 = int(_676);\n    float _692 = _676 - float(_682);\n    int _748 = (_679 * 9) + _682;\n    int _768 = ((_679 + 1) * 9) + _682;\n    return mix(mix(_743[_748], _743[_748 + 1], _692), mix(_743[_768], _743[_768 + 1], _692), _668 - float(_679));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _2245 = false;\n    float _2246 = 1.0;\n    float _2247 = 1.0;\n    float _2248 = 1.0;\n    float _2249 = 0.0;\n    float _2250 = 0.0;\n    float _2251 = 0.0;\n    float _2252 = 0.0;\n    float _2254 = 1.0;\n    bool _2255 = false;\n    vec3 _2256 = vec3(0.0);\n    float _2257 = 1.0;\n    float _2258 = 1.0;\n    float _2259 = 1.0;\n    float _2260 = 0.0;\n    float _2261 = 0.0;\n    vec3 _2262 = vec3(1.0, 0.0, 0.0);\n    vec3 _2263 = vec3(0.0, 0.0, 1.0);\n    float _2264 = 1.0;\n    float _2265 = 1.0;\n    float _830 = clamp(s.specular, 0.0, 1.0);\n    float _835 = clamp(s.ior, 1.0, 3.0);\n    bool _840 = (_830 != 1.0) || (_835 != 1.5);\n    bool _850;\n    if (!_840)\n    {\n        _850 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _850 = _840;\n    }\n    if (_850)\n    {\n        float _858 = (_835 - 1.0) / (_835 + 1.0);\n        f0 = mix(min(vec3(_858 * _858) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _830, s.albedo, vec3(metallic));\n        _2246 = mix(_830, 1.0, metallic);\n        _2245 = true;\n    }\n    float _886 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_886 > 0.0)\n    {\n        float _894 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _2249 = _886;\n        _2250 = _894;\n        float _901 = _894 * _894;\n        _2251 = _901;\n        _2252 = _901 * _901;\n        float _913 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _2254 = _913;\n        _2247 = 1.0 - (_886 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _913, 0.0, 1.0), 5.0))));\n        _2245 = true;\n    }\n    vec3 _933 = max(s.sheen_color, vec3(0.0));\n    float _942 = max(_933.x, max(_933.y, _933.z));\n    if (_942 > 0.0)\n    {\n        float _950 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _2255 = true;\n        _2256 = _933;\n        _2257 = _950;\n        _2258 = _950 * _950;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _950;\n        float _967 = fa_sheen_albedo(param, param_1);\n        _2260 = _967;\n        _2259 = 1.0 - min(_942 * _967, 1.0);\n        _2245 = true;\n    }\n    _2248 = _2247 * _2259;\n    float _986 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_986 != 0.0)\n    {\n        vec3 _1001 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1001;\n        if (dot(_1001, _1001) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1015 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1015.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1015.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1015.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1019 = t;\n        vec3 _1020 = normalize(_1019);\n        t = _1020;\n        vec3 _1045 = normalize((_1020 * cos(s.anisotropy_rotation)) + ((cross(n, _1020) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _2262 = _1045;\n        _2263 = cross(n, _1045);\n        float _1055 = roughness * roughness;\n        float _1061 = mix(_1055, 1.0, _986 * _986);\n        bool _1063 = _986 > 0.0;\n        _2264 = _1063 ? _1061 : _1055;\n        _2265 = _1063 ? _1055 : _1061;\n        _2261 = _986;\n        _2245 = true;\n    }\n    return FaLayers(_2245, _2246, _2247, _2248, _2249, _2250, _2251, _2252, i.world_normal, _2254, _2255, _2256, _2257, _2258, _2259, _2260, _2261, _2262, _2263, _2264, _2265);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _598 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _601 = _598.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_601 * _601, exp2((-9.27999973297119140625) * ndv)) * _601) + _598.y)) + _598.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _519 = rough * rough;\n    float _550 = 0.60000002384185791015625 * _519;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _519)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _550, 0.0500000007450580596923828125 + _550, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_519 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1096;\n        if (L.aniso >= 0.0)\n        {\n            _1096 = L.b;\n        }\n        else\n        {\n            _1096 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1096, v), _1096), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1129 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1129.x) + (vec3(L.f90) * _1129.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1184 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1184.x) + _1184.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _640 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _640.x) + vec3(_640.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _1223 = clamp(s.metallic, 0.0, 1.0);\n    float _1227 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _1234 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_1223));\n    vec3 f0 = _1234;\n    vec3 _1238 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _1238;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _1223;\n    float param_5 = _1227;\n    vec3 param_6 = _1234;\n    FaLayers _1255 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_1255.on)\n    {\n        FaLayers param_7 = _1255;\n        vec3 param_8 = _1238;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _1227;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _1238;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _1227;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _1403 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_1403 > bestPower)\n        {\n            bestPower = _1403;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _1432 = fa_light(param_2, param_3);\n        float _1440;\n        if (dot(s.normal, _1432.direction) > 0.5)\n        {\n            _1440 = 1.0;\n        }\n        else\n        {\n            _1440 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _1432.color) * _1440);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2119 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2119 = -_2119;\n    }\n    vec3 _1832 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _2119, fa_world_tangent, fa_uv, fa_vertex_color, _1832, gl_FrontFacing);\n    Surface _1837 = fa_standard_surface(param);\n    vec3 _2150 = _1837.albedo;\n    float _2151 = _1837.alpha;\n    vec3 _2152 = _1837.normal;\n    float _2153 = _1837.metallic;\n    float _2154 = _1837.roughness;\n    float _2155 = _1837.occlusion;\n    vec3 _2156 = _1837.emission;\n    float _2157 = _1837.clearcoat;\n    float _2158 = _1837.clearcoat_roughness;\n    vec3 _2159 = _1837.sheen_color;\n    float _2160 = _1837.sheen_roughness;\n    float _2161 = _1837.anisotropy;\n    float _2162 = _1837.anisotropy_rotation;\n    float _2163 = _1837.specular;\n    float _2164 = _1837.ior;\n    vec3 _2165 = _1837.specular_color;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2119, fa_world_tangent, fa_uv, fa_vertex_color, _1832, gl_FrontFacing);\n    Surface param_2 = _1837;\n    surface(param_1, param_2);\n    _2150 = param_2.albedo;\n    _2151 = param_2.alpha;\n    _2152 = param_2.normal;\n    _2153 = param_2.metallic;\n    _2154 = param_2.roughness;\n    _2155 = param_2.occlusion;\n    _2156 = param_2.emission;\n    _2157 = param_2.clearcoat;\n    _2158 = param_2.clearcoat_roughness;\n    _2159 = param_2.sheen_color;\n    _2160 = param_2.sheen_roughness;\n    _2161 = param_2.anisotropy;\n    _2162 = param_2.anisotropy_rotation;\n    _2163 = param_2.specular;\n    _2164 = param_2.ior;\n    _2165 = param_2.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2150;\n    }\n    else\n    {\n        vec3 _1858 = _2152;\n        vec3 _1859 = normalize(_1858);\n        _2152 = _1859;\n        SurfaceInput param_3 = SurfaceInput(fa_world_pos, _2119, fa_world_tangent, fa_uv, fa_vertex_color, _1832, gl_FrontFacing);\n        Surface param_4 = Surface(_2150, _2151, _1859, _2153, _2154, _2155, _2156, _2157, _2158, _2159, _2160, _2161, _2162, _2163, _2164, _2165);\n        result = lighting(param_3, param_4);\n    }\n    result += _2156;\n    bool _1878 = fa_mesh_fs_params[7].w > 0.0;\n    bool _1885;\n    if (!_1878)\n    {\n        _1885 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _1885 = _1878;\n    }\n    if (_1885)\n    {\n        vec3 _1894 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _1900 = dot(_1894, fa_mesh_fs_params[9].xyz);\n        bool _1904 = fa_mesh_fs_params[9].w > 0.5;\n        float _1905;\n        if (_1904)\n        {\n            _1905 = _1900;\n        }\n        else\n        {\n            _1905 = length(_1894);\n        }\n        float _1917 = _1905 - fa_mesh_fs_params[8].x;\n        if (_1917 > 0.0)\n        {\n            float _1926 = fa_mesh_fs_params[7].w * _1917;\n            float tau = _1926 * _1926;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _1942;\n                if (_1904)\n                {\n                    _1942 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _1900);\n                }\n                else\n                {\n                    _1942 = fa_mesh_fs_params[0].y;\n                }\n                float _1963 = mix(_1942, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _1905, 0.0, 1.0));\n                float _1967 = fa_world_pos.y - _1963;\n                float _1972 = _1963 - fa_mesh_fs_params[8].z;\n                float _1977 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _1980 = _1972 <= 0.0;\n                bool _1981 = !_1980;\n                bool _1987;\n                if (_1981)\n                {\n                    _1987 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1987 = _1980;\n                }\n                float _1988;\n                if (_1987)\n                {\n                    _1988 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _1988 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _1972, 80.0));\n                }\n                bool _2015;\n                if (_1981)\n                {\n                    _2015 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2015 = _1980;\n                }\n                float _2016;\n                if (_2015)\n                {\n                    _2016 = fa_mesh_fs_params[8].y * _1972;\n                }\n                else\n                {\n                    _2016 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1972, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2041 = _1977 <= 0.0;\n                bool _2048;\n                if (!_2041)\n                {\n                    _2048 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2048 = _2041;\n                }\n                float _2049;\n                if (_2048)\n                {\n                    _2049 = fa_mesh_fs_params[8].y * _1977;\n                }\n                else\n                {\n                    _2049 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _1977, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2076;\n                if (abs(_1967) < 0.001000000047497451305389404296875)\n                {\n                    _2076 = _1988;\n                }\n                else\n                {\n                    _2076 = (_2049 - _2016) / _1967;\n                }\n                tau += (_1917 * max(_2076, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2151);\n}\n\n",
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
            "inst_name": "_217",
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
            "inst_name": "_335",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_1446",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[14].x;\n    float _752 = fa_mesh_fs_params[14].y;\n    float _755 = fa_mesh_fs_params[14].z;\n    float _754 = fa_mesh_fs_params[15].w;\n    float _757 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[15].xyz, _754, _755, fa_mesh_fs_params[14].w, _757, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _517 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _532 = normalize(param_2.normal);\n    vec3 _547 = normalize(vec3(dot(fa_pre_r0, _532), dot(fa_pre_r1, _532), dot(fa_pre_r2, _532)));\n    float _559 = _547.z;\n    vec2 e = _547.xy / vec2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[18];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[14].x;\n    float _752 = fa_mesh_fs_params[14].y;\n    float _755 = fa_mesh_fs_params[14].z;\n    float _754 = fa_mesh_fs_params[15].w;\n    float _757 = fa_mesh_fs_params[16].x;\n    if (fa_mesh_fs_params[16].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[16].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[16].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[15].xyz, _754, _755, fa_mesh_fs_params[14].w, _757, fa_mesh_fs_params[16].y, fa_mesh_fs_params[17].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _517 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _517, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _532 = normalize(param_2.normal);\n    vec3 _547 = normalize(vec3(dot(fa_pre_r0, _532), dot(fa_pre_r1, _532), dot(fa_pre_r2, _532)));\n    float _559 = _547.z;\n    vec2 e = _547.xy / vec2((abs(_547.x) + abs(_547.y)) + abs(_559));\n    if (_559 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
