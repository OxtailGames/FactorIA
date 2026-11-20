{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "b9137a7fd5249b4222bedebb6ca5e740fb7c4a348474dd42da5706fae9a2d4c0",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1530[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _423 = fa_mesh_fs_params[19].x < 0.0;\n    bool _430;\n    if (!_423)\n    {\n        _430 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    bool _438;\n    if (!_430)\n    {\n        _438 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _438 = _430;\n    }\n    bool _445;\n    if (!_438)\n    {\n        _445 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _445 = _438;\n    }\n    bool _452;\n    if (!_445)\n    {\n        _452 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    if (_452)\n    {\n        return ivec2(0);\n    }\n    vec4 _462 = vec4(world_pos, 1.0);\n    float _469 = dot(fa_mesh_fs_params[16], _462);\n    if (!(_469 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _491 = vec2(dot(fa_mesh_fs_params[14], _462), dot(fa_mesh_fs_params[15], _462)) / vec2(_469);\n    int _495 = int(fa_mesh_fs_params[18].x);\n    int _499 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _499) + clamp(int(floor(((_491.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _499 - 1)) * _495)) + clamp(int(floor(((_491.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _495 - 1);\n    vec4 _570 = fa_light_texel(param);\n    return ivec2(int(_570.x), int(_570.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2080 = fa_cluster_lookup(param);\n    fa_cl_slot = _2080.x;\n    fa_cl_local = _2080.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2327 = fa_linear_to_srgb(param);\n        c = _2327;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2335 = fa_srgb_to_linear(param_1);\n            c = _2335;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _198;\n    if (i.front_facing)\n    {\n        _198 = i.world_normal;\n    }\n    else\n    {\n        _198 = -i.world_normal;\n    }\n    vec3 _222 = normalize(i.world_tangent.xyz - (_198 * dot(_198, i.world_tangent.xyz)));\n    vec3 _250 = normalize(((_222 * m.x) + ((cross(_198, _222) * i.world_tangent.w) * m.y)) + (_198 * m.z));\n    vec3 _253;\n    if (i.front_facing)\n    {\n        _253 = _250;\n    }\n    else\n    {\n        _253 = -_250;\n    }\n    return _253;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2366 = fa_tex_fix(param_2, param_3);\n    vec4 _3279 = base_t;\n    _3279.x = _2366.x;\n    _3279.y = _2366.y;\n    _3279.z = _2366.z;\n    base_t = _3279;\n    vec4 _2380 = (_3279 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3213 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2412 = fa_tex_fix(param_6, param_7);\n        vec3 _2416 = (_2412 * 2.0) - vec3(1.0);\n        vec2 _2421 = _2416.xy * fa_mesh_fs_params[6].x;\n        vec3 _3287 = _2416;\n        _3287.x = _2421.x;\n        _3287.y = _2421.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3287;\n        _3213 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2450 = fa_tex_fix(param_12, param_13);\n    vec4 _3290 = mrt;\n    _3290.x = _2450.x;\n    _3290.y = _2450.y;\n    _3290.z = _2450.z;\n    mrt = _3290;\n    vec4 _2478 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2478.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2490 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2520 = fa_tex_fix(param_20, param_21);\n    float _3218 = fa_mesh_fs_params[20].x;\n    float _3219 = fa_mesh_fs_params[20].y;\n    float _3222 = fa_mesh_fs_params[20].z;\n    float _3221 = fa_mesh_fs_params[21].w;\n    float _3224 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3218 *= _2490.y;\n            _3219 *= _2490.z;\n            _3221 *= _2478.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3222 *= mrt.x;\n            _3224 *= mrt.w;\n        }\n    }\n    return Surface(_2380.xyz, _2380.w, _3213, clamp(fa_mesh_fs_params[5].x * _2450.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2450.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2490.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2520), _3218, _3219, fa_mesh_fs_params[21].xyz, _3221, _3222, fa_mesh_fs_params[20].w, _3224, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _290 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _296 = fa_light_texel(param_1);\n    float _299 = _296.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _306 = _299 < 0.5;\n    vec3 l;\n    if (_306)\n    {\n        l = normalize(_290.xyz);\n    }\n    else\n    {\n        vec3 _318 = _290.xyz - world_pos;\n        float _320 = length(_318);\n        dist = _320;\n        l = _318 / vec3(max(_320, 9.9999997473787516355514526367188e-05));\n        float _335 = _320 / max(_290.w, 0.001000000047497451305389404296875);\n        float _341 = clamp(1.0 - (_335 * _335), 0.0, 1.0);\n        atten = _341 * _341;\n        if (_299 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _355 = fa_light_texel(param_2);\n            float _365 = _355.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _372 = fa_light_texel(param_3);\n            float _373 = _372.x;\n            float cos_inner = _373;\n            if (_373 > 1.5)\n            {\n                cos_inner = mix(_365, 1.0, 0.25);\n            }\n            atten *= smoothstep(_365, cos_inner, dot(-l, normalize(_355.xyz)));\n        }\n    }\n    int _404;\n    if (_306)\n    {\n        _404 = 0;\n    }\n    else\n    {\n        _404 = (_299 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _296.xyz * atten, atten, 1.0, dist, _404);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2165 = n < 0;\n    bool _2172;\n    if (!_2165)\n    {\n        _2172 = n >= fa_light_count();\n    }\n    else\n    {\n        _2172 = _2165;\n    }\n    if (_2172)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _644;\n    if (i == 0)\n    {\n        _644 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _660;\n        if (i == 1)\n        {\n            _660 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _668;\n            if (i == 2)\n            {\n                _668 = fa_shadows[24].z;\n            }\n            else\n            {\n                _668 = fa_shadows[24].w;\n            }\n            _660 = _668;\n        }\n        _644 = _660;\n    }\n    return _644;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _632 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_632), sin(_632)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _706 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _711 = clamp(dot(n, l), 0.0, 1.0);\n    float _717 = sqrt(1.0 - (_711 * _711));\n    float _725 = min(_717 / max(_711, 0.20000000298023223876953125), 4.0);\n    float _730;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _730 = fa_shadows[26].y;\n    }\n    else\n    {\n        _730 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _755 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_730 * _717)), 1.0);\n    float _762 = _755.x;\n    bool _765 = _762 < fa_shadows[ci * 1 + 16].x;\n    bool _774;\n    if (!_765)\n    {\n        _774 = _762 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _774 = _765;\n    }\n    bool _783;\n    if (!_774)\n    {\n        _783 = _755.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _783 = _774;\n    }\n    bool _792;\n    if (!_783)\n    {\n        _792 = _755.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _792 = _783;\n    }\n    bool _799;\n    if (!_792)\n    {\n        _799 = _755.z > 1.0;\n    }\n    else\n    {\n        _799 = _792;\n    }\n    if (_799)\n    {\n        return -1.0;\n    }\n    float _808;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _808 = fa_shadows[26].x;\n    }\n    else\n    {\n        _808 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _827 = _755.z - ((_808 * (1.0 + (0.5 * _725))) / _706);\n    float _836 = ((fa_shadows[ci * 1 + 20].x * min(_725, 3.0)) * 0.5) / _706;\n    int _845 = int(fa_shadows[25].z + 0.5);\n    if (_845 == 1)\n    {\n        vec2 param = _755.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _856 = fa_shadow_depth(param, param_1);\n        return float(_827 <= _856);\n    }\n    float _863 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _866 = _845 == 2;\n    if (_866)\n    {\n        float _880 = clamp(((fa_shadows[25].w * _706) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _863;\n            vec2 _899 = fa_shadow_vogel(param_2, param_3, param_4) * _880;\n            vec2 param_5 = _755.xy + (_899 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _910 = fa_shadow_depth(param_5, param_6);\n            if (_910 < (_827 - (length(_899) * _836)))\n            {\n                sum += _910;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_827 - (sum / cnt), 0.0) * _706) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _954 = _866 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _954; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _954;\n        float param_9 = _863;\n        vec2 _973 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _755.xy + (_973 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _984 = fa_shadow_depth(param_10, param_11);\n        lit += float((_827 - (length(_973) * _836)) <= _984);\n    }\n    return lit / float(_954);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1014 = int(fa_shadows[25].x + 0.5);\n    if (_1014 < 1)\n    {\n        return 1.0;\n    }\n    float _1030 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1014 - 1;\n    if (_1030 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1042 = _1014 > 1;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1030 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 1;\n    }\n    bool _1053 = _1014 > 2;\n    bool _1060;\n    if (_1053)\n    {\n        _1060 = _1030 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        ci = 2;\n    }\n    bool _1064 = _1014 > 3;\n    bool _1071;\n    if (_1064)\n    {\n        _1071 = _1030 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1071 = _1064;\n    }\n    if (_1071)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1014)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1097 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1097;\n        if (_1097 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1122 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1122 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1141 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1122, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1152 = clamp((_1030 - (fa_shadow_split_at(param_7) - _1141)) / _1141, 0.0, 1.0);\n        if (_1152 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1014)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1173 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1173;\n                if (_1173 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1152);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2108 = fa_light_sample(param, param_1);\n    vec3 _3189 = _2108.direction;\n    vec3 _3184 = _2108.color;\n    float _3186 = _2108.shadow;\n    int _3194 = _2108.type;\n    if ((_3194 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _3189;\n        float _2122 = fa_shadow_factor(param_2, param_3);\n        _3186 = _2122;\n        _3184 *= _2122;\n    }\n    return LightSample(_3189, _3184, _2108.attenuation, _3186, _2108._distance, _3194);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2139 = n < 0;\n    bool _2146;\n    if (!_2139)\n    {\n        _2146 = n >= fa_light_count();\n    }\n    else\n    {\n        _2146 = _2139;\n    }\n    if (_2146)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1455 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1463 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1466 = int(_1455);\n    int _1469 = int(_1463);\n    float _1479 = _1463 - float(_1469);\n    int _1535 = (_1466 * 9) + _1469;\n    int _1555 = ((_1466 + 1) * 9) + _1469;\n    return mix(mix(_1530[_1535], _1530[_1535 + 1], _1479), mix(_1530[_1555], _1530[_1555 + 1], _1479), _1455 - float(_1466));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3063 = false;\n    float _3064 = 1.0;\n    float _3065 = 1.0;\n    float _3066 = 1.0;\n    float _3067 = 0.0;\n    float _3068 = 0.0;\n    float _3069 = 0.0;\n    float _3070 = 0.0;\n    float _3072 = 1.0;\n    bool _3073 = false;\n    vec3 _3074 = vec3(0.0);\n    float _3075 = 1.0;\n    float _3076 = 1.0;\n    float _3077 = 1.0;\n    float _3078 = 0.0;\n    float _3079 = 0.0;\n    vec3 _3080 = vec3(1.0, 0.0, 0.0);\n    vec3 _3081 = vec3(0.0, 0.0, 1.0);\n    float _3082 = 1.0;\n    float _3083 = 1.0;\n    float _1610 = clamp(s.specular, 0.0, 1.0);\n    float _1614 = clamp(s.ior, 1.0, 3.0);\n    bool _1619 = (_1610 != 1.0) || (_1614 != 1.5);\n    bool _1629;\n    if (!_1619)\n    {\n        _1629 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1629 = _1619;\n    }\n    if (_1629)\n    {\n        float _1637 = (_1614 - 1.0) / (_1614 + 1.0);\n        f0 = mix(min(vec3(_1637 * _1637) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1610, s.albedo, vec3(metallic));\n        _3064 = mix(_1610, 1.0, metallic);\n        _3063 = true;\n    }\n    float _1665 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1665 > 0.0)\n    {\n        float _1673 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3067 = _1665;\n        _3068 = _1673;\n        float _1680 = _1673 * _1673;\n        _3069 = _1680;\n        _3070 = _1680 * _1680;\n        float _1692 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3072 = _1692;\n        _3065 = 1.0 - (_1665 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1692, 0.0, 1.0), 5.0))));\n        _3063 = true;\n    }\n    vec3 _1712 = max(s.sheen_color, vec3(0.0));\n    float _1721 = max(_1712.x, max(_1712.y, _1712.z));\n    if (_1721 > 0.0)\n    {\n        float _1729 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3073 = true;\n        _3074 = _1712;\n        _3075 = _1729;\n        _3076 = _1729 * _1729;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1729;\n        float _1746 = fa_sheen_albedo(param, param_1);\n        _3078 = _1746;\n        _3077 = 1.0 - min(_1721 * _1746, 1.0);\n        _3063 = true;\n    }\n    _3066 = _3065 * _3077;\n    float _1765 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1765 != 0.0)\n    {\n        vec3 _1780 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1780;\n        if (dot(_1780, _1780) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1794 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1794.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1794.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1794.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1798 = t;\n        vec3 _1799 = normalize(_1798);\n        t = _1799;\n        vec3 _1824 = normalize((_1799 * cos(s.anisotropy_rotation)) + ((cross(n, _1799) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3080 = _1824;\n        _3081 = cross(n, _1824);\n        float _1834 = roughness * roughness;\n        float _1840 = mix(_1834, 1.0, _1765 * _1765);\n        bool _1842 = _1765 > 0.0;\n        _3082 = _1842 ? _1840 : _1834;\n        _3083 = _1842 ? _1834 : _1840;\n        _3079 = _1765;\n        _3063 = true;\n    }\n    return FaLayers(_3063, _3064, _3065, _3066, _3067, _3068, _3069, _3070, i.world_normal, _3072, _3073, _3074, _3075, _3076, _3077, _3078, _3079, _3080, _3081, _3082, _3083);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1387 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1390 = _1387.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1390 * _1390, exp2((-9.27999973297119140625) * ndv)) * _1390) + _1387.y)) + _1387.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1310 = rough * rough;\n    float _1340 = 0.60000002384185791015625 * _1310;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1310)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1340, 0.0500000007450580596923828125 + _1340, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1310 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1875;\n        if (L.aniso >= 0.0)\n        {\n            _1875 = L.b;\n        }\n        else\n        {\n            _1875 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1875, v), _1875), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1908 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1908.x) + (vec3(L.f90) * _1908.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1963 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1963.x) + _1963.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1429 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1429.x) + vec3(_1429.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2002 = clamp(s.metallic, 0.0, 1.0);\n    float _2006 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2013 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2002));\n    vec3 f0 = _2013;\n    vec3 _2017 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2017;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2002;\n    float param_5 = _2006;\n    vec3 param_6 = _2013;\n    FaLayers _2034 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2034.on)\n    {\n        FaLayers param_7 = _2034;\n        vec3 param_8 = _2017;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2006;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2017;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2006;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2212 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2212 > bestPower)\n        {\n            bestPower = _2212;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2241 = fa_light(param_2, param_3);\n        float _2249;\n        if (dot(s.normal, _2241.direction) > 0.5)\n        {\n            _2249 = 1.0;\n        }\n        else\n        {\n            _2249 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _2241.color) * _2249);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1197 = int(fa_shadows[25].x + 0.5);\n    float _1207 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1212 = _1197 > 0;\n    bool _1221;\n    if (_1212)\n    {\n        int param = _1197 - 1;\n        _1221 = _1207 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1221 = _1212;\n    }\n    if (_1221)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1228 = _1197 > 1;\n        bool _1235;\n        if (_1228)\n        {\n            _1235 = _1207 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1235 = _1228;\n        }\n        if (_1235)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1241 = _1197 > 2;\n        bool _1248;\n        if (_1241)\n        {\n            _1248 = _1207 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1248 = _1241;\n        }\n        if (_1248)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1254 = _1197 > 3;\n        bool _1261;\n        if (_1254)\n        {\n            _1261 = _1207 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1261 = _1254;\n        }\n        if (_1261)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2937 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2937 = -_2937;\n    }\n    vec3 _2641 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing);\n    Surface _2649 = fa_standard_surface(param_1);\n    vec3 _2968 = _2649.albedo;\n    float _2969 = _2649.alpha;\n    vec3 _2970 = _2649.normal;\n    float _2971 = _2649.metallic;\n    float _2972 = _2649.roughness;\n    float _2973 = _2649.occlusion;\n    vec3 _2974 = _2649.emission;\n    float _2975 = _2649.clearcoat;\n    float _2976 = _2649.clearcoat_roughness;\n    vec3 _2977 = _2649.sheen_color;\n    float _2978 = _2649.sheen_roughness;\n    float _2979 = _2649.anisotropy;\n    float _2980 = _2649.anisotropy_rotation;\n    float _2981 = _2649.specular;\n    float _2982 = _2649.ior;\n    vec3 _2983 = _2649.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing);\n    Surface param_3 = _2649;\n    surface(param_2, param_3);\n    _2968 = param_3.albedo;\n    _2969 = param_3.alpha;\n    _2970 = param_3.normal;\n    _2971 = param_3.metallic;\n    _2972 = param_3.roughness;\n    _2973 = param_3.occlusion;\n    _2974 = param_3.emission;\n    _2975 = param_3.clearcoat;\n    _2976 = param_3.clearcoat_roughness;\n    _2977 = param_3.sheen_color;\n    _2978 = param_3.sheen_roughness;\n    _2979 = param_3.anisotropy;\n    _2980 = param_3.anisotropy_rotation;\n    _2981 = param_3.specular;\n    _2982 = param_3.ior;\n    _2983 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2968;\n    }\n    else\n    {\n        vec3 _2670 = _2970;\n        vec3 _2671 = normalize(_2670);\n        _2970 = _2671;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing);\n        Surface param_5 = Surface(_2968, _2969, _2671, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982, _2983);\n        result = lighting(param_4, param_5);\n    }\n    vec3 _2686 = result;\n    vec3 _2687 = _2686 + _2974;\n    result = _2687;\n    vec3 param_6 = _2687;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2696 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        vec3 _2712 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2718 = dot(_2712, fa_mesh_fs_params[9].xyz);\n        bool _2722 = fa_mesh_fs_params[9].w > 0.5;\n        float _2723;\n        if (_2722)\n        {\n            _2723 = _2718;\n        }\n        else\n        {\n            _2723 = length(_2712);\n        }\n        float _2735 = _2723 - fa_mesh_fs_params[8].x;\n        if (_2735 > 0.0)\n        {\n            float _2744 = fa_mesh_fs_params[7].w * _2735;\n            float tau = _2744 * _2744;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2760;\n                if (_2722)\n                {\n                    _2760 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2718);\n                }\n                else\n                {\n                    _2760 = fa_mesh_fs_params[0].y;\n                }\n                float _2781 = mix(_2760, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2723, 0.0, 1.0));\n                float _2785 = fa_world_pos.y - _2781;\n                float _2790 = _2781 - fa_mesh_fs_params[8].z;\n                float _2795 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2798 = _2790 <= 0.0;\n                bool _2799 = !_2798;\n                bool _2805;\n                if (_2799)\n                {\n                    _2805 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2805 = _2798;\n                }\n                float _2806;\n                if (_2805)\n                {\n                    _2806 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2806 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2790, 80.0));\n                }\n                bool _2833;\n                if (_2799)\n                {\n                    _2833 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2833 = _2798;\n                }\n                float _2834;\n                if (_2833)\n                {\n                    _2834 = fa_mesh_fs_params[8].y * _2790;\n                }\n                else\n                {\n                    _2834 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2790, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2859 = _2795 <= 0.0;\n                bool _2866;\n                if (!_2859)\n                {\n                    _2866 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2866 = _2859;\n                }\n                float _2867;\n                if (_2866)\n                {\n                    _2867 = fa_mesh_fs_params[8].y * _2795;\n                }\n                else\n                {\n                    _2867 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2795, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2894;\n                if (abs(_2785) < 0.001000000047497451305389404296875)\n                {\n                    _2894 = _2806;\n                }\n                else\n                {\n                    _2894 = (_2867 - _2834) / _2785;\n                }\n                tau += (_2735 * max(_2894, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2969);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_418",
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
            "inst_name": "_654",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2255",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _389 = _273.world_pos;\n    fa_world_pos = _389;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_389, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1530[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _423 = fa_mesh_fs_params[19].x < 0.0;\n    bool _430;\n    if (!_423)\n    {\n        _430 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _430 = _423;\n    }\n    bool _438;\n    if (!_430)\n    {\n        _438 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _438 = _430;\n    }\n    bool _445;\n    if (!_438)\n    {\n        _445 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _445 = _438;\n    }\n    bool _452;\n    if (!_445)\n    {\n        _452 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _452 = _445;\n    }\n    if (_452)\n    {\n        return ivec2(0);\n    }\n    vec4 _462 = vec4(world_pos, 1.0);\n    float _469 = dot(fa_mesh_fs_params[16], _462);\n    if (!(_469 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _491 = vec2(dot(fa_mesh_fs_params[14], _462), dot(fa_mesh_fs_params[15], _462)) / vec2(_469);\n    int _495 = int(fa_mesh_fs_params[18].x);\n    int _499 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _499) + clamp(int(floor(((_491.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _499 - 1)) * _495)) + clamp(int(floor(((_491.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _495 - 1);\n    vec4 _570 = fa_light_texel(param);\n    return ivec2(int(_570.x), int(_570.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2080 = fa_cluster_lookup(param);\n    fa_cl_slot = _2080.x;\n    fa_cl_local = _2080.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2327 = fa_linear_to_srgb(param);\n        c = _2327;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2335 = fa_srgb_to_linear(param_1);\n            c = _2335;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _198;\n    if (i.front_facing)\n    {\n        _198 = i.world_normal;\n    }\n    else\n    {\n        _198 = -i.world_normal;\n    }\n    vec3 _222 = normalize(i.world_tangent.xyz - (_198 * dot(_198, i.world_tangent.xyz)));\n    vec3 _250 = normalize(((_222 * m.x) + ((cross(_198, _222) * i.world_tangent.w) * m.y)) + (_198 * m.z));\n    vec3 _253;\n    if (i.front_facing)\n    {\n        _253 = _250;\n    }\n    else\n    {\n        _253 = -_250;\n    }\n    return _253;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2366 = fa_tex_fix(param_2, param_3);\n    vec4 _3279 = base_t;\n    _3279.x = _2366.x;\n    _3279.y = _2366.y;\n    _3279.z = _2366.z;\n    base_t = _3279;\n    vec4 _2380 = (_3279 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3213 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2412 = fa_tex_fix(param_6, param_7);\n        vec3 _2416 = (_2412 * 2.0) - vec3(1.0);\n        vec2 _2421 = _2416.xy * fa_mesh_fs_params[6].x;\n        vec3 _3287 = _2416;\n        _3287.x = _2421.x;\n        _3287.y = _2421.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3287;\n        _3213 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2450 = fa_tex_fix(param_12, param_13);\n    vec4 _3290 = mrt;\n    _3290.x = _2450.x;\n    _3290.y = _2450.y;\n    _3290.z = _2450.z;\n    mrt = _3290;\n    vec4 _2478 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2478.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2490 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2520 = fa_tex_fix(param_20, param_21);\n    float _3218 = fa_mesh_fs_params[20].x;\n    float _3219 = fa_mesh_fs_params[20].y;\n    float _3222 = fa_mesh_fs_params[20].z;\n    float _3221 = fa_mesh_fs_params[21].w;\n    float _3224 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3218 *= _2490.y;\n            _3219 *= _2490.z;\n            _3221 *= _2478.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3222 *= mrt.x;\n            _3224 *= mrt.w;\n        }\n    }\n    return Surface(_2380.xyz, _2380.w, _3213, clamp(fa_mesh_fs_params[5].x * _2450.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2450.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2490.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2520), _3218, _3219, fa_mesh_fs_params[21].xyz, _3221, _3222, fa_mesh_fs_params[20].w, _3224, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _290 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _296 = fa_light_texel(param_1);\n    float _299 = _296.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _306 = _299 < 0.5;\n    vec3 l;\n    if (_306)\n    {\n        l = normalize(_290.xyz);\n    }\n    else\n    {\n        vec3 _318 = _290.xyz - world_pos;\n        float _320 = length(_318);\n        dist = _320;\n        l = _318 / vec3(max(_320, 9.9999997473787516355514526367188e-05));\n        float _335 = _320 / max(_290.w, 0.001000000047497451305389404296875);\n        float _341 = clamp(1.0 - (_335 * _335), 0.0, 1.0);\n        atten = _341 * _341;\n        if (_299 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _355 = fa_light_texel(param_2);\n            float _365 = _355.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _372 = fa_light_texel(param_3);\n            float _373 = _372.x;\n            float cos_inner = _373;\n            if (_373 > 1.5)\n            {\n                cos_inner = mix(_365, 1.0, 0.25);\n            }\n            atten *= smoothstep(_365, cos_inner, dot(-l, normalize(_355.xyz)));\n        }\n    }\n    int _404;\n    if (_306)\n    {\n        _404 = 0;\n    }\n    else\n    {\n        _404 = (_299 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _296.xyz * atten, atten, 1.0, dist, _404);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2165 = n < 0;\n    bool _2172;\n    if (!_2165)\n    {\n        _2172 = n >= fa_light_count();\n    }\n    else\n    {\n        _2172 = _2165;\n    }\n    if (_2172)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _644;\n    if (i == 0)\n    {\n        _644 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _660;\n        if (i == 1)\n        {\n            _660 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _668;\n            if (i == 2)\n            {\n                _668 = fa_shadows[24].z;\n            }\n            else\n            {\n                _668 = fa_shadows[24].w;\n            }\n            _660 = _668;\n        }\n        _644 = _660;\n    }\n    return _644;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _632 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_632), sin(_632)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _706 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _711 = clamp(dot(n, l), 0.0, 1.0);\n    float _717 = sqrt(1.0 - (_711 * _711));\n    float _725 = min(_717 / max(_711, 0.20000000298023223876953125), 4.0);\n    float _730;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _730 = fa_shadows[26].y;\n    }\n    else\n    {\n        _730 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _755 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_730 * _717)), 1.0);\n    float _762 = _755.x;\n    bool _765 = _762 < fa_shadows[ci * 1 + 16].x;\n    bool _774;\n    if (!_765)\n    {\n        _774 = _762 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _774 = _765;\n    }\n    bool _783;\n    if (!_774)\n    {\n        _783 = _755.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _783 = _774;\n    }\n    bool _792;\n    if (!_783)\n    {\n        _792 = _755.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _792 = _783;\n    }\n    bool _799;\n    if (!_792)\n    {\n        _799 = _755.z > 1.0;\n    }\n    else\n    {\n        _799 = _792;\n    }\n    if (_799)\n    {\n        return -1.0;\n    }\n    float _808;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _808 = fa_shadows[26].x;\n    }\n    else\n    {\n        _808 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _827 = _755.z - ((_808 * (1.0 + (0.5 * _725))) / _706);\n    float _836 = ((fa_shadows[ci * 1 + 20].x * min(_725, 3.0)) * 0.5) / _706;\n    int _845 = int(fa_shadows[25].z + 0.5);\n    if (_845 == 1)\n    {\n        vec2 param = _755.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _856 = fa_shadow_depth(param, param_1);\n        return float(_827 <= _856);\n    }\n    float _863 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _866 = _845 == 2;\n    if (_866)\n    {\n        float _880 = clamp(((fa_shadows[25].w * _706) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _863;\n            vec2 _899 = fa_shadow_vogel(param_2, param_3, param_4) * _880;\n            vec2 param_5 = _755.xy + (_899 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _910 = fa_shadow_depth(param_5, param_6);\n            if (_910 < (_827 - (length(_899) * _836)))\n            {\n                sum += _910;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_827 - (sum / cnt), 0.0) * _706) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _954 = _866 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _954; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _954;\n        float param_9 = _863;\n        vec2 _973 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _755.xy + (_973 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _984 = fa_shadow_depth(param_10, param_11);\n        lit += float((_827 - (length(_973) * _836)) <= _984);\n    }\n    return lit / float(_954);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1014 = int(fa_shadows[25].x + 0.5);\n    if (_1014 < 1)\n    {\n        return 1.0;\n    }\n    float _1030 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1014 - 1;\n    if (_1030 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1042 = _1014 > 1;\n    bool _1049;\n    if (_1042)\n    {\n        _1049 = _1030 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1049 = _1042;\n    }\n    if (_1049)\n    {\n        ci = 1;\n    }\n    bool _1053 = _1014 > 2;\n    bool _1060;\n    if (_1053)\n    {\n        _1060 = _1030 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1060 = _1053;\n    }\n    if (_1060)\n    {\n        ci = 2;\n    }\n    bool _1064 = _1014 > 3;\n    bool _1071;\n    if (_1064)\n    {\n        _1071 = _1030 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1071 = _1064;\n    }\n    if (_1071)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1014)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1097 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1097;\n        if (_1097 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1122;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1122 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1122 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1141 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1122, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1152 = clamp((_1030 - (fa_shadow_split_at(param_7) - _1141)) / _1141, 0.0, 1.0);\n        if (_1152 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1014)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1173 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1173;\n                if (_1173 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1152);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2108 = fa_light_sample(param, param_1);\n    vec3 _3189 = _2108.direction;\n    vec3 _3184 = _2108.color;\n    float _3186 = _2108.shadow;\n    int _3194 = _2108.type;\n    if ((_3194 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _3189;\n        float _2122 = fa_shadow_factor(param_2, param_3);\n        _3186 = _2122;\n        _3184 *= _2122;\n    }\n    return LightSample(_3189, _3184, _2108.attenuation, _3186, _2108._distance, _3194);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2139 = n < 0;\n    bool _2146;\n    if (!_2139)\n    {\n        _2146 = n >= fa_light_count();\n    }\n    else\n    {\n        _2146 = _2139;\n    }\n    if (_2146)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1455 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1463 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1466 = int(_1455);\n    int _1469 = int(_1463);\n    float _1479 = _1463 - float(_1469);\n    int _1535 = (_1466 * 9) + _1469;\n    int _1555 = ((_1466 + 1) * 9) + _1469;\n    return mix(mix(_1530[_1535], _1530[_1535 + 1], _1479), mix(_1530[_1555], _1530[_1555 + 1], _1479), _1455 - float(_1466));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3063 = false;\n    float _3064 = 1.0;\n    float _3065 = 1.0;\n    float _3066 = 1.0;\n    float _3067 = 0.0;\n    float _3068 = 0.0;\n    float _3069 = 0.0;\n    float _3070 = 0.0;\n    float _3072 = 1.0;\n    bool _3073 = false;\n    vec3 _3074 = vec3(0.0);\n    float _3075 = 1.0;\n    float _3076 = 1.0;\n    float _3077 = 1.0;\n    float _3078 = 0.0;\n    float _3079 = 0.0;\n    vec3 _3080 = vec3(1.0, 0.0, 0.0);\n    vec3 _3081 = vec3(0.0, 0.0, 1.0);\n    float _3082 = 1.0;\n    float _3083 = 1.0;\n    float _1610 = clamp(s.specular, 0.0, 1.0);\n    float _1614 = clamp(s.ior, 1.0, 3.0);\n    bool _1619 = (_1610 != 1.0) || (_1614 != 1.5);\n    bool _1629;\n    if (!_1619)\n    {\n        _1629 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1629 = _1619;\n    }\n    if (_1629)\n    {\n        float _1637 = (_1614 - 1.0) / (_1614 + 1.0);\n        f0 = mix(min(vec3(_1637 * _1637) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1610, s.albedo, vec3(metallic));\n        _3064 = mix(_1610, 1.0, metallic);\n        _3063 = true;\n    }\n    float _1665 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1665 > 0.0)\n    {\n        float _1673 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3067 = _1665;\n        _3068 = _1673;\n        float _1680 = _1673 * _1673;\n        _3069 = _1680;\n        _3070 = _1680 * _1680;\n        float _1692 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3072 = _1692;\n        _3065 = 1.0 - (_1665 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1692, 0.0, 1.0), 5.0))));\n        _3063 = true;\n    }\n    vec3 _1712 = max(s.sheen_color, vec3(0.0));\n    float _1721 = max(_1712.x, max(_1712.y, _1712.z));\n    if (_1721 > 0.0)\n    {\n        float _1729 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3073 = true;\n        _3074 = _1712;\n        _3075 = _1729;\n        _3076 = _1729 * _1729;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1729;\n        float _1746 = fa_sheen_albedo(param, param_1);\n        _3078 = _1746;\n        _3077 = 1.0 - min(_1721 * _1746, 1.0);\n        _3063 = true;\n    }\n    _3066 = _3065 * _3077;\n    float _1765 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1765 != 0.0)\n    {\n        vec3 _1780 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1780;\n        if (dot(_1780, _1780) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1794 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1794.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1794.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1794.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1798 = t;\n        vec3 _1799 = normalize(_1798);\n        t = _1799;\n        vec3 _1824 = normalize((_1799 * cos(s.anisotropy_rotation)) + ((cross(n, _1799) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3080 = _1824;\n        _3081 = cross(n, _1824);\n        float _1834 = roughness * roughness;\n        float _1840 = mix(_1834, 1.0, _1765 * _1765);\n        bool _1842 = _1765 > 0.0;\n        _3082 = _1842 ? _1840 : _1834;\n        _3083 = _1842 ? _1834 : _1840;\n        _3079 = _1765;\n        _3063 = true;\n    }\n    return FaLayers(_3063, _3064, _3065, _3066, _3067, _3068, _3069, _3070, i.world_normal, _3072, _3073, _3074, _3075, _3076, _3077, _3078, _3079, _3080, _3081, _3082, _3083);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1387 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1390 = _1387.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1390 * _1390, exp2((-9.27999973297119140625) * ndv)) * _1390) + _1387.y)) + _1387.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1310 = rough * rough;\n    float _1340 = 0.60000002384185791015625 * _1310;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1310)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1340, 0.0500000007450580596923828125 + _1340, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1310 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1875;\n        if (L.aniso >= 0.0)\n        {\n            _1875 = L.b;\n        }\n        else\n        {\n            _1875 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1875, v), _1875), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1908 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1908.x) + (vec3(L.f90) * _1908.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1963 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1963.x) + _1963.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1429 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1429.x) + vec3(_1429.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2002 = clamp(s.metallic, 0.0, 1.0);\n    float _2006 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2013 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2002));\n    vec3 f0 = _2013;\n    vec3 _2017 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2017;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2002;\n    float param_5 = _2006;\n    vec3 param_6 = _2013;\n    FaLayers _2034 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2034.on)\n    {\n        FaLayers param_7 = _2034;\n        vec3 param_8 = _2017;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2006;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2017;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2006;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2212 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2212 > bestPower)\n        {\n            bestPower = _2212;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2241 = fa_light(param_2, param_3);\n        float _2249;\n        if (dot(s.normal, _2241.direction) > 0.5)\n        {\n            _2249 = 1.0;\n        }\n        else\n        {\n            _2249 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _2241.color) * _2249);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1197 = int(fa_shadows[25].x + 0.5);\n    float _1207 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1212 = _1197 > 0;\n    bool _1221;\n    if (_1212)\n    {\n        int param = _1197 - 1;\n        _1221 = _1207 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1221 = _1212;\n    }\n    if (_1221)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1228 = _1197 > 1;\n        bool _1235;\n        if (_1228)\n        {\n            _1235 = _1207 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1235 = _1228;\n        }\n        if (_1235)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1241 = _1197 > 2;\n        bool _1248;\n        if (_1241)\n        {\n            _1248 = _1207 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1248 = _1241;\n        }\n        if (_1248)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1254 = _1197 > 3;\n        bool _1261;\n        if (_1254)\n        {\n            _1261 = _1207 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1261 = _1254;\n        }\n        if (_1261)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2937 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2937 = -_2937;\n    }\n    vec3 _2641 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing);\n    Surface _2649 = fa_standard_surface(param_1);\n    vec3 _2968 = _2649.albedo;\n    float _2969 = _2649.alpha;\n    vec3 _2970 = _2649.normal;\n    float _2971 = _2649.metallic;\n    float _2972 = _2649.roughness;\n    float _2973 = _2649.occlusion;\n    vec3 _2974 = _2649.emission;\n    float _2975 = _2649.clearcoat;\n    float _2976 = _2649.clearcoat_roughness;\n    vec3 _2977 = _2649.sheen_color;\n    float _2978 = _2649.sheen_roughness;\n    float _2979 = _2649.anisotropy;\n    float _2980 = _2649.anisotropy_rotation;\n    float _2981 = _2649.specular;\n    float _2982 = _2649.ior;\n    vec3 _2983 = _2649.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing);\n    Surface param_3 = _2649;\n    surface(param_2, param_3);\n    _2968 = param_3.albedo;\n    _2969 = param_3.alpha;\n    _2970 = param_3.normal;\n    _2971 = param_3.metallic;\n    _2972 = param_3.roughness;\n    _2973 = param_3.occlusion;\n    _2974 = param_3.emission;\n    _2975 = param_3.clearcoat;\n    _2976 = param_3.clearcoat_roughness;\n    _2977 = param_3.sheen_color;\n    _2978 = param_3.sheen_roughness;\n    _2979 = param_3.anisotropy;\n    _2980 = param_3.anisotropy_rotation;\n    _2981 = param_3.specular;\n    _2982 = param_3.ior;\n    _2983 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2968;\n    }\n    else\n    {\n        vec3 _2670 = _2970;\n        vec3 _2671 = normalize(_2670);\n        _2970 = _2671;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _2937, fa_world_tangent, fa_uv, fa_vertex_color, _2641, gl_FrontFacing);\n        Surface param_5 = Surface(_2968, _2969, _2671, _2971, _2972, _2973, _2974, _2975, _2976, _2977, _2978, _2979, _2980, _2981, _2982, _2983);\n        result = lighting(param_4, param_5);\n    }\n    vec3 _2686 = result;\n    vec3 _2687 = _2686 + _2974;\n    result = _2687;\n    vec3 param_6 = _2687;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2696 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        vec3 _2712 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2718 = dot(_2712, fa_mesh_fs_params[9].xyz);\n        bool _2722 = fa_mesh_fs_params[9].w > 0.5;\n        float _2723;\n        if (_2722)\n        {\n            _2723 = _2718;\n        }\n        else\n        {\n            _2723 = length(_2712);\n        }\n        float _2735 = _2723 - fa_mesh_fs_params[8].x;\n        if (_2735 > 0.0)\n        {\n            float _2744 = fa_mesh_fs_params[7].w * _2735;\n            float tau = _2744 * _2744;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2760;\n                if (_2722)\n                {\n                    _2760 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2718);\n                }\n                else\n                {\n                    _2760 = fa_mesh_fs_params[0].y;\n                }\n                float _2781 = mix(_2760, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2723, 0.0, 1.0));\n                float _2785 = fa_world_pos.y - _2781;\n                float _2790 = _2781 - fa_mesh_fs_params[8].z;\n                float _2795 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2798 = _2790 <= 0.0;\n                bool _2799 = !_2798;\n                bool _2805;\n                if (_2799)\n                {\n                    _2805 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2805 = _2798;\n                }\n                float _2806;\n                if (_2805)\n                {\n                    _2806 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2806 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2790, 80.0));\n                }\n                bool _2833;\n                if (_2799)\n                {\n                    _2833 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2833 = _2798;\n                }\n                float _2834;\n                if (_2833)\n                {\n                    _2834 = fa_mesh_fs_params[8].y * _2790;\n                }\n                else\n                {\n                    _2834 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2790, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2859 = _2795 <= 0.0;\n                bool _2866;\n                if (!_2859)\n                {\n                    _2866 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2866 = _2859;\n                }\n                float _2867;\n                if (_2866)\n                {\n                    _2867 = fa_mesh_fs_params[8].y * _2795;\n                }\n                else\n                {\n                    _2867 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2795, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2894;\n                if (abs(_2785) < 0.001000000047497451305389404296875)\n                {\n                    _2894 = _2806;\n                }\n                else\n                {\n                    _2894 = (_2867 - _2834) / _2785;\n                }\n                tau += (_2735 * max(_2894, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2969);\n}\n\n",
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
            "size": 384,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_418",
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
            "inst_name": "_654",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_2255",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    vec4 _241 = (_786 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _749 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = fa_mesh_fs_params[20].x;\n    float _755 = fa_mesh_fs_params[20].y;\n    float _758 = fa_mesh_fs_params[20].z;\n    float _757 = fa_mesh_fs_params[21].w;\n    float _760 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _749, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _754, _755, fa_mesh_fs_params[21].xyz, _757, _758, fa_mesh_fs_params[20].w, _760, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _786 = base_t;\n    _786.x = _225.x;\n    _786.y = _225.y;\n    _786.z = _225.z;\n    base_t = _786;\n    vec4 _241 = (_786 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _749 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _794 = _279;\n        _794.x = _284.x;\n        _794.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _794;\n        _749 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _797 = mrt;\n    _797.x = _313.x;\n    _797.y = _313.y;\n    _797.z = _313.z;\n    mrt = _797;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _754 = fa_mesh_fs_params[20].x;\n    float _755 = fa_mesh_fs_params[20].y;\n    float _758 = fa_mesh_fs_params[20].z;\n    float _757 = fa_mesh_fs_params[21].w;\n    float _760 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _754 *= _355.y;\n            _755 *= _355.z;\n            _757 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _758 *= mrt.x;\n            _760 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _749, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _754, _755, fa_mesh_fs_params[21].xyz, _757, _758, fa_mesh_fs_params[20].w, _760, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _660 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _660 = -_660;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _660, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
