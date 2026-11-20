{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1938[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _448 = fa_mesh_fs_params[19].x < 0.0;\n    bool _455;\n    if (!_448)\n    {\n        _455 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _455 = _448;\n    }\n    bool _463;\n    if (!_455)\n    {\n        _463 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _463 = _455;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _477;\n    if (!_470)\n    {\n        _477 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    if (_477)\n    {\n        return ivec2(0);\n    }\n    vec4 _487 = vec4(world_pos, 1.0);\n    float _494 = dot(fa_mesh_fs_params[16], _487);\n    if (!(_494 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _516 = vec2(dot(fa_mesh_fs_params[14], _487), dot(fa_mesh_fs_params[15], _487)) / vec2(_494);\n    int _520 = int(fa_mesh_fs_params[18].x);\n    int _524 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _524) + clamp(int(floor(((_516.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _524 - 1)) * _520)) + clamp(int(floor(((_516.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _520 - 1);\n    vec4 _595 = fa_light_texel(param);\n    return ivec2(int(_595.x), int(_595.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2486 = fa_cluster_lookup(param);\n    fa_cl_slot = _2486.x;\n    fa_cl_local = _2486.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2762 = fa_linear_to_srgb(param);\n        c = _2762;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2770 = fa_srgb_to_linear(param_1);\n            c = _2770;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _223;\n    if (i.front_facing)\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    vec3 _247 = normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    vec3 _275 = normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    vec3 _278;\n    if (i.front_facing)\n    {\n        _278 = _275;\n    }\n    else\n    {\n        _278 = -_275;\n    }\n    return _278;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2801 = fa_tex_fix(param_2, param_3);\n    vec4 _3746 = base_t;\n    _3746.x = _2801.x;\n    _3746.y = _2801.y;\n    _3746.z = _2801.z;\n    base_t = _3746;\n    vec4 _2815 = (_3746 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3648 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2847 = fa_tex_fix(param_6, param_7);\n        vec3 _2851 = (_2847 * 2.0) - vec3(1.0);\n        vec2 _2856 = _2851.xy * fa_mesh_fs_params[6].x;\n        vec3 _3754 = _2851;\n        _3754.x = _2856.x;\n        _3754.y = _2856.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3754;\n        _3648 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2885 = fa_tex_fix(param_12, param_13);\n    vec4 _3757 = mrt;\n    _3757.x = _2885.x;\n    _3757.y = _2885.y;\n    _3757.z = _2885.z;\n    mrt = _3757;\n    vec4 _2913 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2913.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2925 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2955 = fa_tex_fix(param_20, param_21);\n    float _3653 = fa_mesh_fs_params[20].x;\n    float _3654 = fa_mesh_fs_params[20].y;\n    float _3657 = fa_mesh_fs_params[20].z;\n    float _3656 = fa_mesh_fs_params[21].w;\n    float _3659 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3653 *= _2925.y;\n            _3654 *= _2925.z;\n            _3656 *= _2913.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3657 *= mrt.x;\n            _3659 *= mrt.w;\n        }\n    }\n    return Surface(_2815.xyz, _2815.w, _3648, clamp(fa_mesh_fs_params[5].x * _2885.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2885.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2925.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2955), _3653, _3654, fa_mesh_fs_params[21].xyz, _3656, _3657, fa_mesh_fs_params[20].w, _3659, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _315 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _321 = fa_light_texel(param_1);\n    float _324 = _321.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _331 = _324 < 0.5;\n    vec3 l;\n    if (_331)\n    {\n        l = normalize(_315.xyz);\n    }\n    else\n    {\n        vec3 _343 = _315.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / vec3(max(_345, 9.9999997473787516355514526367188e-05));\n        float _360 = _345 / max(_315.w, 0.001000000047497451305389404296875);\n        float _366 = clamp(1.0 - (_360 * _360), 0.0, 1.0);\n        atten = _366 * _366;\n        if (_324 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _397 = fa_light_texel(param_3);\n            float _398 = _397.x;\n            float cos_inner = _398;\n            if (_398 > 1.5)\n            {\n                cos_inner = mix(_390, 1.0, 0.25);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _429;\n    if (_331)\n    {\n        _429 = 0;\n    }\n    else\n    {\n        _429 = (_324 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _321.xyz * atten, atten, 1.0, dist, _429);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2600 = n < 0;\n    bool _2607;\n    if (!_2600)\n    {\n        _2607 = n >= fa_light_count();\n    }\n    else\n    {\n        _2607 = _2600;\n    }\n    if (_2607)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _669;\n    if (i == 0)\n    {\n        _669 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _685;\n        if (i == 1)\n        {\n            _685 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _693;\n            if (i == 2)\n            {\n                _693 = fa_shadows[24].z;\n            }\n            else\n            {\n                _693 = fa_shadows[24].w;\n            }\n            _685 = _693;\n        }\n        _669 = _685;\n    }\n    return _669;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _726 = fa_shadow_depth(param, param_1);\n    float _730;\n    if (conv.x < 0.5)\n    {\n        _730 = _726;\n    }\n    else\n    {\n        _730 = (conv.y * conv.z) / (conv.z - (_726 * (conv.z - conv.y)));\n    }\n    return _730;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _657 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_657), sin(_657)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _776 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _790 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _776;\n            vec2 _809 = fa_shadow_vogel(param_3, param_4, param_5) * _790;\n            vec2 param_6 = uv + (_809 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _821 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_821 < (zr - (length(_809) * plane)))\n            {\n                sum += _821;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _865 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _865; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _865;\n        float param_11 = _776;\n        vec2 _884 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_884 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_884) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_865);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _926 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _931 = clamp(dot(n, l), 0.0, 1.0);\n    float _937 = sqrt(1.0 - (_931 * _931));\n    float _945 = min(_937 / max(_931, 0.20000000298023223876953125), 4.0);\n    float _950;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _950 = fa_shadows[26].y;\n    }\n    else\n    {\n        _950 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _975 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_950 * _937)), 1.0);\n    float _982 = _975.x;\n    bool _985 = _982 < fa_shadows[ci * 1 + 16].x;\n    bool _994;\n    if (!_985)\n    {\n        _994 = _982 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _994 = _985;\n    }\n    bool _1003;\n    if (!_994)\n    {\n        _1003 = _975.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1003 = _994;\n    }\n    bool _1012;\n    if (!_1003)\n    {\n        _1012 = _975.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1012 = _1003;\n    }\n    bool _1019;\n    if (!_1012)\n    {\n        _1019 = _975.z > 1.0;\n    }\n    else\n    {\n        _1019 = _1012;\n    }\n    if (_1019)\n    {\n        return -1.0;\n    }\n    float _1028;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1028 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1028 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _975.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _975.z - ((_1028 * (1.0 + (0.5 * _945))) / _926);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _926;\n    float param_5 = _926 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_945, 3.0)) * 0.5) / _926;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1422 = int(fa_shadows[25].x + 0.5);\n    if (_1422 < 1)\n    {\n        return 1.0;\n    }\n    float _1438 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1422 - 1;\n    if (_1438 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1450 = _1422 > 1;\n    bool _1457;\n    if (_1450)\n    {\n        _1457 = _1438 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1457 = _1450;\n    }\n    if (_1457)\n    {\n        ci = 1;\n    }\n    bool _1461 = _1422 > 2;\n    bool _1468;\n    if (_1461)\n    {\n        _1468 = _1438 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1468 = _1461;\n    }\n    if (_1468)\n    {\n        ci = 2;\n    }\n    bool _1472 = _1422 > 3;\n    bool _1479;\n    if (_1472)\n    {\n        _1479 = _1438 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1479 = _1472;\n    }\n    if (_1479)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1422)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1505 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1505;\n        if (_1505 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1530;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1530 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1530 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1549 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1530, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1560 = clamp((_1438 - (fa_shadow_split_at(param_7) - _1549)) / _1549, 0.0, 1.0);\n        if (_1560 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1422)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1581 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1581;\n                if (_1581 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1560);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1087 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1095;\n    if (!_1087)\n    {\n        _1095 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1095 = _1087;\n    }\n    if (_1095)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1108 = fa_light_texel(param);\n    float _1109 = _1108.x;\n    if (_1109 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1118 = int(_1109 + 0.5);\n    int param_1 = _1118;\n    vec4 _1122 = fa_light_texel(param_1);\n    int param_2 = _1118 + 1;\n    vec4 _1127 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1130 = _1122.y;\n    if (_1130 > 0.0)\n    {\n        float _1147 = 1.0 - smoothstep(0.75 * _1130, _1130, length(world - fa_shadows[27].xyz));\n        fade = _1147;\n        if (_1147 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1122.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1166 = world - fa_light_texel(param_3).xyz;\n        vec3 _1169 = abs(_1166);\n        float _1171 = _1169.x;\n        float _1173 = _1169.y;\n        bool _1174 = _1171 >= _1173;\n        bool _1182;\n        if (_1174)\n        {\n            _1182 = _1171 >= _1169.z;\n        }\n        else\n        {\n            _1182 = _1174;\n        }\n        int _1183;\n        if (_1182)\n        {\n            _1183 = (_1166.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1196;\n            if (_1173 >= _1169.z)\n            {\n                _1196 = (_1166.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1196 = (_1166.z > 0.0) ? 4 : 5;\n            }\n            _1183 = _1196;\n        }\n        face = _1183;\n    }\n    int _1215 = (_1118 + 2) + (face * 6);\n    int param_4 = _1215;\n    int param_5 = _1215 + 1;\n    int param_6 = _1215 + 3;\n    vec4 _1229 = fa_light_texel(param_6);\n    int param_7 = _1215 + 4;\n    vec4 _1234 = fa_light_texel(param_7);\n    int param_8 = _1215 + 5;\n    vec4 _1239 = fa_light_texel(param_8);\n    float _1251 = _1239.x * max(dot(_1229, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1256 = clamp(dot(n, l), 0.0, 1.0);\n    float _1262 = sqrt(1.0 - (_1256 * _1256));\n    float _1268 = min(_1262 / max(_1256, 0.20000000298023223876953125), 4.0);\n    float _1271 = _1127.y;\n    float _1273;\n    if (_1271 > 0.0)\n    {\n        _1273 = _1271;\n    }\n    else\n    {\n        _1273 = 1.5 * _1251;\n    }\n    vec4 _1293 = vec4(world + (n * (_1273 * _1262)), 1.0);\n    float _1297 = dot(_1229, _1293);\n    float _1300 = _1239.y;\n    if (_1297 < _1300)\n    {\n        return 1.0;\n    }\n    vec2 _1315 = vec2(dot(fa_light_texel(param_4), _1293), dot(fa_light_texel(param_5), _1293)) / vec2(_1297);\n    float _1317 = _1315.x;\n    bool _1320 = _1317 < _1234.x;\n    bool _1329;\n    if (!_1320)\n    {\n        _1329 = _1317 > _1234.z;\n    }\n    else\n    {\n        _1329 = _1320;\n    }\n    bool _1338;\n    if (!_1329)\n    {\n        _1338 = _1315.y < _1234.y;\n    }\n    else\n    {\n        _1338 = _1329;\n    }\n    bool _1347;\n    if (!_1338)\n    {\n        _1347 = _1315.y > _1234.w;\n    }\n    else\n    {\n        _1347 = _1338;\n    }\n    if (_1347)\n    {\n        return 1.0;\n    }\n    float _1353 = _1127.x;\n    float _1355;\n    if (_1353 > 0.0)\n    {\n        _1355 = _1353;\n    }\n    else\n    {\n        _1355 = 1.5 * _1251;\n    }\n    vec2 param_9 = _1315;\n    vec4 param_10 = _1234;\n    float param_11 = _1297 - (_1355 * (1.0 + (0.5 * _1268)));\n    float param_12 = _1251;\n    float param_13 = 1.0;\n    float param_14 = _1239.z * 0.25;\n    float param_15 = (_1251 * min(_1268, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1300, _1239.z);\n    int param_17 = int(_1122.z + 0.5);\n    float param_18 = _1122.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2514 = fa_light_sample(param, param_1);\n    vec3 _3624 = _2514.direction;\n    vec3 _3619 = _2514.color;\n    float _3626 = _2514.attenuation;\n    float _3621 = _2514.shadow;\n    int _3629 = _2514.type;\n    if ((_3629 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _3624;\n        float _2528 = fa_shadow_factor(param_2, param_3);\n        _3621 = _2528;\n        _3619 *= _2528;\n    }\n    else\n    {\n        bool _2539 = _3629 != 0;\n        bool _2545;\n        if (_2539)\n        {\n            _2545 = _3626 > 0.0;\n        }\n        else\n        {\n            _2545 = _2539;\n        }\n        if (_2545)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _3624;\n            float _2557 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _3621 = _2557;\n            _3619 *= _2557;\n        }\n    }\n    return LightSample(_3624, _3619, _3626, _3621, _2514._distance, _3629);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2574 = n < 0;\n    bool _2581;\n    if (!_2574)\n    {\n        _2581 = n >= fa_light_count();\n    }\n    else\n    {\n        _2581 = _2574;\n    }\n    if (_2581)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1863 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1871 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1874 = int(_1863);\n    int _1877 = int(_1871);\n    float _1887 = _1871 - float(_1877);\n    int _1943 = (_1874 * 9) + _1877;\n    int _1963 = ((_1874 + 1) * 9) + _1877;\n    return mix(mix(_1938[_1943], _1938[_1943 + 1], _1887), mix(_1938[_1963], _1938[_1963 + 1], _1887), _1863 - float(_1874));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3498 = false;\n    float _3499 = 1.0;\n    float _3500 = 1.0;\n    float _3501 = 1.0;\n    float _3502 = 0.0;\n    float _3503 = 0.0;\n    float _3504 = 0.0;\n    float _3505 = 0.0;\n    float _3507 = 1.0;\n    bool _3508 = false;\n    vec3 _3509 = vec3(0.0);\n    float _3510 = 1.0;\n    float _3511 = 1.0;\n    float _3512 = 1.0;\n    float _3513 = 0.0;\n    float _3514 = 0.0;\n    vec3 _3515 = vec3(1.0, 0.0, 0.0);\n    vec3 _3516 = vec3(0.0, 0.0, 1.0);\n    float _3517 = 1.0;\n    float _3518 = 1.0;\n    float _2016 = clamp(s.specular, 0.0, 1.0);\n    float _2020 = clamp(s.ior, 1.0, 3.0);\n    bool _2025 = (_2016 != 1.0) || (_2020 != 1.5);\n    bool _2035;\n    if (!_2025)\n    {\n        _2035 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2035 = _2025;\n    }\n    if (_2035)\n    {\n        float _2043 = (_2020 - 1.0) / (_2020 + 1.0);\n        f0 = mix(min(vec3(_2043 * _2043) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2016, s.albedo, vec3(metallic));\n        _3499 = mix(_2016, 1.0, metallic);\n        _3498 = true;\n    }\n    float _2071 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2071 > 0.0)\n    {\n        float _2079 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3502 = _2071;\n        _3503 = _2079;\n        float _2086 = _2079 * _2079;\n        _3504 = _2086;\n        _3505 = _2086 * _2086;\n        float _2098 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3507 = _2098;\n        _3500 = 1.0 - (_2071 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2098, 0.0, 1.0), 5.0))));\n        _3498 = true;\n    }\n    vec3 _2118 = max(s.sheen_color, vec3(0.0));\n    float _2127 = max(_2118.x, max(_2118.y, _2118.z));\n    if (_2127 > 0.0)\n    {\n        float _2135 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3508 = true;\n        _3509 = _2118;\n        _3510 = _2135;\n        _3511 = _2135 * _2135;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2135;\n        float _2152 = fa_sheen_albedo(param, param_1);\n        _3513 = _2152;\n        _3512 = 1.0 - min(_2127 * _2152, 1.0);\n        _3498 = true;\n    }\n    _3501 = _3500 * _3512;\n    float _2171 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2171 != 0.0)\n    {\n        vec3 _2186 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2186;\n        if (dot(_2186, _2186) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2200 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2200.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2200.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2200.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2204 = t;\n        vec3 _2205 = normalize(_2204);\n        t = _2205;\n        vec3 _2230 = normalize((_2205 * cos(s.anisotropy_rotation)) + ((cross(n, _2205) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3515 = _2230;\n        _3516 = cross(n, _2230);\n        float _2240 = roughness * roughness;\n        float _2246 = mix(_2240, 1.0, _2171 * _2171);\n        bool _2248 = _2171 > 0.0;\n        _3517 = _2248 ? _2246 : _2240;\n        _3518 = _2248 ? _2240 : _2246;\n        _3514 = _2171;\n        _3498 = true;\n    }\n    return FaLayers(_3498, _3499, _3500, _3501, _3502, _3503, _3504, _3505, i.world_normal, _3507, _3508, _3509, _3510, _3511, _3512, _3513, _3514, _3515, _3516, _3517, _3518);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1795 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1798 = _1795.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1798 * _1798, exp2((-9.27999973297119140625) * ndv)) * _1798) + _1795.y)) + _1795.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1718 = rough * rough;\n    float _1748 = 0.60000002384185791015625 * _1718;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1718)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1748, 0.0500000007450580596923828125 + _1748, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1718 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2281;\n        if (L.aniso >= 0.0)\n        {\n            _2281 = L.b;\n        }\n        else\n        {\n            _2281 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2281, v), _2281), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2314 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2314.x) + (vec3(L.f90) * _2314.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2369 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2369.x) + _2369.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1837 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1837.x) + vec3(_1837.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2408 = clamp(s.metallic, 0.0, 1.0);\n    float _2412 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2419 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2408));\n    vec3 f0 = _2419;\n    vec3 _2423 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2423;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2408;\n    float param_5 = _2412;\n    vec3 param_6 = _2419;\n    FaLayers _2440 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2440.on)\n    {\n        FaLayers param_7 = _2440;\n        vec3 param_8 = _2423;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2412;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2423;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2412;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2647 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2647 > bestPower)\n        {\n            bestPower = _2647;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2676 = fa_light(param_2, param_3);\n        float _2684;\n        if (dot(s.normal, _2676.direction) > 0.5)\n        {\n            _2684 = 1.0;\n        }\n        else\n        {\n            _2684 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _2676.color) * _2684);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1605 = int(fa_shadows[25].x + 0.5);\n    float _1615 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1620 = _1605 > 0;\n    bool _1629;\n    if (_1620)\n    {\n        int param = _1605 - 1;\n        _1629 = _1615 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1629 = _1620;\n    }\n    if (_1629)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1636 = _1605 > 1;\n        bool _1643;\n        if (_1636)\n        {\n            _1643 = _1615 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1643 = _1636;\n        }\n        if (_1643)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1649 = _1605 > 2;\n        bool _1656;\n        if (_1649)\n        {\n            _1656 = _1615 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1656 = _1649;\n        }\n        if (_1656)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1662 = _1605 > 3;\n        bool _1669;\n        if (_1662)\n        {\n            _1669 = _1615 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1669 = _1662;\n        }\n        if (_1669)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3372 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3372 = -_3372;\n    }\n    vec3 _3076 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing);\n    Surface _3084 = fa_standard_surface(param_1);\n    vec3 _3403 = _3084.albedo;\n    float _3404 = _3084.alpha;\n    vec3 _3405 = _3084.normal;\n    float _3406 = _3084.metallic;\n    float _3407 = _3084.roughness;\n    float _3408 = _3084.occlusion;\n    vec3 _3409 = _3084.emission;\n    float _3410 = _3084.clearcoat;\n    float _3411 = _3084.clearcoat_roughness;\n    vec3 _3412 = _3084.sheen_color;\n    float _3413 = _3084.sheen_roughness;\n    float _3414 = _3084.anisotropy;\n    float _3415 = _3084.anisotropy_rotation;\n    float _3416 = _3084.specular;\n    float _3417 = _3084.ior;\n    vec3 _3418 = _3084.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing);\n    Surface param_3 = _3084;\n    surface(param_2, param_3);\n    _3403 = param_3.albedo;\n    _3404 = param_3.alpha;\n    _3405 = param_3.normal;\n    _3406 = param_3.metallic;\n    _3407 = param_3.roughness;\n    _3408 = param_3.occlusion;\n    _3409 = param_3.emission;\n    _3410 = param_3.clearcoat;\n    _3411 = param_3.clearcoat_roughness;\n    _3412 = param_3.sheen_color;\n    _3413 = param_3.sheen_roughness;\n    _3414 = param_3.anisotropy;\n    _3415 = param_3.anisotropy_rotation;\n    _3416 = param_3.specular;\n    _3417 = param_3.ior;\n    _3418 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3403;\n    }\n    else\n    {\n        vec3 _3105 = _3405;\n        vec3 _3106 = normalize(_3105);\n        _3405 = _3106;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing);\n        Surface param_5 = Surface(_3403, _3404, _3106, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413, _3414, _3415, _3416, _3417, _3418);\n        result = lighting(param_4, param_5);\n    }\n    vec3 _3121 = result;\n    vec3 _3122 = _3121 + _3409;\n    result = _3122;\n    vec3 param_6 = _3122;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3131 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3138;\n    if (!_3131)\n    {\n        _3138 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3138 = _3131;\n    }\n    if (_3138)\n    {\n        vec3 _3147 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3153 = dot(_3147, fa_mesh_fs_params[9].xyz);\n        bool _3157 = fa_mesh_fs_params[9].w > 0.5;\n        float _3158;\n        if (_3157)\n        {\n            _3158 = _3153;\n        }\n        else\n        {\n            _3158 = length(_3147);\n        }\n        float _3170 = _3158 - fa_mesh_fs_params[8].x;\n        if (_3170 > 0.0)\n        {\n            float _3179 = fa_mesh_fs_params[7].w * _3170;\n            float tau = _3179 * _3179;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3195;\n                if (_3157)\n                {\n                    _3195 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3153);\n                }\n                else\n                {\n                    _3195 = fa_mesh_fs_params[0].y;\n                }\n                float _3216 = mix(_3195, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3158, 0.0, 1.0));\n                float _3220 = fa_world_pos.y - _3216;\n                float _3225 = _3216 - fa_mesh_fs_params[8].z;\n                float _3230 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3233 = _3225 <= 0.0;\n                bool _3234 = !_3233;\n                bool _3240;\n                if (_3234)\n                {\n                    _3240 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3240 = _3233;\n                }\n                float _3241;\n                if (_3240)\n                {\n                    _3241 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3241 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3225, 80.0));\n                }\n                bool _3268;\n                if (_3234)\n                {\n                    _3268 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3268 = _3233;\n                }\n                float _3269;\n                if (_3268)\n                {\n                    _3269 = fa_mesh_fs_params[8].y * _3225;\n                }\n                else\n                {\n                    _3269 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3225, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3294 = _3230 <= 0.0;\n                bool _3301;\n                if (!_3294)\n                {\n                    _3301 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3301 = _3294;\n                }\n                float _3302;\n                if (_3301)\n                {\n                    _3302 = fa_mesh_fs_params[8].y * _3230;\n                }\n                else\n                {\n                    _3302 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3230, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3329;\n                if (abs(_3220) < 0.001000000047497451305389404296875)\n                {\n                    _3329 = _3241;\n                }\n                else\n                {\n                    _3329 = (_3302 - _3269) / _3220;\n                }\n                tau += (_3170 * max(_3329, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3404);\n}\n\n",
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
            "inst_name": "_443",
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
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_679",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_2690",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _1938[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 7) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _448 = fa_mesh_fs_params[19].x < 0.0;\n    bool _455;\n    if (!_448)\n    {\n        _455 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _455 = _448;\n    }\n    bool _463;\n    if (!_455)\n    {\n        _463 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _463 = _455;\n    }\n    bool _470;\n    if (!_463)\n    {\n        _470 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _470 = _463;\n    }\n    bool _477;\n    if (!_470)\n    {\n        _477 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _477 = _470;\n    }\n    if (_477)\n    {\n        return ivec2(0);\n    }\n    vec4 _487 = vec4(world_pos, 1.0);\n    float _494 = dot(fa_mesh_fs_params[16], _487);\n    if (!(_494 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _516 = vec2(dot(fa_mesh_fs_params[14], _487), dot(fa_mesh_fs_params[15], _487)) / vec2(_494);\n    int _520 = int(fa_mesh_fs_params[18].x);\n    int _524 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _524) + clamp(int(floor(((_516.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _524 - 1)) * _520)) + clamp(int(floor(((_516.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _520 - 1);\n    vec4 _595 = fa_light_texel(param);\n    return ivec2(int(_595.x), int(_595.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _2486 = fa_cluster_lookup(param);\n    fa_cl_slot = _2486.x;\n    fa_cl_local = _2486.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _2762 = fa_linear_to_srgb(param);\n        c = _2762;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _2770 = fa_srgb_to_linear(param_1);\n            c = _2770;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _223;\n    if (i.front_facing)\n    {\n        _223 = i.world_normal;\n    }\n    else\n    {\n        _223 = -i.world_normal;\n    }\n    vec3 _247 = normalize(i.world_tangent.xyz - (_223 * dot(_223, i.world_tangent.xyz)));\n    vec3 _275 = normalize(((_247 * m.x) + ((cross(_223, _247) * i.world_tangent.w) * m.y)) + (_223 * m.z));\n    vec3 _278;\n    if (i.front_facing)\n    {\n        _278 = _275;\n    }\n    else\n    {\n        _278 = -_275;\n    }\n    return _278;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _2801 = fa_tex_fix(param_2, param_3);\n    vec4 _3746 = base_t;\n    _3746.x = _2801.x;\n    _3746.y = _2801.y;\n    _3746.z = _2801.z;\n    base_t = _3746;\n    vec4 _2815 = (_3746 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _3648 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _2847 = fa_tex_fix(param_6, param_7);\n        vec3 _2851 = (_2847 * 2.0) - vec3(1.0);\n        vec2 _2856 = _2851.xy * fa_mesh_fs_params[6].x;\n        vec3 _3754 = _2851;\n        _3754.x = _2856.x;\n        _3754.y = _2856.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _3754;\n        _3648 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2885 = fa_tex_fix(param_12, param_13);\n    vec4 _3757 = mrt;\n    _3757.x = _2885.x;\n    _3757.y = _2885.y;\n    _3757.z = _2885.z;\n    mrt = _3757;\n    vec4 _2913 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2913.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2925 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2955 = fa_tex_fix(param_20, param_21);\n    float _3653 = fa_mesh_fs_params[20].x;\n    float _3654 = fa_mesh_fs_params[20].y;\n    float _3657 = fa_mesh_fs_params[20].z;\n    float _3656 = fa_mesh_fs_params[21].w;\n    float _3659 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _3653 *= _2925.y;\n            _3654 *= _2925.z;\n            _3656 *= _2913.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _3657 *= mrt.x;\n            _3659 *= mrt.w;\n        }\n    }\n    return Surface(_2815.xyz, _2815.w, _3648, clamp(fa_mesh_fs_params[5].x * _2885.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2885.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2925.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2955), _3653, _3654, fa_mesh_fs_params[21].xyz, _3656, _3657, fa_mesh_fs_params[20].w, _3659, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _315 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _321 = fa_light_texel(param_1);\n    float _324 = _321.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _331 = _324 < 0.5;\n    vec3 l;\n    if (_331)\n    {\n        l = normalize(_315.xyz);\n    }\n    else\n    {\n        vec3 _343 = _315.xyz - world_pos;\n        float _345 = length(_343);\n        dist = _345;\n        l = _343 / vec3(max(_345, 9.9999997473787516355514526367188e-05));\n        float _360 = _345 / max(_315.w, 0.001000000047497451305389404296875);\n        float _366 = clamp(1.0 - (_360 * _360), 0.0, 1.0);\n        atten = _366 * _366;\n        if (_324 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _380 = fa_light_texel(param_2);\n            float _390 = _380.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _397 = fa_light_texel(param_3);\n            float _398 = _397.x;\n            float cos_inner = _398;\n            if (_398 > 1.5)\n            {\n                cos_inner = mix(_390, 1.0, 0.25);\n            }\n            atten *= smoothstep(_390, cos_inner, dot(-l, normalize(_380.xyz)));\n        }\n    }\n    int _429;\n    if (_331)\n    {\n        _429 = 0;\n    }\n    else\n    {\n        _429 = (_324 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _321.xyz * atten, atten, 1.0, dist, _429);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _2600 = n < 0;\n    bool _2607;\n    if (!_2600)\n    {\n        _2607 = n >= fa_light_count();\n    }\n    else\n    {\n        _2607 = _2600;\n    }\n    if (_2607)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    return fa_light_sample(param_1, param_2);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _669;\n    if (i == 0)\n    {\n        _669 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _685;\n        if (i == 1)\n        {\n            _685 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _693;\n            if (i == 2)\n            {\n                _693 = fa_shadows[24].z;\n            }\n            else\n            {\n                _693 = fa_shadows[24].w;\n            }\n            _685 = _693;\n        }\n        _669 = _685;\n    }\n    return _669;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _726 = fa_shadow_depth(param, param_1);\n    float _730;\n    if (conv.x < 0.5)\n    {\n        _730 = _726;\n    }\n    else\n    {\n        _730 = (conv.y * conv.z) / (conv.z - (_726 * (conv.z - conv.y)));\n    }\n    return _730;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _657 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_657), sin(_657)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _776 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _790 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _776;\n            vec2 _809 = fa_shadow_vogel(param_3, param_4, param_5) * _790;\n            vec2 param_6 = uv + (_809 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _821 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_821 < (zr - (length(_809) * plane)))\n            {\n                sum += _821;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _865 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _865; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _865;\n        float param_11 = _776;\n        vec2 _884 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_884 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_884) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_865);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _926 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _931 = clamp(dot(n, l), 0.0, 1.0);\n    float _937 = sqrt(1.0 - (_931 * _931));\n    float _945 = min(_937 / max(_931, 0.20000000298023223876953125), 4.0);\n    float _950;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _950 = fa_shadows[26].y;\n    }\n    else\n    {\n        _950 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _975 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_950 * _937)), 1.0);\n    float _982 = _975.x;\n    bool _985 = _982 < fa_shadows[ci * 1 + 16].x;\n    bool _994;\n    if (!_985)\n    {\n        _994 = _982 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _994 = _985;\n    }\n    bool _1003;\n    if (!_994)\n    {\n        _1003 = _975.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1003 = _994;\n    }\n    bool _1012;\n    if (!_1003)\n    {\n        _1012 = _975.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1012 = _1003;\n    }\n    bool _1019;\n    if (!_1012)\n    {\n        _1019 = _975.z > 1.0;\n    }\n    else\n    {\n        _1019 = _1012;\n    }\n    if (_1019)\n    {\n        return -1.0;\n    }\n    float _1028;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1028 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1028 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _975.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _975.z - ((_1028 * (1.0 + (0.5 * _945))) / _926);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _926;\n    float param_5 = _926 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_945, 3.0)) * 0.5) / _926;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1422 = int(fa_shadows[25].x + 0.5);\n    if (_1422 < 1)\n    {\n        return 1.0;\n    }\n    float _1438 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1422 - 1;\n    if (_1438 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1450 = _1422 > 1;\n    bool _1457;\n    if (_1450)\n    {\n        _1457 = _1438 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1457 = _1450;\n    }\n    if (_1457)\n    {\n        ci = 1;\n    }\n    bool _1461 = _1422 > 2;\n    bool _1468;\n    if (_1461)\n    {\n        _1468 = _1438 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1468 = _1461;\n    }\n    if (_1468)\n    {\n        ci = 2;\n    }\n    bool _1472 = _1422 > 3;\n    bool _1479;\n    if (_1472)\n    {\n        _1479 = _1438 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1479 = _1472;\n    }\n    if (_1479)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1422)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1505 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1505;\n        if (_1505 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1530;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1530 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1530 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1549 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1530, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1560 = clamp((_1438 - (fa_shadow_split_at(param_7) - _1549)) / _1549, 0.0, 1.0);\n        if (_1560 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1422)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1581 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1581;\n                if (_1581 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1560);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1087 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1095;\n    if (!_1087)\n    {\n        _1095 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1095 = _1087;\n    }\n    if (_1095)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1108 = fa_light_texel(param);\n    float _1109 = _1108.x;\n    if (_1109 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1118 = int(_1109 + 0.5);\n    int param_1 = _1118;\n    vec4 _1122 = fa_light_texel(param_1);\n    int param_2 = _1118 + 1;\n    vec4 _1127 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1130 = _1122.y;\n    if (_1130 > 0.0)\n    {\n        float _1147 = 1.0 - smoothstep(0.75 * _1130, _1130, length(world - fa_shadows[27].xyz));\n        fade = _1147;\n        if (_1147 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1122.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1166 = world - fa_light_texel(param_3).xyz;\n        vec3 _1169 = abs(_1166);\n        float _1171 = _1169.x;\n        float _1173 = _1169.y;\n        bool _1174 = _1171 >= _1173;\n        bool _1182;\n        if (_1174)\n        {\n            _1182 = _1171 >= _1169.z;\n        }\n        else\n        {\n            _1182 = _1174;\n        }\n        int _1183;\n        if (_1182)\n        {\n            _1183 = (_1166.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1196;\n            if (_1173 >= _1169.z)\n            {\n                _1196 = (_1166.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1196 = (_1166.z > 0.0) ? 4 : 5;\n            }\n            _1183 = _1196;\n        }\n        face = _1183;\n    }\n    int _1215 = (_1118 + 2) + (face * 6);\n    int param_4 = _1215;\n    int param_5 = _1215 + 1;\n    int param_6 = _1215 + 3;\n    vec4 _1229 = fa_light_texel(param_6);\n    int param_7 = _1215 + 4;\n    vec4 _1234 = fa_light_texel(param_7);\n    int param_8 = _1215 + 5;\n    vec4 _1239 = fa_light_texel(param_8);\n    float _1251 = _1239.x * max(dot(_1229, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1256 = clamp(dot(n, l), 0.0, 1.0);\n    float _1262 = sqrt(1.0 - (_1256 * _1256));\n    float _1268 = min(_1262 / max(_1256, 0.20000000298023223876953125), 4.0);\n    float _1271 = _1127.y;\n    float _1273;\n    if (_1271 > 0.0)\n    {\n        _1273 = _1271;\n    }\n    else\n    {\n        _1273 = 1.5 * _1251;\n    }\n    vec4 _1293 = vec4(world + (n * (_1273 * _1262)), 1.0);\n    float _1297 = dot(_1229, _1293);\n    float _1300 = _1239.y;\n    if (_1297 < _1300)\n    {\n        return 1.0;\n    }\n    vec2 _1315 = vec2(dot(fa_light_texel(param_4), _1293), dot(fa_light_texel(param_5), _1293)) / vec2(_1297);\n    float _1317 = _1315.x;\n    bool _1320 = _1317 < _1234.x;\n    bool _1329;\n    if (!_1320)\n    {\n        _1329 = _1317 > _1234.z;\n    }\n    else\n    {\n        _1329 = _1320;\n    }\n    bool _1338;\n    if (!_1329)\n    {\n        _1338 = _1315.y < _1234.y;\n    }\n    else\n    {\n        _1338 = _1329;\n    }\n    bool _1347;\n    if (!_1338)\n    {\n        _1347 = _1315.y > _1234.w;\n    }\n    else\n    {\n        _1347 = _1338;\n    }\n    if (_1347)\n    {\n        return 1.0;\n    }\n    float _1353 = _1127.x;\n    float _1355;\n    if (_1353 > 0.0)\n    {\n        _1355 = _1353;\n    }\n    else\n    {\n        _1355 = 1.5 * _1251;\n    }\n    vec2 param_9 = _1315;\n    vec4 param_10 = _1234;\n    float param_11 = _1297 - (_1355 * (1.0 + (0.5 * _1268)));\n    float param_12 = _1251;\n    float param_13 = 1.0;\n    float param_14 = _1239.z * 0.25;\n    float param_15 = (_1251 * min(_1268, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1300, _1239.z);\n    int param_17 = int(_1122.z + 0.5);\n    float param_18 = _1122.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _2514 = fa_light_sample(param, param_1);\n    vec3 _3624 = _2514.direction;\n    vec3 _3619 = _2514.color;\n    float _3626 = _2514.attenuation;\n    float _3621 = _2514.shadow;\n    int _3629 = _2514.type;\n    if ((_3629 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _3624;\n        float _2528 = fa_shadow_factor(param_2, param_3);\n        _3621 = _2528;\n        _3619 *= _2528;\n    }\n    else\n    {\n        bool _2539 = _3629 != 0;\n        bool _2545;\n        if (_2539)\n        {\n            _2545 = _3626 > 0.0;\n        }\n        else\n        {\n            _2545 = _2539;\n        }\n        if (_2545)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _3624;\n            float _2557 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _3621 = _2557;\n            _3619 *= _2557;\n        }\n    }\n    return LightSample(_3624, _3619, _3626, _3621, _2514._distance, _3629);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _2574 = n < 0;\n    bool _2581;\n    if (!_2574)\n    {\n        _2581 = n >= fa_light_count();\n    }\n    else\n    {\n        _2581 = _2574;\n    }\n    if (_2581)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    return fa_light_shadowed(param_1, param_2, param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _1863 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _1871 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _1874 = int(_1863);\n    int _1877 = int(_1871);\n    float _1887 = _1871 - float(_1877);\n    int _1943 = (_1874 * 9) + _1877;\n    int _1963 = ((_1874 + 1) * 9) + _1877;\n    return mix(mix(_1938[_1943], _1938[_1943 + 1], _1887), mix(_1938[_1963], _1938[_1963 + 1], _1887), _1863 - float(_1874));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _3498 = false;\n    float _3499 = 1.0;\n    float _3500 = 1.0;\n    float _3501 = 1.0;\n    float _3502 = 0.0;\n    float _3503 = 0.0;\n    float _3504 = 0.0;\n    float _3505 = 0.0;\n    float _3507 = 1.0;\n    bool _3508 = false;\n    vec3 _3509 = vec3(0.0);\n    float _3510 = 1.0;\n    float _3511 = 1.0;\n    float _3512 = 1.0;\n    float _3513 = 0.0;\n    float _3514 = 0.0;\n    vec3 _3515 = vec3(1.0, 0.0, 0.0);\n    vec3 _3516 = vec3(0.0, 0.0, 1.0);\n    float _3517 = 1.0;\n    float _3518 = 1.0;\n    float _2016 = clamp(s.specular, 0.0, 1.0);\n    float _2020 = clamp(s.ior, 1.0, 3.0);\n    bool _2025 = (_2016 != 1.0) || (_2020 != 1.5);\n    bool _2035;\n    if (!_2025)\n    {\n        _2035 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _2035 = _2025;\n    }\n    if (_2035)\n    {\n        float _2043 = (_2020 - 1.0) / (_2020 + 1.0);\n        f0 = mix(min(vec3(_2043 * _2043) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _2016, s.albedo, vec3(metallic));\n        _3499 = mix(_2016, 1.0, metallic);\n        _3498 = true;\n    }\n    float _2071 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_2071 > 0.0)\n    {\n        float _2079 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _3502 = _2071;\n        _3503 = _2079;\n        float _2086 = _2079 * _2079;\n        _3504 = _2086;\n        _3505 = _2086 * _2086;\n        float _2098 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _3507 = _2098;\n        _3500 = 1.0 - (_2071 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _2098, 0.0, 1.0), 5.0))));\n        _3498 = true;\n    }\n    vec3 _2118 = max(s.sheen_color, vec3(0.0));\n    float _2127 = max(_2118.x, max(_2118.y, _2118.z));\n    if (_2127 > 0.0)\n    {\n        float _2135 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _3508 = true;\n        _3509 = _2118;\n        _3510 = _2135;\n        _3511 = _2135 * _2135;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _2135;\n        float _2152 = fa_sheen_albedo(param, param_1);\n        _3513 = _2152;\n        _3512 = 1.0 - min(_2127 * _2152, 1.0);\n        _3498 = true;\n    }\n    _3501 = _3500 * _3512;\n    float _2171 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_2171 != 0.0)\n    {\n        vec3 _2186 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _2186;\n        if (dot(_2186, _2186) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _2200 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_2200.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _2200.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _2200.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _2204 = t;\n        vec3 _2205 = normalize(_2204);\n        t = _2205;\n        vec3 _2230 = normalize((_2205 * cos(s.anisotropy_rotation)) + ((cross(n, _2205) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _3515 = _2230;\n        _3516 = cross(n, _2230);\n        float _2240 = roughness * roughness;\n        float _2246 = mix(_2240, 1.0, _2171 * _2171);\n        bool _2248 = _2171 > 0.0;\n        _3517 = _2248 ? _2246 : _2240;\n        _3518 = _2248 ? _2240 : _2246;\n        _3514 = _2171;\n        _3498 = true;\n    }\n    return FaLayers(_3498, _3499, _3500, _3501, _3502, _3503, _3504, _3505, i.world_normal, _3507, _3508, _3509, _3510, _3511, _3512, _3513, _3514, _3515, _3516, _3517, _3518);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1795 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1798 = _1795.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1798 * _1798, exp2((-9.27999973297119140625) * ndv)) * _1798) + _1795.y)) + _1795.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1718 = rough * rough;\n    float _1748 = 0.60000002384185791015625 * _1718;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1718)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1748, 0.0500000007450580596923828125 + _1748, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1718 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _2281;\n        if (L.aniso >= 0.0)\n        {\n            _2281 = L.b;\n        }\n        else\n        {\n            _2281 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_2281, v), _2281), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _2314 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _2314.x) + (vec3(L.f90) * _2314.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _2369 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _2369.x) + _2369.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1837 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1837.x) + vec3(_1837.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _2408 = clamp(s.metallic, 0.0, 1.0);\n    float _2412 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _2419 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_2408));\n    vec3 f0 = _2419;\n    vec3 _2423 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _2423;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _2408;\n    float param_5 = _2412;\n    vec3 param_6 = _2419;\n    FaLayers _2440 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_2440.on)\n    {\n        FaLayers param_7 = _2440;\n        vec3 param_8 = _2423;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _2412;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _2423;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _2412;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        float _2647 = dot(fa_light_unshadowed(param, param_1).color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_2647 > bestPower)\n        {\n            bestPower = _2647;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _2676 = fa_light(param_2, param_3);\n        float _2684;\n        if (dot(s.normal, _2676.direction) > 0.5)\n        {\n            _2684 = 1.0;\n        }\n        else\n        {\n            _2684 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _2676.color) * _2684);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1605 = int(fa_shadows[25].x + 0.5);\n    float _1615 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1620 = _1605 > 0;\n    bool _1629;\n    if (_1620)\n    {\n        int param = _1605 - 1;\n        _1629 = _1615 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1629 = _1620;\n    }\n    if (_1629)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1636 = _1605 > 1;\n        bool _1643;\n        if (_1636)\n        {\n            _1643 = _1615 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1643 = _1636;\n        }\n        if (_1643)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1649 = _1605 > 2;\n        bool _1656;\n        if (_1649)\n        {\n            _1656 = _1615 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1656 = _1649;\n        }\n        if (_1656)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1662 = _1605 > 3;\n        bool _1669;\n        if (_1662)\n        {\n            _1669 = _1615 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1669 = _1662;\n        }\n        if (_1669)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _3372 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _3372 = -_3372;\n    }\n    vec3 _3076 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing);\n    Surface _3084 = fa_standard_surface(param_1);\n    vec3 _3403 = _3084.albedo;\n    float _3404 = _3084.alpha;\n    vec3 _3405 = _3084.normal;\n    float _3406 = _3084.metallic;\n    float _3407 = _3084.roughness;\n    float _3408 = _3084.occlusion;\n    vec3 _3409 = _3084.emission;\n    float _3410 = _3084.clearcoat;\n    float _3411 = _3084.clearcoat_roughness;\n    vec3 _3412 = _3084.sheen_color;\n    float _3413 = _3084.sheen_roughness;\n    float _3414 = _3084.anisotropy;\n    float _3415 = _3084.anisotropy_rotation;\n    float _3416 = _3084.specular;\n    float _3417 = _3084.ior;\n    vec3 _3418 = _3084.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing);\n    Surface param_3 = _3084;\n    surface(param_2, param_3);\n    _3403 = param_3.albedo;\n    _3404 = param_3.alpha;\n    _3405 = param_3.normal;\n    _3406 = param_3.metallic;\n    _3407 = param_3.roughness;\n    _3408 = param_3.occlusion;\n    _3409 = param_3.emission;\n    _3410 = param_3.clearcoat;\n    _3411 = param_3.clearcoat_roughness;\n    _3412 = param_3.sheen_color;\n    _3413 = param_3.sheen_roughness;\n    _3414 = param_3.anisotropy;\n    _3415 = param_3.anisotropy_rotation;\n    _3416 = param_3.specular;\n    _3417 = param_3.ior;\n    _3418 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _3403;\n    }\n    else\n    {\n        vec3 _3105 = _3405;\n        vec3 _3106 = normalize(_3105);\n        _3405 = _3106;\n        SurfaceInput param_4 = SurfaceInput(fa_world_pos, _3372, fa_world_tangent, fa_uv, fa_vertex_color, _3076, gl_FrontFacing);\n        Surface param_5 = Surface(_3403, _3404, _3106, _3406, _3407, _3408, _3409, _3410, _3411, _3412, _3413, _3414, _3415, _3416, _3417, _3418);\n        result = lighting(param_4, param_5);\n    }\n    vec3 _3121 = result;\n    vec3 _3122 = _3121 + _3409;\n    result = _3122;\n    vec3 param_6 = _3122;\n    vec3 param_7 = fa_world_pos;\n    result = fa_shadow_debug(param_6, param_7);\n    bool _3131 = fa_mesh_fs_params[7].w > 0.0;\n    bool _3138;\n    if (!_3131)\n    {\n        _3138 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _3138 = _3131;\n    }\n    if (_3138)\n    {\n        vec3 _3147 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _3153 = dot(_3147, fa_mesh_fs_params[9].xyz);\n        bool _3157 = fa_mesh_fs_params[9].w > 0.5;\n        float _3158;\n        if (_3157)\n        {\n            _3158 = _3153;\n        }\n        else\n        {\n            _3158 = length(_3147);\n        }\n        float _3170 = _3158 - fa_mesh_fs_params[8].x;\n        if (_3170 > 0.0)\n        {\n            float _3179 = fa_mesh_fs_params[7].w * _3170;\n            float tau = _3179 * _3179;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _3195;\n                if (_3157)\n                {\n                    _3195 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _3153);\n                }\n                else\n                {\n                    _3195 = fa_mesh_fs_params[0].y;\n                }\n                float _3216 = mix(_3195, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _3158, 0.0, 1.0));\n                float _3220 = fa_world_pos.y - _3216;\n                float _3225 = _3216 - fa_mesh_fs_params[8].z;\n                float _3230 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _3233 = _3225 <= 0.0;\n                bool _3234 = !_3233;\n                bool _3240;\n                if (_3234)\n                {\n                    _3240 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3240 = _3233;\n                }\n                float _3241;\n                if (_3240)\n                {\n                    _3241 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _3241 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _3225, 80.0));\n                }\n                bool _3268;\n                if (_3234)\n                {\n                    _3268 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3268 = _3233;\n                }\n                float _3269;\n                if (_3268)\n                {\n                    _3269 = fa_mesh_fs_params[8].y * _3225;\n                }\n                else\n                {\n                    _3269 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3225, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _3294 = _3230 <= 0.0;\n                bool _3301;\n                if (!_3294)\n                {\n                    _3301 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _3301 = _3294;\n                }\n                float _3302;\n                if (_3301)\n                {\n                    _3302 = fa_mesh_fs_params[8].y * _3230;\n                }\n                else\n                {\n                    _3302 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _3230, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _3329;\n                if (abs(_3220) < 0.001000000047497451305389404296875)\n                {\n                    _3329 = _3241;\n                }\n                else\n                {\n                    _3329 = (_3302 - _3269) / _3220;\n                }\n                tau += (_3170 * max(_3329, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _3404);\n}\n\n",
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
            "inst_name": "_443",
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
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_679",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
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
            "inst_name": "_2690",
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
