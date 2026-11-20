{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "d7c968bc92bb9c3058c9e4a79ae24422666c878168002734a2aaf374dcac2b6e",
  "slang": "glsl430",
  "params": [
    "glow"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _268 = _160.world_pos;\n    fa_world_pos = _268;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_268, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _390 = fa_mesh_fs_params[19].x < 0.0;\n    bool _397;\n    if (!_390)\n    {\n        _397 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _405;\n    if (!_397)\n    {\n        _405 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _405 = _397;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    if (_419)\n    {\n        return ivec2(0);\n    }\n    vec4 _429 = vec4(world_pos, 1.0);\n    float _436 = dot(fa_mesh_fs_params[16], _429);\n    if (!(_436 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _458 = vec2(dot(fa_mesh_fs_params[14], _429), dot(fa_mesh_fs_params[15], _429)) / vec2(_436);\n    int _462 = int(fa_mesh_fs_params[18].x);\n    int _466 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _466) + clamp(int(floor(((_458.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _466 - 1)) * _462)) + clamp(int(floor(((_458.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _462 - 1);\n    vec4 _537 = fa_light_texel(param);\n    return ivec2(int(_537.x), int(_537.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1440 = fa_cluster_lookup(param);\n    fa_cl_slot = _1440.x;\n    fa_cl_local = _1440.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1554 = fa_linear_to_srgb(param);\n        c = _1554;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1562 = fa_srgb_to_linear(param_1);\n            c = _1562;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _157;\n    if (i.front_facing)\n    {\n        _157 = i.world_normal;\n    }\n    else\n    {\n        _157 = -i.world_normal;\n    }\n    vec3 _181 = normalize(i.world_tangent.xyz - (_157 * dot(_157, i.world_tangent.xyz)));\n    vec3 _209 = normalize(((_181 * m.x) + ((cross(_157, _181) * i.world_tangent.w) * m.y)) + (_157 * m.z));\n    vec3 _212;\n    if (i.front_facing)\n    {\n        _212 = _209;\n    }\n    else\n    {\n        _212 = -_209;\n    }\n    return _212;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1593 = fa_tex_fix(param_2, param_3);\n    vec4 _2387 = base_t;\n    _2387.x = _1593.x;\n    _2387.y = _1593.y;\n    _2387.z = _1593.z;\n    base_t = _2387;\n    vec4 _1607 = (_2387 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2346 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1639 = fa_tex_fix(param_6, param_7);\n        vec3 _1643 = (_1639 * 2.0) - vec3(1.0);\n        vec2 _1648 = _1643.xy * fa_mesh_fs_params[6].x;\n        vec3 _2395 = _1643;\n        _2395.x = _1648.x;\n        _2395.y = _1648.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2395;\n        _2346 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1677 = fa_tex_fix(param_12, param_13);\n    vec4 _2398 = mrt;\n    _2398.x = _1677.x;\n    _2398.y = _1677.y;\n    _2398.z = _1677.z;\n    mrt = _2398;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1716 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1743 = fa_tex_fix(param_20, param_21);\n    return Surface(_1607.xyz, _1607.w, _2346, clamp(fa_mesh_fs_params[5].x * _1677.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1677.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1716.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1743));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (fa_material[0].xyz * fa_material[0].w);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _257 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _263 = fa_light_texel(param_1);\n    float _266 = _263.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _273 = _266 < 0.5;\n    vec3 l;\n    if (_273)\n    {\n        l = normalize(_257.xyz);\n    }\n    else\n    {\n        vec3 _285 = _257.xyz - world_pos;\n        float _287 = length(_285);\n        dist = _287;\n        l = _285 / vec3(max(_287, 9.9999997473787516355514526367188e-05));\n        float _302 = _287 / max(_257.w, 0.001000000047497451305389404296875);\n        float _308 = clamp(1.0 - (_302 * _302), 0.0, 1.0);\n        atten = _308 * _308;\n        if (_266 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _322 = fa_light_texel(param_2);\n            float _332 = _322.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _339 = fa_light_texel(param_3);\n            float _340 = _339.x;\n            float cos_inner = _340;\n            if (_340 > 1.5)\n            {\n                cos_inner = mix(_332, 1.0, 0.25);\n            }\n            atten *= smoothstep(_332, cos_inner, dot(-l, normalize(_322.xyz)));\n        }\n    }\n    int _371;\n    if (_273)\n    {\n        _371 = 0;\n    }\n    else\n    {\n        _371 = (_266 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _263.xyz * atten, atten, 1.0, dist, _371);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _611;\n    if (i == 0)\n    {\n        _611 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _627;\n        if (i == 1)\n        {\n            _627 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _635;\n            if (i == 2)\n            {\n                _635 = fa_shadows[24].z;\n            }\n            else\n            {\n                _635 = fa_shadows[24].w;\n            }\n            _627 = _635;\n        }\n        _611 = _627;\n    }\n    return _611;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _599 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_599), sin(_599)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _673 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _678 = clamp(dot(n, l), 0.0, 1.0);\n    float _684 = sqrt(1.0 - (_678 * _678));\n    float _692 = min(_684 / max(_678, 0.20000000298023223876953125), 4.0);\n    float _697;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _697 = fa_shadows[26].y;\n    }\n    else\n    {\n        _697 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _722 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_697 * _684)), 1.0);\n    float _729 = _722.x;\n    bool _732 = _729 < fa_shadows[ci * 1 + 16].x;\n    bool _741;\n    if (!_732)\n    {\n        _741 = _729 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _741 = _732;\n    }\n    bool _750;\n    if (!_741)\n    {\n        _750 = _722.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _722.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _766;\n    if (!_759)\n    {\n        _766 = _722.z > 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    if (_766)\n    {\n        return -1.0;\n    }\n    float _775;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _775 = fa_shadows[26].x;\n    }\n    else\n    {\n        _775 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _794 = _722.z - ((_775 * (1.0 + (0.5 * _692))) / _673);\n    float _803 = ((fa_shadows[ci * 1 + 20].x * min(_692, 3.0)) * 0.5) / _673;\n    int _812 = int(fa_shadows[25].z + 0.5);\n    if (_812 == 1)\n    {\n        vec2 param = _722.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _823 = fa_shadow_depth(param, param_1);\n        return float(_794 <= _823);\n    }\n    float _830 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _833 = _812 == 2;\n    if (_833)\n    {\n        float _847 = clamp(((fa_shadows[25].w * _673) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _830;\n            vec2 _866 = fa_shadow_vogel(param_2, param_3, param_4) * _847;\n            vec2 param_5 = _722.xy + (_866 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _877 = fa_shadow_depth(param_5, param_6);\n            if (_877 < (_794 - (length(_866) * _803)))\n            {\n                sum += _877;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_794 - (sum / cnt), 0.0) * _673) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _921 = _833 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _921; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _921;\n        float param_9 = _830;\n        vec2 _940 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _722.xy + (_940 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _951 = fa_shadow_depth(param_10, param_11);\n        lit += float((_794 - (length(_940) * _803)) <= _951);\n    }\n    return lit / float(_921);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _981 = int(fa_shadows[25].x + 0.5);\n    if (_981 < 1)\n    {\n        return 1.0;\n    }\n    float _997 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _981 - 1;\n    if (_997 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1009 = _981 > 1;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _997 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 1;\n    }\n    bool _1020 = _981 > 2;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _997 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 2;\n    }\n    bool _1031 = _981 > 3;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _997 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1064 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1064;\n        if (_1064 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1089;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1089 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1089 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1108 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1089, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1119 = clamp((_997 - (fa_shadow_split_at(param_7) - _1108)) / _1108, 0.0, 1.0);\n        if (_1119 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _981)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1140 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1140;\n                if (_1140 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1119);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1468 = fa_light_sample(param, param_1);\n    vec3 _2331 = _1468.direction;\n    vec3 _2326 = _1468.color;\n    float _2328 = _1468.shadow;\n    int _2336 = _1468.type;\n    if ((_2336 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2331;\n        float _1482 = fa_shadow_factor(param_2, param_3);\n        _2328 = _1482;\n        _2326 *= _1482;\n    }\n    return LightSample(_2331, _2326, _1468.attenuation, _2328, _1468._distance, _2336);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1372 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1375 = _1372.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1375 * _1375, exp2((-9.27999973297119140625) * ndv)) * _1375) + _1372.y)) + _1372.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1277 = rough * rough;\n    float _1307 = 0.60000002384185791015625 * _1277;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1277)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1307, 0.0500000007450580596923828125 + _1307, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1277 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1414 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1414.x) + vec3(_1414.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1164 = int(fa_shadows[25].x + 0.5);\n    float _1174 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1179 = _1164 > 0;\n    bool _1188;\n    if (_1179)\n    {\n        int param = _1164 - 1;\n        _1188 = _1174 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1188 = _1179;\n    }\n    if (_1188)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1195 = _1164 > 1;\n        bool _1202;\n        if (_1195)\n        {\n            _1202 = _1174 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1202 = _1195;\n        }\n        if (_1202)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1208 = _1164 > 2;\n        bool _1215;\n        if (_1208)\n        {\n            _1215 = _1174 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1215 = _1208;\n        }\n        if (_1215)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1221 = _1164 > 3;\n        bool _1228;\n        if (_1221)\n        {\n            _1228 = _1174 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1228 = _1221;\n        }\n        if (_1228)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2251 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2251 = -_2251;\n    }\n    vec3 _1786 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2251, fa_world_tangent, fa_uv, fa_vertex_color, _1786, gl_FrontFacing);\n    Surface _1794 = fa_standard_surface(param_1);\n    vec3 _2274 = _1794.albedo;\n    float _2275 = _1794.alpha;\n    vec3 _2276 = _1794.normal;\n    float _2277 = _1794.metallic;\n    float _2278 = _1794.roughness;\n    float _2279 = _1794.occlusion;\n    vec3 _2280 = _1794.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2251, fa_world_tangent, fa_uv, fa_vertex_color, _1786, gl_FrontFacing);\n    Surface param_3 = _1794;\n    surface(param_2, param_3);\n    _2274 = param_3.albedo;\n    _2275 = param_3.alpha;\n    _2276 = param_3.normal;\n    _2277 = param_3.metallic;\n    _2278 = param_3.roughness;\n    _2279 = param_3.occlusion;\n    _2280 = param_3.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2274;\n    }\n    else\n    {\n        vec3 _1816 = normalize(_2276);\n        float _1823 = clamp(_2277, 0.0, 1.0);\n        float _1827 = clamp(_2278, 0.0500000007450580596923828125, 1.0);\n        float _1831 = _1827 * _1827;\n        float _1835 = _1831 * _1831;\n        float _1840 = max(dot(_1816, _1786), 9.9999997473787516355514526367188e-05);\n        vec3 _1846 = _2274 * (1.0 - _1823);\n        vec3 _1854 = mix(vec3(0.039999999105930328369140625), _2274, vec3(_1823));\n        vec3 param_4 = _1816;\n        vec3 lit = (fa_ambient_light(param_4) * _1846) * _2279;\n        int _1867 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1867; ln++)\n        {\n            int param_5 = ln;\n            int _1880 = fa_cl_light(param_5);\n            int param_6 = _1880;\n            vec3 param_7 = fa_world_pos;\n            vec3 param_8 = _2251;\n            LightSample _1889 = fa_light_shadowed(param_6, param_7, param_8);\n            vec3 _2309 = _1889.direction;\n            float _1897 = max(dot(_1816, _2309), 0.0);\n            vec3 _1908 = normalize(_2309 + _1786);\n            float _1913 = max(dot(_1816, _1908), 0.0);\n            float _1926 = ((_1913 * _1913) * (_1835 - 1.0)) + 1.0;\n            int param_9 = _1880;\n            lit += (((_1846 + (((_1854 + ((vec3(1.0) - _1854) * pow(1.0 - max(dot(_1786, _1908), 0.0), 5.0))) * (((_1835 / ((3.1415927410125732421875 * _1926) * _1926)) * (0.5 / max(mix((2.0 * _1897) * _1840, _1897 + _1840, _1831), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1897))) * fa_light_rgb(param_9)) * (_1897 * (_1889.attenuation * _1889.shadow)));\n        }\n        vec3 param_10 = _1816;\n        vec3 param_11 = _1786;\n        vec3 param_12 = _1854;\n        float param_13 = _1827;\n        vec3 _1995 = lit;\n        vec3 _1996 = _1995 + (fa_sky_reflection(param_10, param_11, param_12, param_13) * _2279);\n        lit = _1996;\n        result = _1996;\n    }\n    vec3 _2000 = result;\n    vec3 _2001 = _2000 + _2280;\n    result = _2001;\n    vec3 param_14 = _2001;\n    vec3 param_15 = fa_world_pos;\n    result = fa_shadow_debug(param_14, param_15);\n    bool _2010 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        vec3 _2027 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2034 = dot(_2027, fa_mesh_fs_params[9].xyz);\n        bool _2038 = fa_mesh_fs_params[9].w > 0.5;\n        float _2039;\n        if (_2038)\n        {\n            _2039 = _2034;\n        }\n        else\n        {\n            _2039 = length(_2027);\n        }\n        float _2051 = _2039 - fa_mesh_fs_params[8].x;\n        if (_2051 > 0.0)\n        {\n            float _2060 = fa_mesh_fs_params[7].w * _2051;\n            float tau = _2060 * _2060;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2076;\n                if (_2038)\n                {\n                    _2076 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2034);\n                }\n                else\n                {\n                    _2076 = fa_mesh_fs_params[0].y;\n                }\n                float _2097 = mix(_2076, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2039, 0.0, 1.0));\n                float _2101 = fa_world_pos.y - _2097;\n                float _2106 = _2097 - fa_mesh_fs_params[8].z;\n                float _2111 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2114 = _2106 <= 0.0;\n                bool _2115 = !_2114;\n                bool _2121;\n                if (_2115)\n                {\n                    _2121 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2121 = _2114;\n                }\n                float _2122;\n                if (_2121)\n                {\n                    _2122 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2122 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2106, 80.0));\n                }\n                bool _2149;\n                if (_2115)\n                {\n                    _2149 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2149 = _2114;\n                }\n                float _2150;\n                if (_2149)\n                {\n                    _2150 = fa_mesh_fs_params[8].y * _2106;\n                }\n                else\n                {\n                    _2150 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2106, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2175 = _2111 <= 0.0;\n                bool _2182;\n                if (!_2175)\n                {\n                    _2182 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2182 = _2175;\n                }\n                float _2183;\n                if (_2182)\n                {\n                    _2183 = fa_mesh_fs_params[8].y * _2111;\n                }\n                else\n                {\n                    _2183 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2111, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2210;\n                if (abs(_2101) < 0.001000000047497451305389404296875)\n                {\n                    _2210 = _2122;\n                }\n                else\n                {\n                    _2210 = (_2183 - _2150) / _2101;\n                }\n                tau += (_2051 * max(_2210, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2275);\n}\n\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_385",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
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
            "inst_name": "_621",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1495",
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
          },
          {
            "slot": 8,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _390 = fa_mesh_fs_params[19].x < 0.0;\n    bool _397;\n    if (!_390)\n    {\n        _397 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _397 = _390;\n    }\n    bool _405;\n    if (!_397)\n    {\n        _405 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _405 = _397;\n    }\n    bool _412;\n    if (!_405)\n    {\n        _412 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _412 = _405;\n    }\n    bool _419;\n    if (!_412)\n    {\n        _419 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _419 = _412;\n    }\n    if (_419)\n    {\n        return ivec2(0);\n    }\n    vec4 _429 = vec4(world_pos, 1.0);\n    float _436 = dot(fa_mesh_fs_params[16], _429);\n    if (!(_436 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _458 = vec2(dot(fa_mesh_fs_params[14], _429), dot(fa_mesh_fs_params[15], _429)) / vec2(_436);\n    int _462 = int(fa_mesh_fs_params[18].x);\n    int _466 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _466) + clamp(int(floor(((_458.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _466 - 1)) * _462)) + clamp(int(floor(((_458.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _462 - 1);\n    vec4 _537 = fa_light_texel(param);\n    return ivec2(int(_537.x), int(_537.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1440 = fa_cluster_lookup(param);\n    fa_cl_slot = _1440.x;\n    fa_cl_local = _1440.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1554 = fa_linear_to_srgb(param);\n        c = _1554;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1562 = fa_srgb_to_linear(param_1);\n            c = _1562;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _157;\n    if (i.front_facing)\n    {\n        _157 = i.world_normal;\n    }\n    else\n    {\n        _157 = -i.world_normal;\n    }\n    vec3 _181 = normalize(i.world_tangent.xyz - (_157 * dot(_157, i.world_tangent.xyz)));\n    vec3 _209 = normalize(((_181 * m.x) + ((cross(_157, _181) * i.world_tangent.w) * m.y)) + (_157 * m.z));\n    vec3 _212;\n    if (i.front_facing)\n    {\n        _212 = _209;\n    }\n    else\n    {\n        _212 = -_209;\n    }\n    return _212;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1593 = fa_tex_fix(param_2, param_3);\n    vec4 _2387 = base_t;\n    _2387.x = _1593.x;\n    _2387.y = _1593.y;\n    _2387.z = _1593.z;\n    base_t = _2387;\n    vec4 _1607 = (_2387 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2346 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1639 = fa_tex_fix(param_6, param_7);\n        vec3 _1643 = (_1639 * 2.0) - vec3(1.0);\n        vec2 _1648 = _1643.xy * fa_mesh_fs_params[6].x;\n        vec3 _2395 = _1643;\n        _2395.x = _1648.x;\n        _2395.y = _1648.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2395;\n        _2346 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _1677 = fa_tex_fix(param_12, param_13);\n    vec4 _2398 = mrt;\n    _2398.x = _1677.x;\n    _2398.y = _1677.y;\n    _2398.z = _1677.z;\n    mrt = _2398;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _1716 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _1743 = fa_tex_fix(param_20, param_21);\n    return Surface(_1607.xyz, _1607.w, _2346, clamp(fa_mesh_fs_params[5].x * _1677.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _1677.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_1716.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _1743));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (fa_material[0].xyz * fa_material[0].w);\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _257 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _263 = fa_light_texel(param_1);\n    float _266 = _263.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _273 = _266 < 0.5;\n    vec3 l;\n    if (_273)\n    {\n        l = normalize(_257.xyz);\n    }\n    else\n    {\n        vec3 _285 = _257.xyz - world_pos;\n        float _287 = length(_285);\n        dist = _287;\n        l = _285 / vec3(max(_287, 9.9999997473787516355514526367188e-05));\n        float _302 = _287 / max(_257.w, 0.001000000047497451305389404296875);\n        float _308 = clamp(1.0 - (_302 * _302), 0.0, 1.0);\n        atten = _308 * _308;\n        if (_266 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _322 = fa_light_texel(param_2);\n            float _332 = _322.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _339 = fa_light_texel(param_3);\n            float _340 = _339.x;\n            float cos_inner = _340;\n            if (_340 > 1.5)\n            {\n                cos_inner = mix(_332, 1.0, 0.25);\n            }\n            atten *= smoothstep(_332, cos_inner, dot(-l, normalize(_322.xyz)));\n        }\n    }\n    int _371;\n    if (_273)\n    {\n        _371 = 0;\n    }\n    else\n    {\n        _371 = (_266 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _263.xyz * atten, atten, 1.0, dist, _371);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _611;\n    if (i == 0)\n    {\n        _611 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _627;\n        if (i == 1)\n        {\n            _627 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _635;\n            if (i == 2)\n            {\n                _635 = fa_shadows[24].z;\n            }\n            else\n            {\n                _635 = fa_shadows[24].w;\n            }\n            _627 = _635;\n        }\n        _611 = _627;\n    }\n    return _611;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _599 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_599), sin(_599)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _673 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _678 = clamp(dot(n, l), 0.0, 1.0);\n    float _684 = sqrt(1.0 - (_678 * _678));\n    float _692 = min(_684 / max(_678, 0.20000000298023223876953125), 4.0);\n    float _697;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _697 = fa_shadows[26].y;\n    }\n    else\n    {\n        _697 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _722 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_697 * _684)), 1.0);\n    float _729 = _722.x;\n    bool _732 = _729 < fa_shadows[ci * 1 + 16].x;\n    bool _741;\n    if (!_732)\n    {\n        _741 = _729 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _741 = _732;\n    }\n    bool _750;\n    if (!_741)\n    {\n        _750 = _722.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _750 = _741;\n    }\n    bool _759;\n    if (!_750)\n    {\n        _759 = _722.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _759 = _750;\n    }\n    bool _766;\n    if (!_759)\n    {\n        _766 = _722.z > 1.0;\n    }\n    else\n    {\n        _766 = _759;\n    }\n    if (_766)\n    {\n        return -1.0;\n    }\n    float _775;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _775 = fa_shadows[26].x;\n    }\n    else\n    {\n        _775 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _794 = _722.z - ((_775 * (1.0 + (0.5 * _692))) / _673);\n    float _803 = ((fa_shadows[ci * 1 + 20].x * min(_692, 3.0)) * 0.5) / _673;\n    int _812 = int(fa_shadows[25].z + 0.5);\n    if (_812 == 1)\n    {\n        vec2 param = _722.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _823 = fa_shadow_depth(param, param_1);\n        return float(_794 <= _823);\n    }\n    float _830 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _833 = _812 == 2;\n    if (_833)\n    {\n        float _847 = clamp(((fa_shadows[25].w * _673) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _830;\n            vec2 _866 = fa_shadow_vogel(param_2, param_3, param_4) * _847;\n            vec2 param_5 = _722.xy + (_866 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _877 = fa_shadow_depth(param_5, param_6);\n            if (_877 < (_794 - (length(_866) * _803)))\n            {\n                sum += _877;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_794 - (sum / cnt), 0.0) * _673) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _921 = _833 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _921; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _921;\n        float param_9 = _830;\n        vec2 _940 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _722.xy + (_940 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _951 = fa_shadow_depth(param_10, param_11);\n        lit += float((_794 - (length(_940) * _803)) <= _951);\n    }\n    return lit / float(_921);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _981 = int(fa_shadows[25].x + 0.5);\n    if (_981 < 1)\n    {\n        return 1.0;\n    }\n    float _997 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _981 - 1;\n    if (_997 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1009 = _981 > 1;\n    bool _1016;\n    if (_1009)\n    {\n        _1016 = _997 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1016 = _1009;\n    }\n    if (_1016)\n    {\n        ci = 1;\n    }\n    bool _1020 = _981 > 2;\n    bool _1027;\n    if (_1020)\n    {\n        _1027 = _997 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1027 = _1020;\n    }\n    if (_1027)\n    {\n        ci = 2;\n    }\n    bool _1031 = _981 > 3;\n    bool _1038;\n    if (_1031)\n    {\n        _1038 = _997 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1038 = _1031;\n    }\n    if (_1038)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _981)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1064 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1064;\n        if (_1064 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1089;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1089 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1089 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1108 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1089, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1119 = clamp((_997 - (fa_shadow_split_at(param_7) - _1108)) / _1108, 0.0, 1.0);\n        if (_1119 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _981)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1140 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1140;\n                if (_1140 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1119);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1468 = fa_light_sample(param, param_1);\n    vec3 _2331 = _1468.direction;\n    vec3 _2326 = _1468.color;\n    float _2328 = _1468.shadow;\n    int _2336 = _1468.type;\n    if ((_2336 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2331;\n        float _1482 = fa_shadow_factor(param_2, param_3);\n        _2328 = _1482;\n        _2326 *= _1482;\n    }\n    return LightSample(_2331, _2326, _1468.attenuation, _2328, _1468._distance, _2336);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).xyz;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _1372 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _1375 = _1372.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_1375 * _1375, exp2((-9.27999973297119140625) * ndv)) * _1375) + _1372.y)) + _1372.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _1277 = rough * rough;\n    float _1307 = 0.60000002384185791015625 * _1277;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _1277)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _1307, 0.0500000007450580596923828125 + _1307, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_1277 * 0.60000002384185791015625));\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _1414 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _1414.x) + vec3(_1414.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1164 = int(fa_shadows[25].x + 0.5);\n    float _1174 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1179 = _1164 > 0;\n    bool _1188;\n    if (_1179)\n    {\n        int param = _1164 - 1;\n        _1188 = _1174 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1188 = _1179;\n    }\n    if (_1188)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1195 = _1164 > 1;\n        bool _1202;\n        if (_1195)\n        {\n            _1202 = _1174 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1202 = _1195;\n        }\n        if (_1202)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1208 = _1164 > 2;\n        bool _1215;\n        if (_1208)\n        {\n            _1215 = _1174 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1215 = _1208;\n        }\n        if (_1215)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1221 = _1164 > 3;\n        bool _1228;\n        if (_1221)\n        {\n            _1228 = _1174 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1228 = _1221;\n        }\n        if (_1228)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2251 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2251 = -_2251;\n    }\n    vec3 _1786 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2251, fa_world_tangent, fa_uv, fa_vertex_color, _1786, gl_FrontFacing);\n    Surface _1794 = fa_standard_surface(param_1);\n    vec3 _2274 = _1794.albedo;\n    float _2275 = _1794.alpha;\n    vec3 _2276 = _1794.normal;\n    float _2277 = _1794.metallic;\n    float _2278 = _1794.roughness;\n    float _2279 = _1794.occlusion;\n    vec3 _2280 = _1794.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2251, fa_world_tangent, fa_uv, fa_vertex_color, _1786, gl_FrontFacing);\n    Surface param_3 = _1794;\n    surface(param_2, param_3);\n    _2274 = param_3.albedo;\n    _2275 = param_3.alpha;\n    _2276 = param_3.normal;\n    _2277 = param_3.metallic;\n    _2278 = param_3.roughness;\n    _2279 = param_3.occlusion;\n    _2280 = param_3.emission;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2274;\n    }\n    else\n    {\n        vec3 _1816 = normalize(_2276);\n        float _1823 = clamp(_2277, 0.0, 1.0);\n        float _1827 = clamp(_2278, 0.0500000007450580596923828125, 1.0);\n        float _1831 = _1827 * _1827;\n        float _1835 = _1831 * _1831;\n        float _1840 = max(dot(_1816, _1786), 9.9999997473787516355514526367188e-05);\n        vec3 _1846 = _2274 * (1.0 - _1823);\n        vec3 _1854 = mix(vec3(0.039999999105930328369140625), _2274, vec3(_1823));\n        vec3 param_4 = _1816;\n        vec3 lit = (fa_ambient_light(param_4) * _1846) * _2279;\n        int _1867 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _1867; ln++)\n        {\n            int param_5 = ln;\n            int _1880 = fa_cl_light(param_5);\n            int param_6 = _1880;\n            vec3 param_7 = fa_world_pos;\n            vec3 param_8 = _2251;\n            LightSample _1889 = fa_light_shadowed(param_6, param_7, param_8);\n            vec3 _2309 = _1889.direction;\n            float _1897 = max(dot(_1816, _2309), 0.0);\n            vec3 _1908 = normalize(_2309 + _1786);\n            float _1913 = max(dot(_1816, _1908), 0.0);\n            float _1926 = ((_1913 * _1913) * (_1835 - 1.0)) + 1.0;\n            int param_9 = _1880;\n            lit += (((_1846 + (((_1854 + ((vec3(1.0) - _1854) * pow(1.0 - max(dot(_1786, _1908), 0.0), 5.0))) * (((_1835 / ((3.1415927410125732421875 * _1926) * _1926)) * (0.5 / max(mix((2.0 * _1897) * _1840, _1897 + _1840, _1831), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _1897))) * fa_light_rgb(param_9)) * (_1897 * (_1889.attenuation * _1889.shadow)));\n        }\n        vec3 param_10 = _1816;\n        vec3 param_11 = _1786;\n        vec3 param_12 = _1854;\n        float param_13 = _1827;\n        vec3 _1995 = lit;\n        vec3 _1996 = _1995 + (fa_sky_reflection(param_10, param_11, param_12, param_13) * _2279);\n        lit = _1996;\n        result = _1996;\n    }\n    vec3 _2000 = result;\n    vec3 _2001 = _2000 + _2280;\n    result = _2001;\n    vec3 param_14 = _2001;\n    vec3 param_15 = fa_world_pos;\n    result = fa_shadow_debug(param_14, param_15);\n    bool _2010 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2018;\n    if (!_2010)\n    {\n        _2018 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2018 = _2010;\n    }\n    if (_2018)\n    {\n        vec3 _2027 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2034 = dot(_2027, fa_mesh_fs_params[9].xyz);\n        bool _2038 = fa_mesh_fs_params[9].w > 0.5;\n        float _2039;\n        if (_2038)\n        {\n            _2039 = _2034;\n        }\n        else\n        {\n            _2039 = length(_2027);\n        }\n        float _2051 = _2039 - fa_mesh_fs_params[8].x;\n        if (_2051 > 0.0)\n        {\n            float _2060 = fa_mesh_fs_params[7].w * _2051;\n            float tau = _2060 * _2060;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2076;\n                if (_2038)\n                {\n                    _2076 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2034);\n                }\n                else\n                {\n                    _2076 = fa_mesh_fs_params[0].y;\n                }\n                float _2097 = mix(_2076, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2039, 0.0, 1.0));\n                float _2101 = fa_world_pos.y - _2097;\n                float _2106 = _2097 - fa_mesh_fs_params[8].z;\n                float _2111 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2114 = _2106 <= 0.0;\n                bool _2115 = !_2114;\n                bool _2121;\n                if (_2115)\n                {\n                    _2121 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2121 = _2114;\n                }\n                float _2122;\n                if (_2121)\n                {\n                    _2122 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2122 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2106, 80.0));\n                }\n                bool _2149;\n                if (_2115)\n                {\n                    _2149 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2149 = _2114;\n                }\n                float _2150;\n                if (_2149)\n                {\n                    _2150 = fa_mesh_fs_params[8].y * _2106;\n                }\n                else\n                {\n                    _2150 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2106, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2175 = _2111 <= 0.0;\n                bool _2182;\n                if (!_2175)\n                {\n                    _2182 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2182 = _2175;\n                }\n                float _2183;\n                if (_2182)\n                {\n                    _2183 = fa_mesh_fs_params[8].y * _2111;\n                }\n                else\n                {\n                    _2183 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2111, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2210;\n                if (abs(_2101) < 0.001000000047497451305389404296875)\n                {\n                    _2210 = _2122;\n                }\n                else\n                {\n                    _2210 = (_2183 - _2150) / _2101;\n                }\n                tau += (_2051 * max(_2210, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2275);\n}\n\n",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_385",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
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
            "inst_name": "_621",
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
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1495",
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
          },
          {
            "slot": 8,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _188 = fa_linear_to_srgb(param);\n        c = _188;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _197 = fa_srgb_to_linear(param_1);\n            c = _197;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _240 = fa_tex_fix(param_2, param_3);\n    vec4 _600 = base_t;\n    _600.x = _240.x;\n    _600.y = _240.y;\n    _600.z = _240.z;\n    base_t = _600;\n    vec4 _255 = (_600 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _581 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _288 = fa_tex_fix(param_6, param_7);\n        vec3 _292 = (_288 * 2.0) - vec3(1.0);\n        vec2 _297 = _292.xy * fa_mesh_fs_params[6].x;\n        vec3 _608 = _292;\n        _608.x = _297.x;\n        _608.y = _297.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _608;\n        _581 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _326 = fa_tex_fix(param_12, param_13);\n    vec4 _611 = mrt;\n    _611.x = _326.x;\n    _611.y = _326.y;\n    _611.z = _326.z;\n    mrt = _611;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _367 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _394 = fa_tex_fix(param_20, param_21);\n    return Surface(_255.xyz, _255.w, _581, clamp(fa_mesh_fs_params[5].x * _326.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_367.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _394));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (fa_material[0].xyz * fa_material[0].w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _528 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _528 = -_528;\n    }\n    vec3 _440 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _528, fa_world_tangent, fa_uv, fa_vertex_color, _440, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _528, fa_world_tangent, fa_uv, fa_vertex_color, _440, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _455 = normalize(param_2.normal);\n    vec3 _470 = normalize(vec3(dot(fa_pre_r0, _455), dot(fa_pre_r1, _455), dot(fa_pre_r2, _455)));\n    float _482 = _470.z;\n    vec2 e = _470.xy / vec2((abs(_470.x) + abs(_470.y)) + abs(_482));\n    if (_482 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_124",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _188 = fa_linear_to_srgb(param);\n        c = _188;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _197 = fa_srgb_to_linear(param_1);\n            c = _197;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _240 = fa_tex_fix(param_2, param_3);\n    vec4 _600 = base_t;\n    _600.x = _240.x;\n    _600.y = _240.y;\n    _600.z = _240.z;\n    base_t = _600;\n    vec4 _255 = (_600 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _581 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _288 = fa_tex_fix(param_6, param_7);\n        vec3 _292 = (_288 * 2.0) - vec3(1.0);\n        vec2 _297 = _292.xy * fa_mesh_fs_params[6].x;\n        vec3 _608 = _292;\n        _608.x = _297.x;\n        _608.y = _297.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _608;\n        _581 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _326 = fa_tex_fix(param_12, param_13);\n    vec4 _611 = mrt;\n    _611.x = _326.x;\n    _611.y = _326.y;\n    _611.z = _326.z;\n    mrt = _611;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _367 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _394 = fa_tex_fix(param_20, param_21);\n    return Surface(_255.xyz, _255.w, _581, clamp(fa_mesh_fs_params[5].x * _326.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_367.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _394));\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (fa_material[0].xyz * fa_material[0].w);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _528 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _528 = -_528;\n    }\n    vec3 _440 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _528, fa_world_tangent, fa_uv, fa_vertex_color, _440, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _528, fa_world_tangent, fa_uv, fa_vertex_color, _440, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _455 = normalize(param_2.normal);\n    vec3 _470 = normalize(vec3(dot(fa_pre_r0, _455), dot(fa_pre_r1, _455), dot(fa_pre_r2, _455)));\n    float _482 = _470.z;\n    vec2 e = _470.xy / vec2((abs(_470.x) + abs(_470.y)) + abs(_482));\n    if (_482 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_124",
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
            "size": 320,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_229",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 20,
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
