{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "glsl430",
  "params": [
    "dark"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _420 = fa_mesh_fs_params[19].x < 0.0;\n    bool _427;\n    if (!_420)\n    {\n        _427 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return ivec2(0);\n    }\n    vec4 _459 = vec4(world_pos, 1.0);\n    float _466 = dot(fa_mesh_fs_params[16], _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _488 = vec2(dot(fa_mesh_fs_params[14], _459), dot(fa_mesh_fs_params[15], _459)) / vec2(_466);\n    int _492 = int(fa_mesh_fs_params[18].x);\n    int _496 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _492 - 1);\n    vec4 _567 = fa_light_texel(param);\n    return ivec2(int(_567.x), int(_567.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1729 = fa_cluster_lookup(param);\n    fa_cl_slot = _1729.x;\n    fa_cl_local = _1729.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1914 = fa_linear_to_srgb(param);\n        c = _1914;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1922 = fa_srgb_to_linear(param_1);\n            c = _1922;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _179;\n    if (i.front_facing)\n    {\n        _179 = i.world_normal;\n    }\n    else\n    {\n        _179 = -i.world_normal;\n    }\n    vec3 _203 = normalize(i.world_tangent.xyz - (_179 * dot(_179, i.world_tangent.xyz)));\n    vec3 _231 = normalize(((_203 * m.x) + ((cross(_179, _203) * i.world_tangent.w) * m.y)) + (_179 * m.z));\n    vec3 _234;\n    if (i.front_facing)\n    {\n        _234 = _231;\n    }\n    else\n    {\n        _234 = -_231;\n    }\n    return _234;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1953 = fa_tex_fix(param_2, param_3);\n    vec4 _2915 = base_t;\n    _2915.x = _1953.x;\n    _2915.y = _1953.y;\n    _2915.z = _1953.z;\n    base_t = _2915;\n    vec4 _1967 = (_2915 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2830 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1999 = fa_tex_fix(param_6, param_7);\n        vec3 _2003 = (_1999 * 2.0) - vec3(1.0);\n        vec2 _2008 = _2003.xy * fa_mesh_fs_params[6].x;\n        vec3 _2923 = _2003;\n        _2923.x = _2008.x;\n        _2923.y = _2008.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2923;\n        _2830 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2037 = fa_tex_fix(param_12, param_13);\n    vec4 _2926 = mrt;\n    _2926.x = _2037.x;\n    _2926.y = _2037.y;\n    _2926.z = _2037.z;\n    mrt = _2926;\n    vec4 _2066 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2066.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2078 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2108 = fa_tex_fix(param_20, param_21);\n    float _2835 = fa_mesh_fs_params[20].x;\n    float _2836 = fa_mesh_fs_params[20].y;\n    float _2839 = fa_mesh_fs_params[20].z;\n    float _2838 = fa_mesh_fs_params[21].w;\n    float _2841 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2835 *= _2078.y;\n            _2836 *= _2078.z;\n            _2838 *= _2066.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2839 *= mrt.x;\n            _2841 *= mrt.w;\n        }\n    }\n    return Surface(_1967.xyz, _1967.w, _2830, clamp(fa_mesh_fs_params[5].x * _2037.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2037.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2078.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2108), _2835, _2836, fa_mesh_fs_params[21].xyz, _2838, _2839, fa_mesh_fs_params[20].w, _2841, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _290 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _296 = fa_light_texel(param_1);\n    float _299 = _296.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _305 = _299 < 0.5;\n    vec3 l;\n    if (_305)\n    {\n        l = normalize(_290.xyz);\n    }\n    else\n    {\n        vec3 _317 = _290.xyz - world_pos;\n        float _319 = length(_317);\n        dist = _319;\n        l = _317 / vec3(max(_319, 9.9999997473787516355514526367188e-05));\n        float _334 = _319 / max(_290.w, 0.001000000047497451305389404296875);\n        float _340 = clamp(1.0 - (_334 * _334), 0.0, 1.0);\n        atten = _340 * _340;\n        if (_299 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _354 = fa_light_texel(param_2);\n            float _364 = _354.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_364, 1.0, 0.25);\n            }\n            atten *= smoothstep(_364, cos_inner, dot(-l, normalize(_354.xyz)));\n        }\n    }\n    int _401;\n    if (_305)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_299 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _296.xyz * atten, atten, 1.0, dist, _401);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _641;\n    if (i == 0)\n    {\n        _641 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _657;\n        if (i == 1)\n        {\n            _657 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _665;\n            if (i == 2)\n            {\n                _665 = fa_shadows[24].z;\n            }\n            else\n            {\n                _665 = fa_shadows[24].w;\n            }\n            _657 = _665;\n        }\n        _641 = _657;\n    }\n    return _641;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _698 = fa_shadow_depth(param, param_1);\n    float _702;\n    if (conv.x < 0.5)\n    {\n        _702 = _698;\n    }\n    else\n    {\n        _702 = (conv.y * conv.z) / (conv.z - (_698 * (conv.z - conv.y)));\n    }\n    return _702;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _629 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_629), sin(_629)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _748 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _762 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _748;\n            vec2 _781 = fa_shadow_vogel(param_3, param_4, param_5) * _762;\n            vec2 param_6 = uv + (_781 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _793 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_793 < (zr - (length(_781) * plane)))\n            {\n                sum += _793;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _837 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _837; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _837;\n        float param_11 = _748;\n        vec2 _856 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_856 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_856) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_837);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _898 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _903 = clamp(dot(n, l), 0.0, 1.0);\n    float _909 = sqrt(1.0 - (_903 * _903));\n    float _917 = min(_909 / max(_903, 0.20000000298023223876953125), 4.0);\n    float _922;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _922 = fa_shadows[26].y;\n    }\n    else\n    {\n        _922 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _947 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_922 * _909)), 1.0);\n    float _954 = _947.x;\n    bool _957 = _954 < fa_shadows[ci * 1 + 16].x;\n    bool _966;\n    if (!_957)\n    {\n        _966 = _954 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _966 = _957;\n    }\n    bool _975;\n    if (!_966)\n    {\n        _975 = _947.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _975 = _966;\n    }\n    bool _984;\n    if (!_975)\n    {\n        _984 = _947.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _984 = _975;\n    }\n    bool _991;\n    if (!_984)\n    {\n        _991 = _947.z > 1.0;\n    }\n    else\n    {\n        _991 = _984;\n    }\n    if (_991)\n    {\n        return -1.0;\n    }\n    float _1000;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1000 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1000 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _947.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _947.z - ((_1000 * (1.0 + (0.5 * _917))) / _898);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _898;\n    float param_5 = _898 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_917, 3.0)) * 0.5) / _898;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1428 = int(fa_shadows[25].x + 0.5);\n    if (_1428 < 1)\n    {\n        return 1.0;\n    }\n    float _1444 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1428 - 1;\n    if (_1444 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1456 = _1428 > 1;\n    bool _1463;\n    if (_1456)\n    {\n        _1463 = _1444 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1463 = _1456;\n    }\n    if (_1463)\n    {\n        ci = 1;\n    }\n    bool _1467 = _1428 > 2;\n    bool _1474;\n    if (_1467)\n    {\n        _1474 = _1444 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1474 = _1467;\n    }\n    if (_1474)\n    {\n        ci = 2;\n    }\n    bool _1478 = _1428 > 3;\n    bool _1485;\n    if (_1478)\n    {\n        _1485 = _1444 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1485 = _1478;\n    }\n    if (_1485)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1428)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1511 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1511;\n        if (_1511 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1536;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1536 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1536 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1555 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1536, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1566 = clamp((_1444 - (fa_shadow_split_at(param_7) - _1555)) / _1555, 0.0, 1.0);\n        if (_1566 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1428)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1587 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1587;\n                if (_1587 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1566);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1059 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1067;\n    if (!_1059)\n    {\n        _1067 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1067 = _1059;\n    }\n    if (_1067)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1080 = fa_light_texel(param);\n    float _1081 = _1080.x;\n    if (_1081 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1090 = int(_1081 + 0.5);\n    int param_1 = _1090;\n    vec4 _1094 = fa_light_texel(param_1);\n    int param_2 = _1090 + 1;\n    vec4 _1099 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1102 = _1094.y;\n    if (_1102 > 0.0)\n    {\n        float _1119 = 1.0 - smoothstep(0.75 * _1102, _1102, length(world - fa_shadows[27].xyz));\n        fade = _1119;\n        if (_1119 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1094.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1138 = world - fa_light_texel(param_3).xyz;\n        vec3 _1141 = abs(_1138);\n        float _1143 = _1141.x;\n        float _1145 = _1141.y;\n        bool _1146 = _1143 >= _1145;\n        bool _1154;\n        if (_1146)\n        {\n            _1154 = _1143 >= _1141.z;\n        }\n        else\n        {\n            _1154 = _1146;\n        }\n        int _1155;\n        if (_1154)\n        {\n            _1155 = (_1138.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1168;\n            if (_1145 >= _1141.z)\n            {\n                _1168 = (_1138.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1168 = (_1138.z > 0.0) ? 4 : 5;\n            }\n            _1155 = _1168;\n        }\n        face = _1155;\n    }\n    int _1187 = (_1090 + 2) + (face * 6);\n    int param_4 = _1187;\n    int param_5 = _1187 + 1;\n    int param_6 = _1187 + 3;\n    vec4 _1201 = fa_light_texel(param_6);\n    int param_7 = _1187 + 4;\n    vec4 _1206 = fa_light_texel(param_7);\n    int param_8 = _1187 + 5;\n    vec4 _1211 = fa_light_texel(param_8);\n    float _1223 = _1211.x * max(dot(_1201, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1228 = clamp(dot(n, l), 0.0, 1.0);\n    float _1251 = clamp(dot(n, _1201.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1274 = min(sqrt(1.0 - (_1251 * _1251)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1201, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1277 = _1099.y;\n    float _1279;\n    if (_1277 > 0.0)\n    {\n        _1279 = _1277;\n    }\n    else\n    {\n        _1279 = 1.5 * _1223;\n    }\n    vec4 _1299 = vec4(world + (n * (_1279 * sqrt(1.0 - (_1228 * _1228)))), 1.0);\n    float _1303 = dot(_1201, _1299);\n    float _1306 = _1211.y;\n    if (_1303 < _1306)\n    {\n        return 1.0;\n    }\n    vec2 _1321 = vec2(dot(fa_light_texel(param_4), _1299), dot(fa_light_texel(param_5), _1299)) / vec2(_1303);\n    float _1323 = _1321.x;\n    bool _1326 = _1323 < _1206.x;\n    bool _1335;\n    if (!_1326)\n    {\n        _1335 = _1323 > _1206.z;\n    }\n    else\n    {\n        _1335 = _1326;\n    }\n    bool _1344;\n    if (!_1335)\n    {\n        _1344 = _1321.y < _1206.y;\n    }\n    else\n    {\n        _1344 = _1335;\n    }\n    bool _1353;\n    if (!_1344)\n    {\n        _1353 = _1321.y > _1206.w;\n    }\n    else\n    {\n        _1353 = _1344;\n    }\n    if (_1353)\n    {\n        return 1.0;\n    }\n    float _1359 = _1099.x;\n    float _1361;\n    if (_1359 > 0.0)\n    {\n        _1361 = _1359;\n    }\n    else\n    {\n        _1361 = 1.5 * _1223;\n    }\n    vec2 param_10 = _1321;\n    vec4 param_11 = _1206;\n    float param_12 = _1303 - (_1361 * (1.0 + (0.5 * _1274)));\n    float param_13 = _1223;\n    float param_14 = 1.0;\n    float param_15 = _1211.z * 0.25;\n    float param_16 = (_1223 * min(_1274, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1306, _1211.z);\n    int param_18 = int(_1094.z + 0.5);\n    float param_19 = _1094.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _1756 = fa_lm.z > 0.5;\n    bool _1762;\n    if (_1756)\n    {\n        int param = li;\n        _1762 = fa_light_baked(param);\n    }\n    else\n    {\n        _1762 = _1756;\n    }\n    if (_1762)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _1785 = fa_light_sample(param_2, param_3);\n    vec3 _2815 = _1785.direction;\n    vec3 _2810 = _1785.color;\n    float _2817 = _1785.attenuation;\n    float _2812 = _1785.shadow;\n    int _2820 = _1785.type;\n    if ((_2820 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _2815;\n        float _1799 = fa_shadow_factor(param_4, param_5);\n        _2812 = _1799;\n        _2810 *= _1799;\n    }\n    else\n    {\n        bool _1810 = _2820 != 0;\n        bool _1816;\n        if (_1810)\n        {\n            _1816 = _2817 > 0.0;\n        }\n        else\n        {\n            _1816 = _1810;\n        }\n        if (_1816)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _2815;\n            float _1828 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _2812 = _1828;\n            _2810 *= _1828;\n        }\n    }\n    return LightSample(_2815, _2810, _2817, _2812, _1785._distance, _2820);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1848;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1848 = 1.0;\n    }\n    else\n    {\n        _1848 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _1848;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1611 = int(fa_shadows[25].x + 0.5);\n    float _1621 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1626 = _1611 > 0;\n    bool _1635;\n    if (_1626)\n    {\n        int param = _1611 - 1;\n        _1635 = _1621 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1635 = _1626;\n    }\n    if (_1635)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1642 = _1611 > 1;\n        bool _1649;\n        if (_1642)\n        {\n            _1649 = _1621 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1649 = _1642;\n        }\n        if (_1649)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1655 = _1611 > 2;\n        bool _1662;\n        if (_1655)\n        {\n            _1662 = _1621 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1662 = _1655;\n        }\n        if (_1662)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1668 = _1611 > 3;\n        bool _1675;\n        if (_1668)\n        {\n            _1675 = _1621 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1675 = _1668;\n        }\n        if (_1675)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2651 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2651 = -_2651;\n    }\n    vec3 _2252 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2651, fa_world_tangent, fa_uv, fa_vertex_color, _2252, gl_FrontFacing);\n    Surface _2260 = fa_standard_surface(param_1);\n    vec3 _2682 = _2260.albedo;\n    float _2683 = _2260.alpha;\n    vec3 _2684 = _2260.normal;\n    float _2685 = _2260.metallic;\n    float _2686 = _2260.roughness;\n    float _2687 = _2260.occlusion;\n    vec3 _2688 = _2260.emission;\n    float _2689 = _2260.clearcoat;\n    float _2690 = _2260.clearcoat_roughness;\n    vec3 _2691 = _2260.sheen_color;\n    float _2692 = _2260.sheen_roughness;\n    float _2693 = _2260.anisotropy;\n    float _2694 = _2260.anisotropy_rotation;\n    float _2695 = _2260.specular;\n    float _2696 = _2260.ior;\n    vec3 _2697 = _2260.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2651, fa_world_tangent, fa_uv, fa_vertex_color, _2252, gl_FrontFacing);\n    Surface param_3 = _2260;\n    surface(param_2, param_3);\n    _2682 = param_3.albedo;\n    _2683 = param_3.alpha;\n    _2684 = param_3.normal;\n    _2685 = param_3.metallic;\n    _2686 = param_3.roughness;\n    _2687 = param_3.occlusion;\n    _2688 = param_3.emission;\n    _2689 = param_3.clearcoat;\n    _2690 = param_3.clearcoat_roughness;\n    _2691 = param_3.sheen_color;\n    _2692 = param_3.sheen_roughness;\n    _2693 = param_3.anisotropy;\n    _2694 = param_3.anisotropy_rotation;\n    _2695 = param_3.specular;\n    _2696 = param_3.ior;\n    _2697 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2682;\n    }\n    else\n    {\n        vec3 _2281 = _2684;\n        vec3 _2282 = normalize(_2281);\n        _2684 = _2282;\n        vec3 param_4 = _2282;\n        vec3 lit = (fa_indirect_diffuse(param_4) * _2682) * _2687;\n        int _2301 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2301; ln++)\n        {\n            int param_5 = ln;\n            int _2314 = fa_cl_light(param_5);\n            bool _2317 = fa_lm.z > 0.5;\n            bool _2323;\n            if (_2317)\n            {\n                int param_6 = _2314;\n                _2323 = fa_light_baked(param_6);\n            }\n            else\n            {\n                _2323 = _2317;\n            }\n            if (_2323)\n            {\n                continue;\n            }\n            int param_7 = _2314;\n            vec3 param_8 = fa_world_pos;\n            vec3 param_9 = _2651;\n            SurfaceInput param_10 = SurfaceInput(fa_world_pos, _2651, fa_world_tangent, fa_uv, fa_vertex_color, _2252, gl_FrontFacing);\n            Surface param_11 = Surface(_2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690, _2691, _2692, _2693, _2694, _2695, _2696, _2697);\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9);\n            lit += light(param_10, param_11, param_12);\n        }\n        result = lit;\n    }\n    vec3 _2350 = result;\n    vec3 _2351 = _2350 + _2688;\n    result = _2351;\n    vec3 param_13 = _2351;\n    vec3 param_14 = fa_world_pos;\n    result = fa_shadow_debug(param_13, param_14);\n    bool _2360 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2367;\n    if (!_2360)\n    {\n        _2367 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2367 = _2360;\n    }\n    if (_2367)\n    {\n        vec3 _2376 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2382 = dot(_2376, fa_mesh_fs_params[9].xyz);\n        bool _2386 = fa_mesh_fs_params[9].w > 0.5;\n        float _2387;\n        if (_2386)\n        {\n            _2387 = _2382;\n        }\n        else\n        {\n            _2387 = length(_2376);\n        }\n        float _2399 = _2387 - fa_mesh_fs_params[8].x;\n        if (_2399 > 0.0)\n        {\n            float _2408 = fa_mesh_fs_params[7].w * _2399;\n            float tau = _2408 * _2408;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2424;\n                if (_2386)\n                {\n                    _2424 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2382);\n                }\n                else\n                {\n                    _2424 = fa_mesh_fs_params[0].y;\n                }\n                float _2445 = mix(_2424, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2387, 0.0, 1.0));\n                float _2449 = fa_world_pos.y - _2445;\n                float _2454 = _2445 - fa_mesh_fs_params[8].z;\n                float _2459 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2462 = _2454 <= 0.0;\n                bool _2463 = !_2462;\n                bool _2469;\n                if (_2463)\n                {\n                    _2469 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2469 = _2462;\n                }\n                float _2470;\n                if (_2469)\n                {\n                    _2470 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2470 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2454, 80.0));\n                }\n                bool _2497;\n                if (_2463)\n                {\n                    _2497 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2497 = _2462;\n                }\n                float _2498;\n                if (_2497)\n                {\n                    _2498 = fa_mesh_fs_params[8].y * _2454;\n                }\n                else\n                {\n                    _2498 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2454, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2523 = _2459 <= 0.0;\n                bool _2530;\n                if (!_2523)\n                {\n                    _2530 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2530 = _2523;\n                }\n                float _2531;\n                if (_2530)\n                {\n                    _2531 = fa_mesh_fs_params[8].y * _2459;\n                }\n                else\n                {\n                    _2531 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2459, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2558;\n                if (abs(_2449) < 0.001000000047497451305389404296875)\n                {\n                    _2558 = _2470;\n                }\n                else\n                {\n                    _2558 = (_2531 - _2498) / _2449;\n                }\n                tau += (_2399 * max(_2558, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2683);\n}\n\n",
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
            "inst_name": "_415",
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
            "inst_name": "_651",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1854",
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
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _420 = fa_mesh_fs_params[19].x < 0.0;\n    bool _427;\n    if (!_420)\n    {\n        _427 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _427 = _420;\n    }\n    bool _435;\n    if (!_427)\n    {\n        _435 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    bool _442;\n    if (!_435)\n    {\n        _442 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _442 = _435;\n    }\n    bool _449;\n    if (!_442)\n    {\n        _449 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _449 = _442;\n    }\n    if (_449)\n    {\n        return ivec2(0);\n    }\n    vec4 _459 = vec4(world_pos, 1.0);\n    float _466 = dot(fa_mesh_fs_params[16], _459);\n    if (!(_466 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _488 = vec2(dot(fa_mesh_fs_params[14], _459), dot(fa_mesh_fs_params[15], _459)) / vec2(_466);\n    int _492 = int(fa_mesh_fs_params[18].x);\n    int _496 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _496) + clamp(int(floor(((_488.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _496 - 1)) * _492)) + clamp(int(floor(((_488.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _492 - 1);\n    vec4 _567 = fa_light_texel(param);\n    return ivec2(int(_567.x), int(_567.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1729 = fa_cluster_lookup(param);\n    fa_cl_slot = _1729.x;\n    fa_cl_local = _1729.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1914 = fa_linear_to_srgb(param);\n        c = _1914;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1922 = fa_srgb_to_linear(param_1);\n            c = _1922;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _179;\n    if (i.front_facing)\n    {\n        _179 = i.world_normal;\n    }\n    else\n    {\n        _179 = -i.world_normal;\n    }\n    vec3 _203 = normalize(i.world_tangent.xyz - (_179 * dot(_179, i.world_tangent.xyz)));\n    vec3 _231 = normalize(((_203 * m.x) + ((cross(_179, _203) * i.world_tangent.w) * m.y)) + (_179 * m.z));\n    vec3 _234;\n    if (i.front_facing)\n    {\n        _234 = _231;\n    }\n    else\n    {\n        _234 = -_231;\n    }\n    return _234;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1953 = fa_tex_fix(param_2, param_3);\n    vec4 _2915 = base_t;\n    _2915.x = _1953.x;\n    _2915.y = _1953.y;\n    _2915.z = _1953.z;\n    base_t = _2915;\n    vec4 _1967 = (_2915 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2830 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1999 = fa_tex_fix(param_6, param_7);\n        vec3 _2003 = (_1999 * 2.0) - vec3(1.0);\n        vec2 _2008 = _2003.xy * fa_mesh_fs_params[6].x;\n        vec3 _2923 = _2003;\n        _2923.x = _2008.x;\n        _2923.y = _2008.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2923;\n        _2830 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2037 = fa_tex_fix(param_12, param_13);\n    vec4 _2926 = mrt;\n    _2926.x = _2037.x;\n    _2926.y = _2037.y;\n    _2926.z = _2037.z;\n    mrt = _2926;\n    vec4 _2066 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2066.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2078 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2108 = fa_tex_fix(param_20, param_21);\n    float _2835 = fa_mesh_fs_params[20].x;\n    float _2836 = fa_mesh_fs_params[20].y;\n    float _2839 = fa_mesh_fs_params[20].z;\n    float _2838 = fa_mesh_fs_params[21].w;\n    float _2841 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2835 *= _2078.y;\n            _2836 *= _2078.z;\n            _2838 *= _2066.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2839 *= mrt.x;\n            _2841 *= mrt.w;\n        }\n    }\n    return Surface(_1967.xyz, _1967.w, _2830, clamp(fa_mesh_fs_params[5].x * _2037.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2037.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2078.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2108), _2835, _2836, fa_mesh_fs_params[21].xyz, _2838, _2839, fa_mesh_fs_params[20].w, _2841, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _290 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _296 = fa_light_texel(param_1);\n    float _299 = _296.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _305 = _299 < 0.5;\n    vec3 l;\n    if (_305)\n    {\n        l = normalize(_290.xyz);\n    }\n    else\n    {\n        vec3 _317 = _290.xyz - world_pos;\n        float _319 = length(_317);\n        dist = _319;\n        l = _317 / vec3(max(_319, 9.9999997473787516355514526367188e-05));\n        float _334 = _319 / max(_290.w, 0.001000000047497451305389404296875);\n        float _340 = clamp(1.0 - (_334 * _334), 0.0, 1.0);\n        atten = _340 * _340;\n        if (_299 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _354 = fa_light_texel(param_2);\n            float _364 = _354.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _370 = fa_light_texel(param_3);\n            float _371 = _370.x;\n            float cos_inner = _371;\n            if (_371 > 1.5)\n            {\n                cos_inner = mix(_364, 1.0, 0.25);\n            }\n            atten *= smoothstep(_364, cos_inner, dot(-l, normalize(_354.xyz)));\n        }\n    }\n    int _401;\n    if (_305)\n    {\n        _401 = 0;\n    }\n    else\n    {\n        _401 = (_299 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _296.xyz * atten, atten, 1.0, dist, _401);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _641;\n    if (i == 0)\n    {\n        _641 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _657;\n        if (i == 1)\n        {\n            _657 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _665;\n            if (i == 2)\n            {\n                _665 = fa_shadows[24].z;\n            }\n            else\n            {\n                _665 = fa_shadows[24].w;\n            }\n            _657 = _665;\n        }\n        _641 = _657;\n    }\n    return _641;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _698 = fa_shadow_depth(param, param_1);\n    float _702;\n    if (conv.x < 0.5)\n    {\n        _702 = _698;\n    }\n    else\n    {\n        _702 = (conv.y * conv.z) / (conv.z - (_698 * (conv.z - conv.y)));\n    }\n    return _702;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _629 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_629), sin(_629)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _748 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _762 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _748;\n            vec2 _781 = fa_shadow_vogel(param_3, param_4, param_5) * _762;\n            vec2 param_6 = uv + (_781 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _793 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_793 < (zr - (length(_781) * plane)))\n            {\n                sum += _793;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _837 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _837; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _837;\n        float param_11 = _748;\n        vec2 _856 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_856 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_856) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_837);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _898 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _903 = clamp(dot(n, l), 0.0, 1.0);\n    float _909 = sqrt(1.0 - (_903 * _903));\n    float _917 = min(_909 / max(_903, 0.20000000298023223876953125), 4.0);\n    float _922;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _922 = fa_shadows[26].y;\n    }\n    else\n    {\n        _922 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _947 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_922 * _909)), 1.0);\n    float _954 = _947.x;\n    bool _957 = _954 < fa_shadows[ci * 1 + 16].x;\n    bool _966;\n    if (!_957)\n    {\n        _966 = _954 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _966 = _957;\n    }\n    bool _975;\n    if (!_966)\n    {\n        _975 = _947.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _975 = _966;\n    }\n    bool _984;\n    if (!_975)\n    {\n        _984 = _947.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _984 = _975;\n    }\n    bool _991;\n    if (!_984)\n    {\n        _991 = _947.z > 1.0;\n    }\n    else\n    {\n        _991 = _984;\n    }\n    if (_991)\n    {\n        return -1.0;\n    }\n    float _1000;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1000 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1000 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _947.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _947.z - ((_1000 * (1.0 + (0.5 * _917))) / _898);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _898;\n    float param_5 = _898 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_917, 3.0)) * 0.5) / _898;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1428 = int(fa_shadows[25].x + 0.5);\n    if (_1428 < 1)\n    {\n        return 1.0;\n    }\n    float _1444 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1428 - 1;\n    if (_1444 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1456 = _1428 > 1;\n    bool _1463;\n    if (_1456)\n    {\n        _1463 = _1444 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1463 = _1456;\n    }\n    if (_1463)\n    {\n        ci = 1;\n    }\n    bool _1467 = _1428 > 2;\n    bool _1474;\n    if (_1467)\n    {\n        _1474 = _1444 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1474 = _1467;\n    }\n    if (_1474)\n    {\n        ci = 2;\n    }\n    bool _1478 = _1428 > 3;\n    bool _1485;\n    if (_1478)\n    {\n        _1485 = _1444 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1485 = _1478;\n    }\n    if (_1485)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1428)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1511 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1511;\n        if (_1511 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1536;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1536 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1536 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1555 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1536, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1566 = clamp((_1444 - (fa_shadow_split_at(param_7) - _1555)) / _1555, 0.0, 1.0);\n        if (_1566 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1428)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1587 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1587;\n                if (_1587 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1566);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1059 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1067;\n    if (!_1059)\n    {\n        _1067 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1067 = _1059;\n    }\n    if (_1067)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1080 = fa_light_texel(param);\n    float _1081 = _1080.x;\n    if (_1081 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1090 = int(_1081 + 0.5);\n    int param_1 = _1090;\n    vec4 _1094 = fa_light_texel(param_1);\n    int param_2 = _1090 + 1;\n    vec4 _1099 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1102 = _1094.y;\n    if (_1102 > 0.0)\n    {\n        float _1119 = 1.0 - smoothstep(0.75 * _1102, _1102, length(world - fa_shadows[27].xyz));\n        fade = _1119;\n        if (_1119 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1094.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1138 = world - fa_light_texel(param_3).xyz;\n        vec3 _1141 = abs(_1138);\n        float _1143 = _1141.x;\n        float _1145 = _1141.y;\n        bool _1146 = _1143 >= _1145;\n        bool _1154;\n        if (_1146)\n        {\n            _1154 = _1143 >= _1141.z;\n        }\n        else\n        {\n            _1154 = _1146;\n        }\n        int _1155;\n        if (_1154)\n        {\n            _1155 = (_1138.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1168;\n            if (_1145 >= _1141.z)\n            {\n                _1168 = (_1138.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1168 = (_1138.z > 0.0) ? 4 : 5;\n            }\n            _1155 = _1168;\n        }\n        face = _1155;\n    }\n    int _1187 = (_1090 + 2) + (face * 6);\n    int param_4 = _1187;\n    int param_5 = _1187 + 1;\n    int param_6 = _1187 + 3;\n    vec4 _1201 = fa_light_texel(param_6);\n    int param_7 = _1187 + 4;\n    vec4 _1206 = fa_light_texel(param_7);\n    int param_8 = _1187 + 5;\n    vec4 _1211 = fa_light_texel(param_8);\n    float _1223 = _1211.x * max(dot(_1201, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1228 = clamp(dot(n, l), 0.0, 1.0);\n    float _1251 = clamp(dot(n, _1201.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1274 = min(sqrt(1.0 - (_1251 * _1251)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1201, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1277 = _1099.y;\n    float _1279;\n    if (_1277 > 0.0)\n    {\n        _1279 = _1277;\n    }\n    else\n    {\n        _1279 = 1.5 * _1223;\n    }\n    vec4 _1299 = vec4(world + (n * (_1279 * sqrt(1.0 - (_1228 * _1228)))), 1.0);\n    float _1303 = dot(_1201, _1299);\n    float _1306 = _1211.y;\n    if (_1303 < _1306)\n    {\n        return 1.0;\n    }\n    vec2 _1321 = vec2(dot(fa_light_texel(param_4), _1299), dot(fa_light_texel(param_5), _1299)) / vec2(_1303);\n    float _1323 = _1321.x;\n    bool _1326 = _1323 < _1206.x;\n    bool _1335;\n    if (!_1326)\n    {\n        _1335 = _1323 > _1206.z;\n    }\n    else\n    {\n        _1335 = _1326;\n    }\n    bool _1344;\n    if (!_1335)\n    {\n        _1344 = _1321.y < _1206.y;\n    }\n    else\n    {\n        _1344 = _1335;\n    }\n    bool _1353;\n    if (!_1344)\n    {\n        _1353 = _1321.y > _1206.w;\n    }\n    else\n    {\n        _1353 = _1344;\n    }\n    if (_1353)\n    {\n        return 1.0;\n    }\n    float _1359 = _1099.x;\n    float _1361;\n    if (_1359 > 0.0)\n    {\n        _1361 = _1359;\n    }\n    else\n    {\n        _1361 = 1.5 * _1223;\n    }\n    vec2 param_10 = _1321;\n    vec4 param_11 = _1206;\n    float param_12 = _1303 - (_1361 * (1.0 + (0.5 * _1274)));\n    float param_13 = _1223;\n    float param_14 = 1.0;\n    float param_15 = _1211.z * 0.25;\n    float param_16 = (_1223 * min(_1274, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1306, _1211.z);\n    int param_18 = int(_1094.z + 0.5);\n    float param_19 = _1094.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _1756 = fa_lm.z > 0.5;\n    bool _1762;\n    if (_1756)\n    {\n        int param = li;\n        _1762 = fa_light_baked(param);\n    }\n    else\n    {\n        _1762 = _1756;\n    }\n    if (_1762)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _1785 = fa_light_sample(param_2, param_3);\n    vec3 _2815 = _1785.direction;\n    vec3 _2810 = _1785.color;\n    float _2817 = _1785.attenuation;\n    float _2812 = _1785.shadow;\n    int _2820 = _1785.type;\n    if ((_2820 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _2815;\n        float _1799 = fa_shadow_factor(param_4, param_5);\n        _2812 = _1799;\n        _2810 *= _1799;\n    }\n    else\n    {\n        bool _1810 = _2820 != 0;\n        bool _1816;\n        if (_1810)\n        {\n            _1816 = _2817 > 0.0;\n        }\n        else\n        {\n            _1816 = _1810;\n        }\n        if (_1816)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _2815;\n            float _1828 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _2812 = _1828;\n            _2810 *= _1828;\n        }\n    }\n    return LightSample(_2815, _2810, _2817, _2812, _1785._distance, _2820);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    float _1848;\n    if (dot(s.normal, l.direction) > 0.5)\n    {\n        _1848 = 1.0;\n    }\n    else\n    {\n        _1848 = fa_material[0].x;\n    }\n    return (s.albedo * l.color) * _1848;\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1611 = int(fa_shadows[25].x + 0.5);\n    float _1621 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1626 = _1611 > 0;\n    bool _1635;\n    if (_1626)\n    {\n        int param = _1611 - 1;\n        _1635 = _1621 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1635 = _1626;\n    }\n    if (_1635)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1642 = _1611 > 1;\n        bool _1649;\n        if (_1642)\n        {\n            _1649 = _1621 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1649 = _1642;\n        }\n        if (_1649)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1655 = _1611 > 2;\n        bool _1662;\n        if (_1655)\n        {\n            _1662 = _1621 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1662 = _1655;\n        }\n        if (_1662)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1668 = _1611 > 3;\n        bool _1675;\n        if (_1668)\n        {\n            _1675 = _1621 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1675 = _1668;\n        }\n        if (_1675)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2651 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2651 = -_2651;\n    }\n    vec3 _2252 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2651, fa_world_tangent, fa_uv, fa_vertex_color, _2252, gl_FrontFacing);\n    Surface _2260 = fa_standard_surface(param_1);\n    vec3 _2682 = _2260.albedo;\n    float _2683 = _2260.alpha;\n    vec3 _2684 = _2260.normal;\n    float _2685 = _2260.metallic;\n    float _2686 = _2260.roughness;\n    float _2687 = _2260.occlusion;\n    vec3 _2688 = _2260.emission;\n    float _2689 = _2260.clearcoat;\n    float _2690 = _2260.clearcoat_roughness;\n    vec3 _2691 = _2260.sheen_color;\n    float _2692 = _2260.sheen_roughness;\n    float _2693 = _2260.anisotropy;\n    float _2694 = _2260.anisotropy_rotation;\n    float _2695 = _2260.specular;\n    float _2696 = _2260.ior;\n    vec3 _2697 = _2260.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2651, fa_world_tangent, fa_uv, fa_vertex_color, _2252, gl_FrontFacing);\n    Surface param_3 = _2260;\n    surface(param_2, param_3);\n    _2682 = param_3.albedo;\n    _2683 = param_3.alpha;\n    _2684 = param_3.normal;\n    _2685 = param_3.metallic;\n    _2686 = param_3.roughness;\n    _2687 = param_3.occlusion;\n    _2688 = param_3.emission;\n    _2689 = param_3.clearcoat;\n    _2690 = param_3.clearcoat_roughness;\n    _2691 = param_3.sheen_color;\n    _2692 = param_3.sheen_roughness;\n    _2693 = param_3.anisotropy;\n    _2694 = param_3.anisotropy_rotation;\n    _2695 = param_3.specular;\n    _2696 = param_3.ior;\n    _2697 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2682;\n    }\n    else\n    {\n        vec3 _2281 = _2684;\n        vec3 _2282 = normalize(_2281);\n        _2684 = _2282;\n        vec3 param_4 = _2282;\n        vec3 lit = (fa_indirect_diffuse(param_4) * _2682) * _2687;\n        int _2301 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2301; ln++)\n        {\n            int param_5 = ln;\n            int _2314 = fa_cl_light(param_5);\n            bool _2317 = fa_lm.z > 0.5;\n            bool _2323;\n            if (_2317)\n            {\n                int param_6 = _2314;\n                _2323 = fa_light_baked(param_6);\n            }\n            else\n            {\n                _2323 = _2317;\n            }\n            if (_2323)\n            {\n                continue;\n            }\n            int param_7 = _2314;\n            vec3 param_8 = fa_world_pos;\n            vec3 param_9 = _2651;\n            SurfaceInput param_10 = SurfaceInput(fa_world_pos, _2651, fa_world_tangent, fa_uv, fa_vertex_color, _2252, gl_FrontFacing);\n            Surface param_11 = Surface(_2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690, _2691, _2692, _2693, _2694, _2695, _2696, _2697);\n            LightSample param_12 = fa_light_shadowed(param_7, param_8, param_9);\n            lit += light(param_10, param_11, param_12);\n        }\n        result = lit;\n    }\n    vec3 _2350 = result;\n    vec3 _2351 = _2350 + _2688;\n    result = _2351;\n    vec3 param_13 = _2351;\n    vec3 param_14 = fa_world_pos;\n    result = fa_shadow_debug(param_13, param_14);\n    bool _2360 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2367;\n    if (!_2360)\n    {\n        _2367 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2367 = _2360;\n    }\n    if (_2367)\n    {\n        vec3 _2376 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2382 = dot(_2376, fa_mesh_fs_params[9].xyz);\n        bool _2386 = fa_mesh_fs_params[9].w > 0.5;\n        float _2387;\n        if (_2386)\n        {\n            _2387 = _2382;\n        }\n        else\n        {\n            _2387 = length(_2376);\n        }\n        float _2399 = _2387 - fa_mesh_fs_params[8].x;\n        if (_2399 > 0.0)\n        {\n            float _2408 = fa_mesh_fs_params[7].w * _2399;\n            float tau = _2408 * _2408;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2424;\n                if (_2386)\n                {\n                    _2424 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2382);\n                }\n                else\n                {\n                    _2424 = fa_mesh_fs_params[0].y;\n                }\n                float _2445 = mix(_2424, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2387, 0.0, 1.0));\n                float _2449 = fa_world_pos.y - _2445;\n                float _2454 = _2445 - fa_mesh_fs_params[8].z;\n                float _2459 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2462 = _2454 <= 0.0;\n                bool _2463 = !_2462;\n                bool _2469;\n                if (_2463)\n                {\n                    _2469 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2469 = _2462;\n                }\n                float _2470;\n                if (_2469)\n                {\n                    _2470 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2470 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2454, 80.0));\n                }\n                bool _2497;\n                if (_2463)\n                {\n                    _2497 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2497 = _2462;\n                }\n                float _2498;\n                if (_2497)\n                {\n                    _2498 = fa_mesh_fs_params[8].y * _2454;\n                }\n                else\n                {\n                    _2498 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2454, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2523 = _2459 <= 0.0;\n                bool _2530;\n                if (!_2523)\n                {\n                    _2530 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2530 = _2523;\n                }\n                float _2531;\n                if (_2530)\n                {\n                    _2531 = fa_mesh_fs_params[8].y * _2459;\n                }\n                else\n                {\n                    _2531 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2459, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2558;\n                if (abs(_2449) < 0.001000000047497451305389404296875)\n                {\n                    _2558 = _2470;\n                }\n                else\n                {\n                    _2558 = (_2531 - _2498) / _2449;\n                }\n                tau += (_2399 * max(_2558, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2683);\n}\n\n",
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
            "inst_name": "_415",
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
            "inst_name": "_651",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1854",
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
