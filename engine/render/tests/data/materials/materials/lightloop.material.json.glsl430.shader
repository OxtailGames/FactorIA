{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "194db57da3c2e45b061059a5d5aaa1ec99bea4d520978217d5e137fe8b76e503",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1554[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _447 = fa_mesh_fs_params[19].x < 0.0;\n    bool _454;\n    if (!_447)\n    {\n        _454 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _454 = _447;\n    }\n    bool _462;\n    if (!_454)\n    {\n        _462 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _462 = _454;\n    }\n    bool _469;\n    if (!_462)\n    {\n        _469 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _469 = _462;\n    }\n    bool _476;\n    if (!_469)\n    {\n        _476 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    if (_476)\n    {\n        return ivec2(0);\n    }\n    vec4 _486 = vec4(world_pos, 1.0);\n    float _493 = dot(fa_mesh_fs_params[16], _486);\n    if (!(_493 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _515 = vec2(dot(fa_mesh_fs_params[14], _486), dot(fa_mesh_fs_params[15], _486)) / vec2(_493);\n    int _519 = int(fa_mesh_fs_params[18].x);\n    int _523 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _523) + clamp(int(floor(((_515.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _523 - 1)) * _519)) + clamp(int(floor(((_515.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _519 - 1);\n    vec4 _594 = fa_light_texel(param);\n    return ivec2(int(_594.x), int(_594.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2104 = fa_cluster_lookup(param);\n    fa_cl_slot = _2104.x;\n    fa_cl_local = _2104.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2393 = fa_linear_to_srgb(param);\n        c = _2393;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2401 = fa_srgb_to_linear(param_1);\n            c = _2401;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _205;\n    if (i.front_facing)\n    {\n        _205 = i.world_normal;\n    }\n    else\n    {\n        _205 = -i.world_normal;\n    }\n    vec3 _229 = normalize(i.world_tangent.xyz - (_205 * dot(_205, i.world_tangent.xyz)));\n    vec3 _257 = normalize(((_229 * m.x) + ((cross(_205, _229) * i.world_tangent.w) * m.y)) + (_205 * m.z));\n    vec3 _260;\n    if (i.front_facing)\n    {\n        _260 = _257;\n    }\n    else\n    {\n        _260 = -_257;\n    }\n    return _260;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2432 = fa_tex_fix(param_2, param_3);\n    vec4 _3359 = base_t;\n    _3359.x = _2432.x;\n    _3359.y = _2432.y;\n    _3359.z = _2432.z;\n    base_t = _3359;\n    vec4 _2446 = (_3359 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3293 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2478 = fa_tex_fix(param_6, param_7);\n        vec3 _2482 = (_2478 * 2.0) - vec3(1.0);\n        vec2 _2487 = _2482.xy * fa_mesh_fs_params[6].x;\n        vec3 _3367 = _2482;\n        _3367.x = _2487.x;\n        _3367.y = _2487.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3367;\n        _3293 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2516 = fa_tex_fix(param_12, param_13);\n    vec4 _3370 = mrt;\n    _3370.x = _2516.x;\n    _3370.y = _2516.y;\n    _3370.z = _2516.z;\n    mrt = _3370;\n    vec4 _2544 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2544.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2556 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2586 = fa_tex_fix(param_20, param_21);\n    float _3298 = fa_mesh_fs_params[20].x;\n    float _3299 = fa_mesh_fs_params[20].y;\n    float _3302 = fa_mesh_fs_params[20].z;\n    float _3301 = fa_mesh_fs_params[21].w;\n    float _3304 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3298 *= _2556.y;\n            _3299 *= _2556.z;\n            _3301 *= _2544.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3302 *= mrt.x;\n            _3304 *= mrt.w;\n        }\n    }\n    return Surface(_2446.xyz, _2446.w, _3293, clamp(fa_mesh_fs_params[5].x * _2516.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2516.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2556.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2586), _3298, _3299, fa_mesh_fs_params[21].xyz, _3301, _3302, fa_mesh_fs_params[20].w, _3304, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _316 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _322 = fa_light_texel(param_1);\n    float _325 = _322.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _331 = _325 < 0.5;\n    vec3 l;\n    if (_331)\n    {\n        l = normalize(_316.xyz);\n    }\n    else\n    {\n        vec3 _343 = _316.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / vec3(max(_345, 9.9999997473787516355514526367188e-05));\n        float _360 = _345 / max(_316.w, 0.001000000047497451305389404296875);\n        float _366 = clamp(1.0 - (_360 * _360), 0.0, 1.0);\n        atten = _366 * _366;\n        if (_325 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _396 = fa_light_texel(param_3);\n            float _397 = _396.x;\n            float cos_inner = _397;\n            if (_397 > 1.5)\n            {\n                cos_inner = mix(_390, 1.0, 0.25);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _428;\n    if (_331)\n    {\n        _428 = 0;\n    }\n    else\n    {\n        _428 = (_325 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _322.xyz * atten, atten, 1.0, dist, _428);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2216 = n < 0;\n    bool _2223;\n    if (!_2216)\n    {\n        _2223 = n >= fa_light_count();\n    }\n    else\n    {\n        _2223 = _2216;\n    }\n    if (_2223)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _2231 = fa_cl_light(param);\n    bool _2234 = fa_lm.z > 0.5;\n    bool _2240;\n    if (_2234)\n    {\n        int param_1 = _2231;\n        _2240 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _2240 = _2234;\n    }\n    if (_2240)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _2231;\n    vec3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _668;\n    if (i == 0)\n    {\n        _668 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _684;\n        if (i == 1)\n        {\n            _684 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _692;\n            if (i == 2)\n            {\n                _692 = fa_shadows[24].z;\n            }\n            else\n            {\n                _692 = fa_shadows[24].w;\n            }\n            _684 = _692;\n        }\n        _668 = _684;\n    }\n    return _668;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _656 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_656), sin(_656)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _730 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _735 = clamp(dot(n, l), 0.0, 1.0);\n    float _741 = sqrt(1.0 - (_735 * _735));\n    float _749 = min(_741 / max(_735, 0.20000000298023223876953125), 4.0);\n    float _754;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _754 = fa_shadows[26].y;\n    }\n    else\n    {\n        _754 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _779 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_754 * _741)), 1.0);\n    float _786 = _779.x;\n    bool _789 = _786 < fa_shadows[ci * 1 + 16].x;\n    bool _798;\n    if (!_789)\n    {\n        _798 = _786 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _798 = _789;\n    }\n    bool _807;\n    if (!_798)\n    {\n        _807 = _779.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _807 = _798;\n    }\n    bool _816;\n    if (!_807)\n    {\n        _816 = _779.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _816 = _807;\n    }\n    bool _823;\n    if (!_816)\n    {\n        _823 = _779.z > 1.0;\n    }\n    else\n    {\n        _823 = _816;\n    }\n    if (_823)\n    {\n        return -1.0;\n    }\n    float _832;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _832 = fa_shadows[26].x;\n    }\n    else\n    {\n        _832 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _851 = _779.z - ((_832 * (1.0 + (0.5 * _749))) / _730);\n    float _860 = ((fa_shadows[ci * 1 + 20].x * min(_749, 3.0)) * 0.5) / _730;\n    int _869 = int(fa_shadows[25].z + 0.5);\n    if (_869 == 1)\n    {\n        vec2 param = _779.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _880 = fa_shadow_depth(param, param_1);\n        return float(_851 <= _880);\n    }\n    float _887 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _890 = _869 == 2;\n    if (_890)\n    {\n        float _904 = clamp(((fa_shadows[25].w * _730) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _887;\n            vec2 _923 = fa_shadow_vogel(param_2, param_3, param_4) * _904;\n            vec2 param_5 = _779.xy + (_923 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _934 = fa_shadow_depth(param_5, param_6);\n            if (_934 < (_851 - (length(_923) * _860)))\n            {\n                sum += _934;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_851 - (sum / cnt), 0.0) * _730) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _978 = _890 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _978; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _978;\n        float param_9 = _887;\n        vec2 _997 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _779.xy + (_997 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1008 = fa_shadow_depth(param_10, param_11);\n        lit += float((_851 - (length(_997) * _860)) <= _1008);\n    }\n    return lit / float(_978);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1038 = int(fa_shadows[25].x + 0.5);\n    if (_1038 < 1)\n    {\n        return 1.0;\n    }\n    float _1054 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1038 - 1;\n    if (_1054 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1066 = _1038 > 1;\n    bool _1073;\n    if (_1066)\n    {\n        _1073 = _1054 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1073 = _1066;\n    }\n    if (_1073)\n    {\n        ci = 1;\n    }\n    bool _1077 = _1038 > 2;\n    bool _1084;\n    if (_1077)\n    {\n        _1084 = _1054 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1084 = _1077;\n    }\n    if (_1084)\n    {\n        ci = 2;\n    }\n    bool _1088 = _1038 > 3;\n    bool _1095;\n    if (_1088)\n    {\n        _1095 = _1054 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1095 = _1088;\n    }\n    if (_1095)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1038)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1121 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1121;\n        if (_1121 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1146;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1146 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1146 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1165 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1146, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1176 = clamp((_1054 - (fa_shadow_split_at(param_7) - _1165)) / _1165, 0.0, 1.0);\n        if (_1176 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1038)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1197 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1197;\n                if (_1197 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1176);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2131 = fa_lm.z > 0.5;\n    bool _2137;\n    if (_2131)\n    {\n        int param = li;\n        _2137 = fa_light_baked(param);\n    }\n    else\n    {\n        _2137 = _2131;\n    }\n    if (_2137)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2159 = fa_light_sample(param_2, param_3);\n    vec3 _3269 = _2159.direction;\n    vec3 _3264 = _2159.color;\n    float _3266 = _2159.shadow;\n    int _3274 = _2159.type;\n    if ((_3274 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3269;\n        float _2173 = fa_shadow_factor(param_4, param_5);\n        _3266 = _2173;\n        _3264 *= _2173;\n    }\n    return LightSample(_3269, _3264, _2159.attenuation, _3266, _2159._distance, _3274);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2190 = n < 0;\n    bool _2197;\n    if (!_2190)\n    {\n        _2197 = n >= fa_light_count();\n    }\n    else\n    {\n        _2197 = _2190;\n    }\n    if (_2197)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1479 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1487 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1490 = int(_1479);\n    int _1493 = int(_1487);\n    float _1503 = _1487 - float(_1493);\n    int _1559 = (_1490 * 9) + _1493;\n    int _1579 = ((_1490 + 1) * 9) + _1493;\n    return mix(mix(_1554[_1559], _1554[_1559 + 1], _1503), mix(_1554[_1579], _1554[_1579 + 1], _1503), _1479 - float(_1490));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3130 = false;\n    float _3131 = 1.0;\n    float _3132 = 1.0;\n    float _3133 = 1.0;\n    float _3134 = 0.0;\n    float _3135 = 0.0;\n    float _3136 = 0.0;\n    float _3137 = 0.0;\n    float _3139 = 1.0;\n    bool _3140 = false;\n    vec3 _3141 = vec3(0.0);\n    float _3142 = 1.0;\n    float _3143 = 1.0;\n    float _3144 = 1.0;\n    float _3145 = 0.0;\n    float _3146 = 0.0;\n    vec3 _3147 = vec3(1.0, 0.0, 0.0);\n    vec3 _3148 = vec3(0.0, 0.0, 1.0);\n    float _3149 = 1.0;\n    float _3150 = 1.0;\n    float _1634 = clamp(s.specular, 0.0, 1.0);\n    float _1638 = clamp(s.ior, 1.0, 3.0);\n    bool _1643 = (_1634 != 1.0) || (_1638 != 1.5);\n    bool _1653;\n    if (!_1643)\n    {\n        _1653 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1653 = _1643;\n    }\n    if (_1653)\n    {\n        float _1661 = (_1638 - 1.0) / (_1638 + 1.0);\n        f0 = mix(min(vec3(_1661 * _1661) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1634, s.albedo, vec3(metallic));\n        _3131 = mix(_1634, 1.0, metallic);\n        _3130 = true;\n    }\n    float _1689 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1689 > 0.0)\n    {\n        float _1697 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3134 = _1689;\n        _3135 = _1697;\n        float _1704 = _1697 * _1697;\n        _3136 = _1704;\n        _3137 = _1704 * _1704;\n        float _1716 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3139 = _1716;\n        _3132 = 1.0 - (_1689 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1716, 0.0, 1.0), 5.0))));\n        _3130 = true;\n    }\n    vec3 _1736 = max(s.sheen_color, vec3(0.0));\n    float _1745 = max(_1736.x, max(_1736.y, _1736.z));\n    if (_1745 > 0.0)\n    {\n        float _1753 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3140 = true;\n        _3141 = _1736;\n        _3142 = _1753;\n        _3143 = _1753 * _1753;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1753;\n        float _1770 = fa_sheen_albedo(param, param_1);\n        _3145 = _1770;\n        _3144 = 1.0 - min(_1745 * _1770, 1.0);\n        _3130 = true;\n    }\n    _3133 = _3132 * _3144;\n    float _1789 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1789 != 0.0)\n    {\n        vec3 _1804 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1804;\n        if (dot(_1804, _1804) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1818 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1818.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1818.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1818.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1822 = t;\n        vec3 _1823 = normalize(_1822);\n        t = _1823;\n        vec3 _1848 = normalize((_1823 * cos(s.anisotropy_rotation)) + ((cross(n, _1823) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3147 = _1848;\n        _3148 = cross(n, _1848);\n        float _1858 = roughness * roughness;\n        float _1864 = mix(_1858, 1.0, _1789 * _1789);\n        bool _1866 = _1789 > 0.0;\n        _3149 = _1866 ? _1864 : _1858;\n        _3150 = _1866 ? _1858 : _1864;\n        _3146 = _1789;\n        _3130 = true;\n    }\n    return FaLayers(_3130, _3131, _3132, _3133, _3134, _3135, _3136, _3137, i.world_normal, _3139, _3140, _3141, _3142, _3143, _3144, _3145, _3146, _3147, _3148, _3149, _3150);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1411 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1414 = _1411.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1414 * _1414, exp2((-9.27999973297119140625) * ndv)) * _1414) + _1411.y)) + _1411.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1334 = rough * rough;\n    float _1364 = 0.60000002384185791015625 * _1334;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1334)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1364, 0.0500000007450580596923828125 + _1364, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1334 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1899;\n        if (L.aniso >= 0.0)\n        {\n            _1899 = L.b;\n        }\n        else\n        {\n            _1899 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1899, v), _1899), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1932 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1932.x) + (vec3(L.f90) * _1932.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1987 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1987.x) + _1987.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1453 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1453.x) + vec3(_1453.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2026 = clamp(s.metallic, 0.0, 1.0);\n    float _2030 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2037 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2026));\n    vec3 f0 = _2037;\n    vec3 _2041 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2041;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2026;\n    float param_5 = _2030;\n    vec3 param_6 = _2037;\n    FaLayers _2058 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2058.on)\n    {\n        FaLayers param_7 = _2058;\n        vec3 param_8 = _2041;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2030;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2041;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2030;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2278 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2278 > bestPower)\n        {\n            bestPower = _2278;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2307 = fa_light(param_2, param_3);\n        float _2315;\n        if (dot(s.normal, _2307.direction) > 0.5)\n        {\n            _2315 = 1.0;\n        }\n        else\n        {\n            _2315 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _2307.color) * _2315);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1221 = int(fa_shadows[25].x + 0.5);\n    float _1231 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1236 = _1221 > 0;\n    bool _1245;\n    if (_1236)\n    {\n        int param = _1221 - 1;\n        _1245 = _1231 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1245 = _1236;\n    }\n    if (_1245)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1252 = _1221 > 1;\n        bool _1259;\n        if (_1252)\n        {\n            _1259 = _1231 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1259 = _1252;\n        }\n        if (_1259)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1265 = _1221 > 2;\n        bool _1272;\n        if (_1265)\n        {\n            _1272 = _1231 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1272 = _1265;\n        }\n        if (_1272)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1278 = _1221 > 3;\n        bool _1285;\n        if (_1278)\n        {\n            _1285 = _1231 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1285 = _1278;\n        }\n        if (_1285)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3004 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3004 = -_3004;\n    }\n    vec3 _2707 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing);\n    Surface _2715 = fa_standard_surface(param_1);\n    vec3 _3035 = _2715.albedo;\n    float _3036 = _2715.alpha;\n    vec3 _3037 = _2715.normal;\n    float _3038 = _2715.metallic;\n    float _3039 = _2715.roughness;\n    float _3040 = _2715.occlusion;\n    vec3 _3041 = _2715.emission;\n    float _3042 = _2715.clearcoat;\n    float _3043 = _2715.clearcoat_roughness;\n    vec3 _3044 = _2715.sheen_color;\n    float _3045 = _2715.sheen_roughness;\n    float _3046 = _2715.anisotropy;\n    float _3047 = _2715.anisotropy_rotation;\n    float _3048 = _2715.specular;\n    float _3049 = _2715.ior;\n    vec3 _3050 = _2715.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing);\n    Surface param_3 = _2715;\n    surface(param_2, param_3);\n    _3035 = param_3.albedo;\n    _3036 = param_3.alpha;\n    _3037 = param_3.normal;\n    _3038 = param_3.metallic;\n    _3039 = param_3.roughness;\n    _3040 = param_3.occlusion;\n    _3041 = param_3.emission;\n    _3042 = param_3.clearcoat;\n    _3043 = param_3.clearcoat_roughness;\n    _3044 = param_3.sheen_color;\n    _3045 = param_3.sheen_roughness;\n    _3046 = param_3.anisotropy;\n    _3047 = param_3.anisotropy_rotation;\n    _3048 = param_3.specular;\n    _3049 = param_3.ior;\n    _3050 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3035;\n    }\n    else\n    {\n        vec3 _2736 = _3037;\n        vec3 _2737 = normalize(_2736);\n        _3037 = _2737;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing);\n        Surface param_5 = Surface(_3035, _3036, _2737, _3038, _3039, _3040, _3041, _3042, _3043, _3044, _3045, _3046, _3047, _3048, _3049, _3050);\n        result = lighting(param_4, param_5);\n    }\n    vec3 _2752 = result;\n    vec3 _2753 = _2752 + _3041;\n    result = _2753;\n    vec3 param_6 = _2753;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2762 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2769;\n    if (!_2762)\n    {\n        _2769 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2769 = _2762;\n    }\n    if (_2769)\n    {\n        vec3 _2778 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2784 = dot(_2778, fa_mesh_fs_params[9].xyz);\n        bool _2788 = fa_mesh_fs_params[9].w > 0.5;\n        float _2789;\n        if (_2788)\n        {\n            _2789 = _2784;\n        }\n        else\n        {\n            _2789 = length(_2778);\n        }\n        float _2801 = _2789 - fa_mesh_fs_params[8].x;\n        if (_2801 > 0.0)\n        {\n            float _2810 = fa_mesh_fs_params[7].w * _2801;\n            float tau = _2810 * _2810;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2826;\n                if (_2788)\n                {\n                    _2826 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2784);\n                }\n                else\n                {\n                    _2826 = fa_mesh_fs_params[0].y;\n                }\n                float _2847 = mix(_2826, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2789, 0.0, 1.0));\n                float _2851 = fa_world_pos.y - _2847;\n                float _2856 = _2847 - fa_mesh_fs_params[8].z;\n                float _2861 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2864 = _2856 <= 0.0;\n                bool _2865 = !_2864;\n                bool _2871;\n                if (_2865)\n                {\n                    _2871 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2871 = _2864;\n                }\n                float _2872;\n                if (_2871)\n                {\n                    _2872 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2872 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2856, 80.0));\n                }\n                bool _2899;\n                if (_2865)\n                {\n                    _2899 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2899 = _2864;\n                }\n                float _2900;\n                if (_2899)\n                {\n                    _2900 = fa_mesh_fs_params[8].y * _2856;\n                }\n                else\n                {\n                    _2900 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2856, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2925 = _2861 <= 0.0;\n                bool _2932;\n                if (!_2925)\n                {\n                    _2932 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2932 = _2925;\n                }\n                float _2933;\n                if (_2932)\n                {\n                    _2933 = fa_mesh_fs_params[8].y * _2861;\n                }\n                else\n                {\n                    _2933 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2861, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2960;\n                if (abs(_2851) < 0.001000000047497451305389404296875)\n                {\n                    _2960 = _2872;\n                }\n                else\n                {\n                    _2960 = (_2933 - _2900) / _2851;\n                }\n                tau += (_2801 * max(_2960, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3036);\n}\n\n",
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
            "inst_name": "_442",
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
            "inst_name": "_678",
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
            "inst_name": "_2321",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1554[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _447 = fa_mesh_fs_params[19].x < 0.0;\n    bool _454;\n    if (!_447)\n    {\n        _454 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _454 = _447;\n    }\n    bool _462;\n    if (!_454)\n    {\n        _462 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _462 = _454;\n    }\n    bool _469;\n    if (!_462)\n    {\n        _469 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _469 = _462;\n    }\n    bool _476;\n    if (!_469)\n    {\n        _476 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _476 = _469;\n    }\n    if (_476)\n    {\n        return ivec2(0);\n    }\n    vec4 _486 = vec4(world_pos, 1.0);\n    float _493 = dot(fa_mesh_fs_params[16], _486);\n    if (!(_493 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _515 = vec2(dot(fa_mesh_fs_params[14], _486), dot(fa_mesh_fs_params[15], _486)) / vec2(_493);\n    int _519 = int(fa_mesh_fs_params[18].x);\n    int _523 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _523) + clamp(int(floor(((_515.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _523 - 1)) * _519)) + clamp(int(floor(((_515.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _519 - 1);\n    vec4 _594 = fa_light_texel(param);\n    return ivec2(int(_594.x), int(_594.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2104 = fa_cluster_lookup(param);\n    fa_cl_slot = _2104.x;\n    fa_cl_local = _2104.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2393 = fa_linear_to_srgb(param);\n        c = _2393;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2401 = fa_srgb_to_linear(param_1);\n            c = _2401;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _205;\n    if (i.front_facing)\n    {\n        _205 = i.world_normal;\n    }\n    else\n    {\n        _205 = -i.world_normal;\n    }\n    vec3 _229 = normalize(i.world_tangent.xyz - (_205 * dot(_205, i.world_tangent.xyz)));\n    vec3 _257 = normalize(((_229 * m.x) + ((cross(_205, _229) * i.world_tangent.w) * m.y)) + (_205 * m.z));\n    vec3 _260;\n    if (i.front_facing)\n    {\n        _260 = _257;\n    }\n    else\n    {\n        _260 = -_257;\n    }\n    return _260;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2432 = fa_tex_fix(param_2, param_3);\n    vec4 _3359 = base_t;\n    _3359.x = _2432.x;\n    _3359.y = _2432.y;\n    _3359.z = _2432.z;\n    base_t = _3359;\n    vec4 _2446 = (_3359 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3293 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2478 = fa_tex_fix(param_6, param_7);\n        vec3 _2482 = (_2478 * 2.0) - vec3(1.0);\n        vec2 _2487 = _2482.xy * fa_mesh_fs_params[6].x;\n        vec3 _3367 = _2482;\n        _3367.x = _2487.x;\n        _3367.y = _2487.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3367;\n        _3293 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2516 = fa_tex_fix(param_12, param_13);\n    vec4 _3370 = mrt;\n    _3370.x = _2516.x;\n    _3370.y = _2516.y;\n    _3370.z = _2516.z;\n    mrt = _3370;\n    vec4 _2544 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2544.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2556 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2586 = fa_tex_fix(param_20, param_21);\n    float _3298 = fa_mesh_fs_params[20].x;\n    float _3299 = fa_mesh_fs_params[20].y;\n    float _3302 = fa_mesh_fs_params[20].z;\n    float _3301 = fa_mesh_fs_params[21].w;\n    float _3304 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3298 *= _2556.y;\n            _3299 *= _2556.z;\n            _3301 *= _2544.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3302 *= mrt.x;\n            _3304 *= mrt.w;\n        }\n    }\n    return Surface(_2446.xyz, _2446.w, _3293, clamp(fa_mesh_fs_params[5].x * _2516.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2516.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2556.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2586), _3298, _3299, fa_mesh_fs_params[21].xyz, _3301, _3302, fa_mesh_fs_params[20].w, _3304, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _316 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _322 = fa_light_texel(param_1);\n    float _325 = _322.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _331 = _325 < 0.5;\n    vec3 l;\n    if (_331)\n    {\n        l = normalize(_316.xyz);\n    }\n    else\n    {\n        vec3 _343 = _316.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / vec3(max(_345, 9.9999997473787516355514526367188e-05));\n        float _360 = _345 / max(_316.w, 0.001000000047497451305389404296875);\n        float _366 = clamp(1.0 - (_360 * _360), 0.0, 1.0);\n        atten = _366 * _366;\n        if (_325 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _396 = fa_light_texel(param_3);\n            float _397 = _396.x;\n            float cos_inner = _397;\n            if (_397 > 1.5)\n            {\n                cos_inner = mix(_390, 1.0, 0.25);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _428;\n    if (_331)\n    {\n        _428 = 0;\n    }\n    else\n    {\n        _428 = (_325 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _322.xyz * atten, atten, 1.0, dist, _428);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2216 = n < 0;\n    bool _2223;\n    if (!_2216)\n    {\n        _2223 = n >= fa_light_count();\n    }\n    else\n    {\n        _2223 = _2216;\n    }\n    if (_2223)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _2231 = fa_cl_light(param);\n    bool _2234 = fa_lm.z > 0.5;\n    bool _2240;\n    if (_2234)\n    {\n        int param_1 = _2231;\n        _2240 = fa_light_baked(param_1);\n    }\n    else\n    {\n        _2240 = _2234;\n    }\n    if (_2240)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _2231;\n    vec3 param_3 = i.world_pos;\n    return fa_light_sample(param_2, param_3);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _668;\n    if (i == 0)\n    {\n        _668 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _684;\n        if (i == 1)\n        {\n            _684 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _692;\n            if (i == 2)\n            {\n                _692 = fa_shadows[24].z;\n            }\n            else\n            {\n                _692 = fa_shadows[24].w;\n            }\n            _684 = _692;\n        }\n        _668 = _684;\n    }\n    return _668;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _656 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_656), sin(_656)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _730 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _735 = clamp(dot(n, l), 0.0, 1.0);\n    float _741 = sqrt(1.0 - (_735 * _735));\n    float _749 = min(_741 / max(_735, 0.20000000298023223876953125), 4.0);\n    float _754;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _754 = fa_shadows[26].y;\n    }\n    else\n    {\n        _754 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _779 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_754 * _741)), 1.0);\n    float _786 = _779.x;\n    bool _789 = _786 < fa_shadows[ci * 1 + 16].x;\n    bool _798;\n    if (!_789)\n    {\n        _798 = _786 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _798 = _789;\n    }\n    bool _807;\n    if (!_798)\n    {\n        _807 = _779.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _807 = _798;\n    }\n    bool _816;\n    if (!_807)\n    {\n        _816 = _779.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _816 = _807;\n    }\n    bool _823;\n    if (!_816)\n    {\n        _823 = _779.z > 1.0;\n    }\n    else\n    {\n        _823 = _816;\n    }\n    if (_823)\n    {\n        return -1.0;\n    }\n    float _832;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _832 = fa_shadows[26].x;\n    }\n    else\n    {\n        _832 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _851 = _779.z - ((_832 * (1.0 + (0.5 * _749))) / _730);\n    float _860 = ((fa_shadows[ci * 1 + 20].x * min(_749, 3.0)) * 0.5) / _730;\n    int _869 = int(fa_shadows[25].z + 0.5);\n    if (_869 == 1)\n    {\n        vec2 param = _779.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _880 = fa_shadow_depth(param, param_1);\n        return float(_851 <= _880);\n    }\n    float _887 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _890 = _869 == 2;\n    if (_890)\n    {\n        float _904 = clamp(((fa_shadows[25].w * _730) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _887;\n            vec2 _923 = fa_shadow_vogel(param_2, param_3, param_4) * _904;\n            vec2 param_5 = _779.xy + (_923 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _934 = fa_shadow_depth(param_5, param_6);\n            if (_934 < (_851 - (length(_923) * _860)))\n            {\n                sum += _934;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_851 - (sum / cnt), 0.0) * _730) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _978 = _890 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _978; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _978;\n        float param_9 = _887;\n        vec2 _997 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _779.xy + (_997 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1008 = fa_shadow_depth(param_10, param_11);\n        lit += float((_851 - (length(_997) * _860)) <= _1008);\n    }\n    return lit / float(_978);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1038 = int(fa_shadows[25].x + 0.5);\n    if (_1038 < 1)\n    {\n        return 1.0;\n    }\n    float _1054 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1038 - 1;\n    if (_1054 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1066 = _1038 > 1;\n    bool _1073;\n    if (_1066)\n    {\n        _1073 = _1054 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1073 = _1066;\n    }\n    if (_1073)\n    {\n        ci = 1;\n    }\n    bool _1077 = _1038 > 2;\n    bool _1084;\n    if (_1077)\n    {\n        _1084 = _1054 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1084 = _1077;\n    }\n    if (_1084)\n    {\n        ci = 2;\n    }\n    bool _1088 = _1038 > 3;\n    bool _1095;\n    if (_1088)\n    {\n        _1095 = _1054 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1095 = _1088;\n    }\n    if (_1095)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1038)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1121 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1121;\n        if (_1121 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1146;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1146 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1146 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1165 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1146, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1176 = clamp((_1054 - (fa_shadow_split_at(param_7) - _1165)) / _1165, 0.0, 1.0);\n        if (_1176 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1038)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1197 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1197;\n                if (_1197 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1176);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _2131 = fa_lm.z > 0.5;\n    bool _2137;\n    if (_2131)\n    {\n        int param = li;\n        _2137 = fa_light_baked(param);\n    }\n    else\n    {\n        _2137 = _2131;\n    }\n    if (_2137)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _2159 = fa_light_sample(param_2, param_3);\n    vec3 _3269 = _2159.direction;\n    vec3 _3264 = _2159.color;\n    float _3266 = _2159.shadow;\n    int _3274 = _2159.type;\n    if ((_3274 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _3269;\n        float _2173 = fa_shadow_factor(param_4, param_5);\n        _3266 = _2173;\n        _3264 *= _2173;\n    }\n    return LightSample(_3269, _3264, _2159.attenuation, _3266, _2159._distance, _3274);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2190 = n < 0;\n    bool _2197;\n    if (!_2190)\n    {\n        _2197 = n >= fa_light_count();\n    }\n    else\n    {\n        _2197 = _2190;\n    }\n    if (_2197)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1479 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1487 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1490 = int(_1479);\n    int _1493 = int(_1487);\n    float _1503 = _1487 - float(_1493);\n    int _1559 = (_1490 * 9) + _1493;\n    int _1579 = ((_1490 + 1) * 9) + _1493;\n    return mix(mix(_1554[_1559], _1554[_1559 + 1], _1503), mix(_1554[_1579], _1554[_1579 + 1], _1503), _1479 - float(_1490));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3130 = false;\n    float _3131 = 1.0;\n    float _3132 = 1.0;\n    float _3133 = 1.0;\n    float _3134 = 0.0;\n    float _3135 = 0.0;\n    float _3136 = 0.0;\n    float _3137 = 0.0;\n    float _3139 = 1.0;\n    bool _3140 = false;\n    vec3 _3141 = vec3(0.0);\n    float _3142 = 1.0;\n    float _3143 = 1.0;\n    float _3144 = 1.0;\n    float _3145 = 0.0;\n    float _3146 = 0.0;\n    vec3 _3147 = vec3(1.0, 0.0, 0.0);\n    vec3 _3148 = vec3(0.0, 0.0, 1.0);\n    float _3149 = 1.0;\n    float _3150 = 1.0;\n    float _1634 = clamp(s.specular, 0.0, 1.0);\n    float _1638 = clamp(s.ior, 1.0, 3.0);\n    bool _1643 = (_1634 != 1.0) || (_1638 != 1.5);\n    bool _1653;\n    if (!_1643)\n    {\n        _1653 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _1653 = _1643;\n    }\n    if (_1653)\n    {\n        float _1661 = (_1638 - 1.0) / (_1638 + 1.0);\n        f0 = mix(min(vec3(_1661 * _1661) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _1634, s.albedo, vec3(metallic));\n        _3131 = mix(_1634, 1.0, metallic);\n        _3130 = true;\n    }\n    float _1689 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_1689 > 0.0)\n    {\n        float _1697 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3134 = _1689;\n        _3135 = _1697;\n        float _1704 = _1697 * _1697;\n        _3136 = _1704;\n        _3137 = _1704 * _1704;\n        float _1716 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3139 = _1716;\n        _3132 = 1.0 - (_1689 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _1716, 0.0, 1.0), 5.0))));\n        _3130 = true;\n    }\n    vec3 _1736 = max(s.sheen_color, vec3(0.0));\n    float _1745 = max(_1736.x, max(_1736.y, _1736.z));\n    if (_1745 > 0.0)\n    {\n        float _1753 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3140 = true;\n        _3141 = _1736;\n        _3142 = _1753;\n        _3143 = _1753 * _1753;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _1753;\n        float _1770 = fa_sheen_albedo(param, param_1);\n        _3145 = _1770;\n        _3144 = 1.0 - min(_1745 * _1770, 1.0);\n        _3130 = true;\n    }\n    _3133 = _3132 * _3144;\n    float _1789 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_1789 != 0.0)\n    {\n        vec3 _1804 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _1804;\n        if (dot(_1804, _1804) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _1818 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_1818.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _1818.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _1818.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _1822 = t;\n        vec3 _1823 = normalize(_1822);\n        t = _1823;\n        vec3 _1848 = normalize((_1823 * cos(s.anisotropy_rotation)) + ((cross(n, _1823) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3147 = _1848;\n        _3148 = cross(n, _1848);\n        float _1858 = roughness * roughness;\n        float _1864 = mix(_1858, 1.0, _1789 * _1789);\n        bool _1866 = _1789 > 0.0;\n        _3149 = _1866 ? _1864 : _1858;\n        _3150 = _1866 ? _1858 : _1864;\n        _3146 = _1789;\n        _3130 = true;\n    }\n    return FaLayers(_3130, _3131, _3132, _3133, _3134, _3135, _3136, _3137, i.world_normal, _3139, _3140, _3141, _3142, _3143, _3144, _3145, _3146, _3147, _3148, _3149, _3150);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1411 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1414 = _1411.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1414 * _1414, exp2((-9.27999973297119140625) * ndv)) * _1414) + _1411.y)) + _1411.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1334 = rough * rough;\n    float _1364 = 0.60000002384185791015625 * _1334;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1334)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1364, 0.0500000007450580596923828125 + _1364, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1334 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _1899;\n        if (L.aniso >= 0.0)\n        {\n            _1899 = L.b;\n        }\n        else\n        {\n            _1899 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_1899, v), _1899), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1932 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _1932.x) + (vec3(L.f90) * _1932.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _1987 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _1987.x) + _1987.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1453 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1453.x) + vec3(_1453.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2026 = clamp(s.metallic, 0.0, 1.0);\n    float _2030 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2037 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2026));\n    vec3 f0 = _2037;\n    vec3 _2041 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2041;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2026;\n    float param_5 = _2030;\n    vec3 param_6 = _2037;\n    FaLayers _2058 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2058.on)\n    {\n        FaLayers param_7 = _2058;\n        vec3 param_8 = _2041;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2030;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2041;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2030;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2278 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2278 > bestPower)\n        {\n            bestPower = _2278;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2307 = fa_light(param_2, param_3);\n        float _2315;\n        if (dot(s.normal, _2307.direction) > 0.5)\n        {\n            _2315 = 1.0;\n        }\n        else\n        {\n            _2315 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _2307.color) * _2315);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1221 = int(fa_shadows[25].x + 0.5);\n    float _1231 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1236 = _1221 > 0;\n    bool _1245;\n    if (_1236)\n    {\n        int param = _1221 - 1;\n        _1245 = _1231 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1245 = _1236;\n    }\n    if (_1245)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1252 = _1221 > 1;\n        bool _1259;\n        if (_1252)\n        {\n            _1259 = _1231 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1259 = _1252;\n        }\n        if (_1259)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1265 = _1221 > 2;\n        bool _1272;\n        if (_1265)\n        {\n            _1272 = _1231 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1272 = _1265;\n        }\n        if (_1272)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1278 = _1221 > 3;\n        bool _1285;\n        if (_1278)\n        {\n            _1285 = _1231 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1285 = _1278;\n        }\n        if (_1285)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3004 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3004 = -_3004;\n    }\n    vec3 _2707 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing);\n    Surface _2715 = fa_standard_surface(param_1);\n    vec3 _3035 = _2715.albedo;\n    float _3036 = _2715.alpha;\n    vec3 _3037 = _2715.normal;\n    float _3038 = _2715.metallic;\n    float _3039 = _2715.roughness;\n    float _3040 = _2715.occlusion;\n    vec3 _3041 = _2715.emission;\n    float _3042 = _2715.clearcoat;\n    float _3043 = _2715.clearcoat_roughness;\n    vec3 _3044 = _2715.sheen_color;\n    float _3045 = _2715.sheen_roughness;\n    float _3046 = _2715.anisotropy;\n    float _3047 = _2715.anisotropy_rotation;\n    float _3048 = _2715.specular;\n    float _3049 = _2715.ior;\n    vec3 _3050 = _2715.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing);\n    Surface param_3 = _2715;\n    surface(param_2, param_3);\n    _3035 = param_3.albedo;\n    _3036 = param_3.alpha;\n    _3037 = param_3.normal;\n    _3038 = param_3.metallic;\n    _3039 = param_3.roughness;\n    _3040 = param_3.occlusion;\n    _3041 = param_3.emission;\n    _3042 = param_3.clearcoat;\n    _3043 = param_3.clearcoat_roughness;\n    _3044 = param_3.sheen_color;\n    _3045 = param_3.sheen_roughness;\n    _3046 = param_3.anisotropy;\n    _3047 = param_3.anisotropy_rotation;\n    _3048 = param_3.specular;\n    _3049 = param_3.ior;\n    _3050 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3035;\n    }\n    else\n    {\n        vec3 _2736 = _3037;\n        vec3 _2737 = normalize(_2736);\n        _3037 = _2737;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3004, fa_world_tangent, fa_uv, fa_vertex_color, _2707, gl_FrontFacing);\n        Surface param_5 = Surface(_3035, _3036, _2737, _3038, _3039, _3040, _3041, _3042, _3043, _3044, _3045, _3046, _3047, _3048, _3049, _3050);\n        result = lighting(param_4, param_5);\n    }\n    vec3 _2752 = result;\n    vec3 _2753 = _2752 + _3041;\n    result = _2753;\n    vec3 param_6 = _2753;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _2762 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2769;\n    if (!_2762)\n    {\n        _2769 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2769 = _2762;\n    }\n    if (_2769)\n    {\n        vec3 _2778 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2784 = dot(_2778, fa_mesh_fs_params[9].xyz);\n        bool _2788 = fa_mesh_fs_params[9].w > 0.5;\n        float _2789;\n        if (_2788)\n        {\n            _2789 = _2784;\n        }\n        else\n        {\n            _2789 = length(_2778);\n        }\n        float _2801 = _2789 - fa_mesh_fs_params[8].x;\n        if (_2801 > 0.0)\n        {\n            float _2810 = fa_mesh_fs_params[7].w * _2801;\n            float tau = _2810 * _2810;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2826;\n                if (_2788)\n                {\n                    _2826 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2784);\n                }\n                else\n                {\n                    _2826 = fa_mesh_fs_params[0].y;\n                }\n                float _2847 = mix(_2826, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2789, 0.0, 1.0));\n                float _2851 = fa_world_pos.y - _2847;\n                float _2856 = _2847 - fa_mesh_fs_params[8].z;\n                float _2861 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2864 = _2856 <= 0.0;\n                bool _2865 = !_2864;\n                bool _2871;\n                if (_2865)\n                {\n                    _2871 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2871 = _2864;\n                }\n                float _2872;\n                if (_2871)\n                {\n                    _2872 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2872 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2856, 80.0));\n                }\n                bool _2899;\n                if (_2865)\n                {\n                    _2899 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2899 = _2864;\n                }\n                float _2900;\n                if (_2899)\n                {\n                    _2900 = fa_mesh_fs_params[8].y * _2856;\n                }\n                else\n                {\n                    _2900 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2856, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2925 = _2861 <= 0.0;\n                bool _2932;\n                if (!_2925)\n                {\n                    _2932 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2932 = _2925;\n                }\n                float _2933;\n                if (_2932)\n                {\n                    _2933 = fa_mesh_fs_params[8].y * _2861;\n                }\n                else\n                {\n                    _2933 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2861, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2960;\n                if (abs(_2851) < 0.001000000047497451305389404296875)\n                {\n                    _2960 = _2872;\n                }\n                else\n                {\n                    _2960 = (_2933 - _2900) / _2851;\n                }\n                tau += (_2801 * max(_2960, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3036);\n}\n\n",
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
            "inst_name": "_442",
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
            "inst_name": "_678",
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
            "inst_name": "_2321",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
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
