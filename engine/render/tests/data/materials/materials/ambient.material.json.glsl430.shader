{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "7cd31c28ac6572768802838498bbbd3180b96e0a1bb1bab7ad49d1d6af9d528c",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_265, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _399 = fa_mesh_fs_params[19].x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return ivec2(0);\n    }\n    vec4 _438 = vec4(world_pos, 1.0);\n    float _445 = dot(fa_mesh_fs_params[16], _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _467 = vec2(dot(fa_mesh_fs_params[14], _438), dot(fa_mesh_fs_params[15], _438)) / vec2(_445);\n    int _471 = int(fa_mesh_fs_params[18].x);\n    int _475 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _471 - 1);\n    vec4 _546 = fa_light_texel(param);\n    return ivec2(int(_546.x), int(_546.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1674 = fa_cluster_lookup(param);\n    fa_cl_slot = _1674.x;\n    fa_cl_local = _1674.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1810 = fa_linear_to_srgb(param);\n        c = _1810;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1818 = fa_srgb_to_linear(param_1);\n            c = _1818;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _175;\n    if (i.front_facing)\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    vec3 _199 = normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    vec3 _227 = normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    vec3 _230;\n    if (i.front_facing)\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1849 = fa_tex_fix(param_2, param_3);\n    vec4 _2792 = base_t;\n    _2792.x = _1849.x;\n    _2792.y = _1849.y;\n    _2792.z = _1849.z;\n    base_t = _2792;\n    vec4 _1863 = (_2792 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2707 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1895 = fa_tex_fix(param_6, param_7);\n        vec3 _1899 = (_1895 * 2.0) - vec3(1.0);\n        vec2 _1904 = _1899.xy * fa_mesh_fs_params[6].x;\n        vec3 _2800 = _1899;\n        _2800.x = _1904.x;\n        _2800.y = _1904.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2800;\n        _2707 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1933 = fa_tex_fix(param_12, param_13);\n    vec4 _2803 = mrt;\n    _2803.x = _1933.x;\n    _2803.y = _1933.y;\n    _2803.z = _1933.z;\n    mrt = _2803;\n    vec4 _1962 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1962.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1974 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2004 = fa_tex_fix(param_20, param_21);\n    float _2712 = fa_mesh_fs_params[20].x;\n    float _2713 = fa_mesh_fs_params[20].y;\n    float _2716 = fa_mesh_fs_params[20].z;\n    float _2715 = fa_mesh_fs_params[21].w;\n    float _2718 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2712 *= _1974.y;\n            _2713 *= _1974.z;\n            _2715 *= _1962.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2716 *= mrt.x;\n            _2718 *= mrt.w;\n        }\n    }\n    return Surface(_1863.xyz, _1863.w, _2707, clamp(fa_mesh_fs_params[5].x * _1933.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1933.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1974.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2004), _2712, _2713, fa_mesh_fs_params[21].xyz, _2715, _2716, fa_mesh_fs_params[20].w, _2718, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _267 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _273 = fa_light_texel(param_1);\n    float _276 = _273.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _283 = _276 < 0.5;\n    vec3 l;\n    if (_283)\n    {\n        l = normalize(_267.xyz);\n    }\n    else\n    {\n        vec3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / vec3(max(_297, 9.9999997473787516355514526367188e-05));\n        float _312 = _297 / max(_267.w, 0.001000000047497451305389404296875);\n        float _318 = clamp(1.0 - (_312 * _312), 0.0, 1.0);\n        atten = _318 * _318;\n        if (_276 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _332 = fa_light_texel(param_2);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _349 = fa_light_texel(param_3);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5)\n            {\n                cos_inner = mix(_342, 1.0, 0.25);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _273.xyz * atten, atten, 1.0, dist, _380);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = fa_shadows[24].z;\n            }\n            else\n            {\n                _644 = fa_shadows[24].w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _677 = fa_shadow_depth(param, param_1);\n    float _681;\n    if (conv.x < 0.5)\n    {\n        _681 = _677;\n    }\n    else\n    {\n        _681 = (conv.y * conv.z) / (conv.z - (_677 * (conv.z - conv.y)));\n    }\n    return _681;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _727 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _741 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _727;\n            vec2 _760 = fa_shadow_vogel(param_3, param_4, param_5) * _741;\n            vec2 param_6 = uv + (_760 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _772 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_772 < (zr - (length(_760) * plane)))\n            {\n                sum += _772;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _816 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _816; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _816;\n        float param_11 = _727;\n        vec2 _835 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_835 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_835) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_816);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _877 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _882 = clamp(dot(n, l), 0.0, 1.0);\n    float _888 = sqrt(1.0 - (_882 * _882));\n    float _896 = min(_888 / max(_882, 0.20000000298023223876953125), 4.0);\n    float _901;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _901 = fa_shadows[26].y;\n    }\n    else\n    {\n        _901 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _926 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_901 * _888)), 1.0);\n    float _933 = _926.x;\n    bool _936 = _933 < fa_shadows[ci * 1 + 16].x;\n    bool _945;\n    if (!_936)\n    {\n        _945 = _933 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _945 = _936;\n    }\n    bool _954;\n    if (!_945)\n    {\n        _954 = _926.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _954 = _945;\n    }\n    bool _963;\n    if (!_954)\n    {\n        _963 = _926.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _963 = _954;\n    }\n    bool _970;\n    if (!_963)\n    {\n        _970 = _926.z > 1.0;\n    }\n    else\n    {\n        _970 = _963;\n    }\n    if (_970)\n    {\n        return -1.0;\n    }\n    float _979;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _979 = fa_shadows[26].x;\n    }\n    else\n    {\n        _979 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _926.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _926.z - ((_979 * (1.0 + (0.5 * _896))) / _877);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _877;\n    float param_5 = _877 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_896, 3.0)) * 0.5) / _877;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1373 = int(fa_shadows[25].x + 0.5);\n    if (_1373 < 1)\n    {\n        return 1.0;\n    }\n    float _1389 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1373 - 1;\n    if (_1389 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1401 = _1373 > 1;\n    bool _1408;\n    if (_1401)\n    {\n        _1408 = _1389 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1408 = _1401;\n    }\n    if (_1408)\n    {\n        ci = 1;\n    }\n    bool _1412 = _1373 > 2;\n    bool _1419;\n    if (_1412)\n    {\n        _1419 = _1389 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    if (_1419)\n    {\n        ci = 2;\n    }\n    bool _1423 = _1373 > 3;\n    bool _1430;\n    if (_1423)\n    {\n        _1430 = _1389 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1430 = _1423;\n    }\n    if (_1430)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1373)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1456 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1456;\n        if (_1456 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1481;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1481 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1481 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1500 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1481, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1511 = clamp((_1389 - (fa_shadow_split_at(param_7) - _1500)) / _1500, 0.0, 1.0);\n        if (_1511 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1373)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1532 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1532;\n                if (_1532 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1511);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1038 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1046;\n    if (!_1038)\n    {\n        _1046 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1046 = _1038;\n    }\n    if (_1046)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1059 = fa_light_texel(param);\n    float _1060 = _1059.x;\n    if (_1060 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1069 = int(_1060 + 0.5);\n    int param_1 = _1069;\n    vec4 _1073 = fa_light_texel(param_1);\n    int param_2 = _1069 + 1;\n    vec4 _1078 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1081 = _1073.y;\n    if (_1081 > 0.0)\n    {\n        float _1098 = 1.0 - smoothstep(0.75 * _1081, _1081, length(world - fa_shadows[27].xyz));\n        fade = _1098;\n        if (_1098 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1073.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1117 = world - fa_light_texel(param_3).xyz;\n        vec3 _1120 = abs(_1117);\n        float _1122 = _1120.x;\n        float _1124 = _1120.y;\n        bool _1125 = _1122 >= _1124;\n        bool _1133;\n        if (_1125)\n        {\n            _1133 = _1122 >= _1120.z;\n        }\n        else\n        {\n            _1133 = _1125;\n        }\n        int _1134;\n        if (_1133)\n        {\n            _1134 = (_1117.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1147;\n            if (_1124 >= _1120.z)\n            {\n                _1147 = (_1117.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1147 = (_1117.z > 0.0) ? 4 : 5;\n            }\n            _1134 = _1147;\n        }\n        face = _1134;\n    }\n    int _1166 = (_1069 + 2) + (face * 6);\n    int param_4 = _1166;\n    int param_5 = _1166 + 1;\n    int param_6 = _1166 + 3;\n    vec4 _1180 = fa_light_texel(param_6);\n    int param_7 = _1166 + 4;\n    vec4 _1185 = fa_light_texel(param_7);\n    int param_8 = _1166 + 5;\n    vec4 _1190 = fa_light_texel(param_8);\n    float _1202 = _1190.x * max(dot(_1180, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1207 = clamp(dot(n, l), 0.0, 1.0);\n    float _1213 = sqrt(1.0 - (_1207 * _1207));\n    float _1219 = min(_1213 / max(_1207, 0.20000000298023223876953125), 4.0);\n    float _1222 = _1078.y;\n    float _1224;\n    if (_1222 > 0.0)\n    {\n        _1224 = _1222;\n    }\n    else\n    {\n        _1224 = 1.5 * _1202;\n    }\n    vec4 _1244 = vec4(world + (n * (_1224 * _1213)), 1.0);\n    float _1248 = dot(_1180, _1244);\n    float _1251 = _1190.y;\n    if (_1248 < _1251)\n    {\n        return 1.0;\n    }\n    vec2 _1266 = vec2(dot(fa_light_texel(param_4), _1244), dot(fa_light_texel(param_5), _1244)) / vec2(_1248);\n    float _1268 = _1266.x;\n    bool _1271 = _1268 < _1185.x;\n    bool _1280;\n    if (!_1271)\n    {\n        _1280 = _1268 > _1185.z;\n    }\n    else\n    {\n        _1280 = _1271;\n    }\n    bool _1289;\n    if (!_1280)\n    {\n        _1289 = _1266.y < _1185.y;\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    bool _1298;\n    if (!_1289)\n    {\n        _1298 = _1266.y > _1185.w;\n    }\n    else\n    {\n        _1298 = _1289;\n    }\n    if (_1298)\n    {\n        return 1.0;\n    }\n    float _1304 = _1078.x;\n    float _1306;\n    if (_1304 > 0.0)\n    {\n        _1306 = _1304;\n    }\n    else\n    {\n        _1306 = 1.5 * _1202;\n    }\n    vec2 param_9 = _1266;\n    vec4 param_10 = _1185;\n    float param_11 = _1248 - (_1306 * (1.0 + (0.5 * _1219)));\n    float param_12 = _1202;\n    float param_13 = 1.0;\n    float param_14 = _1190.z * 0.25;\n    float param_15 = (_1202 * min(_1219, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1251, _1190.z);\n    int param_17 = int(_1073.z + 0.5);\n    float param_18 = _1073.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1702 = fa_light_sample(param, param_1);\n    vec3 _2692 = _1702.direction;\n    vec3 _2687 = _1702.color;\n    float _2694 = _1702.attenuation;\n    float _2689 = _1702.shadow;\n    int _2697 = _1702.type;\n    if ((_2697 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2692;\n        float _1716 = fa_shadow_factor(param_2, param_3);\n        _2689 = _1716;\n        _2687 *= _1716;\n    }\n    else\n    {\n        bool _1727 = _2697 != 0;\n        bool _1733;\n        if (_1727)\n        {\n            _1733 = _2694 > 0.0;\n        }\n        else\n        {\n            _1733 = _1727;\n        }\n        if (_1733)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _2692;\n            float _1745 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _2689 = _1745;\n            _2687 *= _1745;\n        }\n    }\n    return LightSample(_2692, _2687, _2694, _2689, _1702._distance, _2697);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1556 = int(fa_shadows[25].x + 0.5);\n    float _1566 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1571 = _1556 > 0;\n    bool _1580;\n    if (_1571)\n    {\n        int param = _1556 - 1;\n        _1580 = _1566 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1580 = _1571;\n    }\n    if (_1580)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1587 = _1556 > 1;\n        bool _1594;\n        if (_1587)\n        {\n            _1594 = _1566 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1594 = _1587;\n        }\n        if (_1594)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1600 = _1556 > 2;\n        bool _1607;\n        if (_1600)\n        {\n            _1607 = _1566 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1607 = _1600;\n        }\n        if (_1607)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1613 = _1556 > 3;\n        bool _1620;\n        if (_1613)\n        {\n            _1620 = _1566 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1620 = _1613;\n        }\n        if (_1620)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2516 = -_2516;\n    }\n    vec3 _2129 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing);\n    Surface _2137 = fa_standard_surface(param_1);\n    vec3 _2555 = _2137.albedo;\n    float _2556 = _2137.alpha;\n    vec3 _2557 = _2137.normal;\n    float _2558 = _2137.metallic;\n    float _2559 = _2137.roughness;\n    float _2560 = _2137.occlusion;\n    vec3 _2561 = _2137.emission;\n    float _2562 = _2137.clearcoat;\n    float _2563 = _2137.clearcoat_roughness;\n    vec3 _2564 = _2137.sheen_color;\n    float _2565 = _2137.sheen_roughness;\n    float _2566 = _2137.anisotropy;\n    float _2567 = _2137.anisotropy_rotation;\n    float _2568 = _2137.specular;\n    float _2569 = _2137.ior;\n    vec3 _2570 = _2137.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing);\n    Surface param_3 = _2137;\n    surface(param_2, param_3);\n    _2555 = param_3.albedo;\n    _2556 = param_3.alpha;\n    _2557 = param_3.normal;\n    _2558 = param_3.metallic;\n    _2559 = param_3.roughness;\n    _2560 = param_3.occlusion;\n    _2561 = param_3.emission;\n    _2562 = param_3.clearcoat;\n    _2563 = param_3.clearcoat_roughness;\n    _2564 = param_3.sheen_color;\n    _2565 = param_3.sheen_roughness;\n    _2566 = param_3.anisotropy;\n    _2567 = param_3.anisotropy_rotation;\n    _2568 = param_3.specular;\n    _2569 = param_3.ior;\n    _2570 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2555;\n    }\n    else\n    {\n        vec3 _2158 = _2557;\n        vec3 _2159 = normalize(_2158);\n        _2557 = _2159;\n        vec3 param_4 = _2159;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing);\n        Surface param_6 = Surface(_2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570);\n        vec3 param_7 = fa_ambient_light(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _2178 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2178; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            vec3 param_10 = fa_world_pos;\n            vec3 param_11 = _2516;\n            SurfaceInput param_12 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing);\n            Surface param_13 = Surface(_2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570);\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    vec3 _2215 = result;\n    vec3 _2216 = _2215 + _2561;\n    result = _2216;\n    vec3 param_15 = _2216;\n    vec3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2225 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2232;\n    if (!_2225)\n    {\n        _2232 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2232 = _2225;\n    }\n    if (_2232)\n    {\n        vec3 _2241 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2247 = dot(_2241, fa_mesh_fs_params[9].xyz);\n        bool _2251 = fa_mesh_fs_params[9].w > 0.5;\n        float _2252;\n        if (_2251)\n        {\n            _2252 = _2247;\n        }\n        else\n        {\n            _2252 = length(_2241);\n        }\n        float _2264 = _2252 - fa_mesh_fs_params[8].x;\n        if (_2264 > 0.0)\n        {\n            float _2273 = fa_mesh_fs_params[7].w * _2264;\n            float tau = _2273 * _2273;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2289;\n                if (_2251)\n                {\n                    _2289 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2247);\n                }\n                else\n                {\n                    _2289 = fa_mesh_fs_params[0].y;\n                }\n                float _2310 = mix(_2289, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2252, 0.0, 1.0));\n                float _2314 = fa_world_pos.y - _2310;\n                float _2319 = _2310 - fa_mesh_fs_params[8].z;\n                float _2324 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2327 = _2319 <= 0.0;\n                bool _2328 = !_2327;\n                bool _2334;\n                if (_2328)\n                {\n                    _2334 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2334 = _2327;\n                }\n                float _2335;\n                if (_2334)\n                {\n                    _2335 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2335 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2319, 80.0));\n                }\n                bool _2362;\n                if (_2328)\n                {\n                    _2362 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2362 = _2327;\n                }\n                float _2363;\n                if (_2362)\n                {\n                    _2363 = fa_mesh_fs_params[8].y * _2319;\n                }\n                else\n                {\n                    _2363 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2319, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2388 = _2324 <= 0.0;\n                bool _2395;\n                if (!_2388)\n                {\n                    _2395 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2395 = _2388;\n                }\n                float _2396;\n                if (_2395)\n                {\n                    _2396 = fa_mesh_fs_params[8].y * _2324;\n                }\n                else\n                {\n                    _2396 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2324, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2423;\n                if (abs(_2314) < 0.001000000047497451305389404296875)\n                {\n                    _2423 = _2335;\n                }\n                else\n                {\n                    _2423 = (_2396 - _2363) / _2314;\n                }\n                tau += (_2264 * max(_2423, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2556);\n}\n\n",
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
            "inst_name": "_394",
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
            "inst_name": "_630",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_386, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _399 = fa_mesh_fs_params[19].x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return ivec2(0);\n    }\n    vec4 _438 = vec4(world_pos, 1.0);\n    float _445 = dot(fa_mesh_fs_params[16], _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _467 = vec2(dot(fa_mesh_fs_params[14], _438), dot(fa_mesh_fs_params[15], _438)) / vec2(_445);\n    int _471 = int(fa_mesh_fs_params[18].x);\n    int _475 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _471 - 1);\n    vec4 _546 = fa_light_texel(param);\n    return ivec2(int(_546.x), int(_546.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1674 = fa_cluster_lookup(param);\n    fa_cl_slot = _1674.x;\n    fa_cl_local = _1674.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1810 = fa_linear_to_srgb(param);\n        c = _1810;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1818 = fa_srgb_to_linear(param_1);\n            c = _1818;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _175;\n    if (i.front_facing)\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    vec3 _199 = normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    vec3 _227 = normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    vec3 _230;\n    if (i.front_facing)\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1849 = fa_tex_fix(param_2, param_3);\n    vec4 _2792 = base_t;\n    _2792.x = _1849.x;\n    _2792.y = _1849.y;\n    _2792.z = _1849.z;\n    base_t = _2792;\n    vec4 _1863 = (_2792 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2707 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1895 = fa_tex_fix(param_6, param_7);\n        vec3 _1899 = (_1895 * 2.0) - vec3(1.0);\n        vec2 _1904 = _1899.xy * fa_mesh_fs_params[6].x;\n        vec3 _2800 = _1899;\n        _2800.x = _1904.x;\n        _2800.y = _1904.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2800;\n        _2707 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1933 = fa_tex_fix(param_12, param_13);\n    vec4 _2803 = mrt;\n    _2803.x = _1933.x;\n    _2803.y = _1933.y;\n    _2803.z = _1933.z;\n    mrt = _2803;\n    vec4 _1962 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _1962.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1974 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2004 = fa_tex_fix(param_20, param_21);\n    float _2712 = fa_mesh_fs_params[20].x;\n    float _2713 = fa_mesh_fs_params[20].y;\n    float _2716 = fa_mesh_fs_params[20].z;\n    float _2715 = fa_mesh_fs_params[21].w;\n    float _2718 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2712 *= _1974.y;\n            _2713 *= _1974.z;\n            _2715 *= _1962.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2716 *= mrt.x;\n            _2718 *= mrt.w;\n        }\n    }\n    return Surface(_1863.xyz, _1863.w, _2707, clamp(fa_mesh_fs_params[5].x * _1933.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1933.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1974.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2004), _2712, _2713, fa_mesh_fs_params[21].xyz, _2715, _2716, fa_mesh_fs_params[20].w, _2718, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _267 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _273 = fa_light_texel(param_1);\n    float _276 = _273.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _283 = _276 < 0.5;\n    vec3 l;\n    if (_283)\n    {\n        l = normalize(_267.xyz);\n    }\n    else\n    {\n        vec3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / vec3(max(_297, 9.9999997473787516355514526367188e-05));\n        float _312 = _297 / max(_267.w, 0.001000000047497451305389404296875);\n        float _318 = clamp(1.0 - (_312 * _312), 0.0, 1.0);\n        atten = _318 * _318;\n        if (_276 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _332 = fa_light_texel(param_2);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _349 = fa_light_texel(param_3);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5)\n            {\n                cos_inner = mix(_342, 1.0, 0.25);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _273.xyz * atten, atten, 1.0, dist, _380);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _620;\n    if (i == 0)\n    {\n        _620 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _636;\n        if (i == 1)\n        {\n            _636 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _644;\n            if (i == 2)\n            {\n                _644 = fa_shadows[24].z;\n            }\n            else\n            {\n                _644 = fa_shadows[24].w;\n            }\n            _636 = _644;\n        }\n        _620 = _636;\n    }\n    return _620;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _677 = fa_shadow_depth(param, param_1);\n    float _681;\n    if (conv.x < 0.5)\n    {\n        _681 = _677;\n    }\n    else\n    {\n        _681 = (conv.y * conv.z) / (conv.z - (_677 * (conv.z - conv.y)));\n    }\n    return _681;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _608 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_608), sin(_608)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _727 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _741 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _727;\n            vec2 _760 = fa_shadow_vogel(param_3, param_4, param_5) * _741;\n            vec2 param_6 = uv + (_760 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _772 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_772 < (zr - (length(_760) * plane)))\n            {\n                sum += _772;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _816 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _816; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _816;\n        float param_11 = _727;\n        vec2 _835 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_835 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_835) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_816);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _877 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _882 = clamp(dot(n, l), 0.0, 1.0);\n    float _888 = sqrt(1.0 - (_882 * _882));\n    float _896 = min(_888 / max(_882, 0.20000000298023223876953125), 4.0);\n    float _901;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _901 = fa_shadows[26].y;\n    }\n    else\n    {\n        _901 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _926 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_901 * _888)), 1.0);\n    float _933 = _926.x;\n    bool _936 = _933 < fa_shadows[ci * 1 + 16].x;\n    bool _945;\n    if (!_936)\n    {\n        _945 = _933 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _945 = _936;\n    }\n    bool _954;\n    if (!_945)\n    {\n        _954 = _926.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _954 = _945;\n    }\n    bool _963;\n    if (!_954)\n    {\n        _963 = _926.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _963 = _954;\n    }\n    bool _970;\n    if (!_963)\n    {\n        _970 = _926.z > 1.0;\n    }\n    else\n    {\n        _970 = _963;\n    }\n    if (_970)\n    {\n        return -1.0;\n    }\n    float _979;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _979 = fa_shadows[26].x;\n    }\n    else\n    {\n        _979 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _926.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _926.z - ((_979 * (1.0 + (0.5 * _896))) / _877);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _877;\n    float param_5 = _877 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_896, 3.0)) * 0.5) / _877;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1373 = int(fa_shadows[25].x + 0.5);\n    if (_1373 < 1)\n    {\n        return 1.0;\n    }\n    float _1389 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1373 - 1;\n    if (_1389 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1401 = _1373 > 1;\n    bool _1408;\n    if (_1401)\n    {\n        _1408 = _1389 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1408 = _1401;\n    }\n    if (_1408)\n    {\n        ci = 1;\n    }\n    bool _1412 = _1373 > 2;\n    bool _1419;\n    if (_1412)\n    {\n        _1419 = _1389 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1419 = _1412;\n    }\n    if (_1419)\n    {\n        ci = 2;\n    }\n    bool _1423 = _1373 > 3;\n    bool _1430;\n    if (_1423)\n    {\n        _1430 = _1389 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1430 = _1423;\n    }\n    if (_1430)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1373)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1456 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1456;\n        if (_1456 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1481;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1481 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1481 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1500 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1481, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1511 = clamp((_1389 - (fa_shadow_split_at(param_7) - _1500)) / _1500, 0.0, 1.0);\n        if (_1511 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1373)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1532 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1532;\n                if (_1532 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1511);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1038 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1046;\n    if (!_1038)\n    {\n        _1046 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1046 = _1038;\n    }\n    if (_1046)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1059 = fa_light_texel(param);\n    float _1060 = _1059.x;\n    if (_1060 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1069 = int(_1060 + 0.5);\n    int param_1 = _1069;\n    vec4 _1073 = fa_light_texel(param_1);\n    int param_2 = _1069 + 1;\n    vec4 _1078 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1081 = _1073.y;\n    if (_1081 > 0.0)\n    {\n        float _1098 = 1.0 - smoothstep(0.75 * _1081, _1081, length(world - fa_shadows[27].xyz));\n        fade = _1098;\n        if (_1098 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1073.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1117 = world - fa_light_texel(param_3).xyz;\n        vec3 _1120 = abs(_1117);\n        float _1122 = _1120.x;\n        float _1124 = _1120.y;\n        bool _1125 = _1122 >= _1124;\n        bool _1133;\n        if (_1125)\n        {\n            _1133 = _1122 >= _1120.z;\n        }\n        else\n        {\n            _1133 = _1125;\n        }\n        int _1134;\n        if (_1133)\n        {\n            _1134 = (_1117.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1147;\n            if (_1124 >= _1120.z)\n            {\n                _1147 = (_1117.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1147 = (_1117.z > 0.0) ? 4 : 5;\n            }\n            _1134 = _1147;\n        }\n        face = _1134;\n    }\n    int _1166 = (_1069 + 2) + (face * 6);\n    int param_4 = _1166;\n    int param_5 = _1166 + 1;\n    int param_6 = _1166 + 3;\n    vec4 _1180 = fa_light_texel(param_6);\n    int param_7 = _1166 + 4;\n    vec4 _1185 = fa_light_texel(param_7);\n    int param_8 = _1166 + 5;\n    vec4 _1190 = fa_light_texel(param_8);\n    float _1202 = _1190.x * max(dot(_1180, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1207 = clamp(dot(n, l), 0.0, 1.0);\n    float _1213 = sqrt(1.0 - (_1207 * _1207));\n    float _1219 = min(_1213 / max(_1207, 0.20000000298023223876953125), 4.0);\n    float _1222 = _1078.y;\n    float _1224;\n    if (_1222 > 0.0)\n    {\n        _1224 = _1222;\n    }\n    else\n    {\n        _1224 = 1.5 * _1202;\n    }\n    vec4 _1244 = vec4(world + (n * (_1224 * _1213)), 1.0);\n    float _1248 = dot(_1180, _1244);\n    float _1251 = _1190.y;\n    if (_1248 < _1251)\n    {\n        return 1.0;\n    }\n    vec2 _1266 = vec2(dot(fa_light_texel(param_4), _1244), dot(fa_light_texel(param_5), _1244)) / vec2(_1248);\n    float _1268 = _1266.x;\n    bool _1271 = _1268 < _1185.x;\n    bool _1280;\n    if (!_1271)\n    {\n        _1280 = _1268 > _1185.z;\n    }\n    else\n    {\n        _1280 = _1271;\n    }\n    bool _1289;\n    if (!_1280)\n    {\n        _1289 = _1266.y < _1185.y;\n    }\n    else\n    {\n        _1289 = _1280;\n    }\n    bool _1298;\n    if (!_1289)\n    {\n        _1298 = _1266.y > _1185.w;\n    }\n    else\n    {\n        _1298 = _1289;\n    }\n    if (_1298)\n    {\n        return 1.0;\n    }\n    float _1304 = _1078.x;\n    float _1306;\n    if (_1304 > 0.0)\n    {\n        _1306 = _1304;\n    }\n    else\n    {\n        _1306 = 1.5 * _1202;\n    }\n    vec2 param_9 = _1266;\n    vec4 param_10 = _1185;\n    float param_11 = _1248 - (_1306 * (1.0 + (0.5 * _1219)));\n    float param_12 = _1202;\n    float param_13 = 1.0;\n    float param_14 = _1190.z * 0.25;\n    float param_15 = (_1202 * min(_1219, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _1251, _1190.z);\n    int param_17 = int(_1073.z + 0.5);\n    float param_18 = _1073.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1702 = fa_light_sample(param, param_1);\n    vec3 _2692 = _1702.direction;\n    vec3 _2687 = _1702.color;\n    float _2694 = _1702.attenuation;\n    float _2689 = _1702.shadow;\n    int _2697 = _1702.type;\n    if ((_2697 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2692;\n        float _1716 = fa_shadow_factor(param_2, param_3);\n        _2689 = _1716;\n        _2687 *= _1716;\n    }\n    else\n    {\n        bool _1727 = _2697 != 0;\n        bool _1733;\n        if (_1727)\n        {\n            _1733 = _2694 > 0.0;\n        }\n        else\n        {\n            _1733 = _1727;\n        }\n        if (_1733)\n        {\n            int param_4 = li;\n            vec3 param_5 = world_pos;\n            vec3 param_6 = gn;\n            vec3 param_7 = _2692;\n            float _1745 = fa_shadow_local(param_4, param_5, param_6, param_7);\n            _2689 = _1745;\n            _2687 *= _1745;\n        }\n    }\n    return LightSample(_2692, _2687, _2694, _2689, _1702._distance, _2697);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1556 = int(fa_shadows[25].x + 0.5);\n    float _1566 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1571 = _1556 > 0;\n    bool _1580;\n    if (_1571)\n    {\n        int param = _1556 - 1;\n        _1580 = _1566 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1580 = _1571;\n    }\n    if (_1580)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1587 = _1556 > 1;\n        bool _1594;\n        if (_1587)\n        {\n            _1594 = _1566 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1594 = _1587;\n        }\n        if (_1594)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1600 = _1556 > 2;\n        bool _1607;\n        if (_1600)\n        {\n            _1607 = _1566 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1607 = _1600;\n        }\n        if (_1607)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1613 = _1556 > 3;\n        bool _1620;\n        if (_1613)\n        {\n            _1620 = _1566 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1620 = _1613;\n        }\n        if (_1620)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2516 = -_2516;\n    }\n    vec3 _2129 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing);\n    Surface _2137 = fa_standard_surface(param_1);\n    vec3 _2555 = _2137.albedo;\n    float _2556 = _2137.alpha;\n    vec3 _2557 = _2137.normal;\n    float _2558 = _2137.metallic;\n    float _2559 = _2137.roughness;\n    float _2560 = _2137.occlusion;\n    vec3 _2561 = _2137.emission;\n    float _2562 = _2137.clearcoat;\n    float _2563 = _2137.clearcoat_roughness;\n    vec3 _2564 = _2137.sheen_color;\n    float _2565 = _2137.sheen_roughness;\n    float _2566 = _2137.anisotropy;\n    float _2567 = _2137.anisotropy_rotation;\n    float _2568 = _2137.specular;\n    float _2569 = _2137.ior;\n    vec3 _2570 = _2137.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing);\n    Surface param_3 = _2137;\n    surface(param_2, param_3);\n    _2555 = param_3.albedo;\n    _2556 = param_3.alpha;\n    _2557 = param_3.normal;\n    _2558 = param_3.metallic;\n    _2559 = param_3.roughness;\n    _2560 = param_3.occlusion;\n    _2561 = param_3.emission;\n    _2562 = param_3.clearcoat;\n    _2563 = param_3.clearcoat_roughness;\n    _2564 = param_3.sheen_color;\n    _2565 = param_3.sheen_roughness;\n    _2566 = param_3.anisotropy;\n    _2567 = param_3.anisotropy_rotation;\n    _2568 = param_3.specular;\n    _2569 = param_3.ior;\n    _2570 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2555;\n    }\n    else\n    {\n        vec3 _2158 = _2557;\n        vec3 _2159 = normalize(_2158);\n        _2557 = _2159;\n        vec3 param_4 = _2159;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing);\n        Surface param_6 = Surface(_2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570);\n        vec3 param_7 = fa_ambient_light(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _2178 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2178; ln++)\n        {\n            int param_8 = ln;\n            int param_9 = fa_cl_light(param_8);\n            vec3 param_10 = fa_world_pos;\n            vec3 param_11 = _2516;\n            SurfaceInput param_12 = SurfaceInput(fa_world_pos, _2516, fa_world_tangent, fa_uv, fa_vertex_color, _2129, gl_FrontFacing);\n            Surface param_13 = Surface(_2555, _2556, _2557, _2558, _2559, _2560, _2561, _2562, _2563, _2564, _2565, _2566, _2567, _2568, _2569, _2570);\n            LightSample param_14 = fa_light_shadowed(param_9, param_10, param_11);\n            lit += light(param_12, param_13, param_14);\n        }\n        result = lit;\n    }\n    vec3 _2215 = result;\n    vec3 _2216 = _2215 + _2561;\n    result = _2216;\n    vec3 param_15 = _2216;\n    vec3 param_16 = fa_world_pos;\n    result = fa_shadow_debug(param_15, param_16);\n    bool _2225 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2232;\n    if (!_2225)\n    {\n        _2232 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2232 = _2225;\n    }\n    if (_2232)\n    {\n        vec3 _2241 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2247 = dot(_2241, fa_mesh_fs_params[9].xyz);\n        bool _2251 = fa_mesh_fs_params[9].w > 0.5;\n        float _2252;\n        if (_2251)\n        {\n            _2252 = _2247;\n        }\n        else\n        {\n            _2252 = length(_2241);\n        }\n        float _2264 = _2252 - fa_mesh_fs_params[8].x;\n        if (_2264 > 0.0)\n        {\n            float _2273 = fa_mesh_fs_params[7].w * _2264;\n            float tau = _2273 * _2273;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2289;\n                if (_2251)\n                {\n                    _2289 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2247);\n                }\n                else\n                {\n                    _2289 = fa_mesh_fs_params[0].y;\n                }\n                float _2310 = mix(_2289, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2252, 0.0, 1.0));\n                float _2314 = fa_world_pos.y - _2310;\n                float _2319 = _2310 - fa_mesh_fs_params[8].z;\n                float _2324 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2327 = _2319 <= 0.0;\n                bool _2328 = !_2327;\n                bool _2334;\n                if (_2328)\n                {\n                    _2334 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2334 = _2327;\n                }\n                float _2335;\n                if (_2334)\n                {\n                    _2335 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2335 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2319, 80.0));\n                }\n                bool _2362;\n                if (_2328)\n                {\n                    _2362 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2362 = _2327;\n                }\n                float _2363;\n                if (_2362)\n                {\n                    _2363 = fa_mesh_fs_params[8].y * _2319;\n                }\n                else\n                {\n                    _2363 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2319, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2388 = _2324 <= 0.0;\n                bool _2395;\n                if (!_2388)\n                {\n                    _2395 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2395 = _2388;\n                }\n                float _2396;\n                if (_2395)\n                {\n                    _2396 = fa_mesh_fs_params[8].y * _2324;\n                }\n                else\n                {\n                    _2396 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2324, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2423;\n                if (abs(_2314) < 0.001000000047497451305389404296875)\n                {\n                    _2423 = _2335;\n                }\n                else\n                {\n                    _2423 = (_2396 - _2363) / _2314;\n                }\n                tau += (_2264 * max(_2423, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2556);\n}\n\n",
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
            "inst_name": "_394",
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
            "inst_name": "_630",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _783 = base_t;\n    _783.x = _225.x;\n    _783.y = _225.y;\n    _783.z = _225.z;\n    base_t = _783;\n    vec4 _241 = (_783 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _791 = _279;\n        _791.x = _284.x;\n        _791.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _791;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _794 = mrt;\n    _794.x = _313.x;\n    _794.y = _313.y;\n    _794.z = _313.z;\n    mrt = _794;\n    vec4 _343 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _343.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _355 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _385 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _355.y;\n            _752 *= _355.z;\n            _754 *= _343.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_241.xyz, _241.w, _746, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_355.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _385), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _657 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _657 = -_657;\n    }\n    vec3 _519 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _657, fa_world_tangent, fa_uv, fa_vertex_color, _519, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _534 = normalize(param_2.normal);\n    vec3 _549 = normalize(vec3(dot(fa_pre_r0, _534), dot(fa_pre_r1, _534), dot(fa_pre_r2, _534)));\n    float _561 = _549.z;\n    vec2 e = _549.xy / vec2((abs(_549.x) + abs(_549.y)) + abs(_561));\n    if (_561 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
