{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "df130aaeb5c0790af276010723d2798f8fdace693dbde21948e5a037edff24ef",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _426 = fa_mesh_fs_params[19].x < 0.0;\n    bool _433;\n    if (!_426)\n    {\n        _433 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    bool _441;\n    if (!_433)\n    {\n        _441 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _441 = _433;\n    }\n    bool _448;\n    if (!_441)\n    {\n        _448 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _448 = _441;\n    }\n    bool _455;\n    if (!_448)\n    {\n        _455 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _455 = _448;\n    }\n    if (_455)\n    {\n        return ivec2(0);\n    }\n    vec4 _465 = vec4(world_pos, 1.0);\n    float _472 = dot(fa_mesh_fs_params[16], _465);\n    if (!(_472 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _494 = vec2(dot(fa_mesh_fs_params[14], _465), dot(fa_mesh_fs_params[15], _465)) / vec2(_472);\n    int _498 = int(fa_mesh_fs_params[18].x);\n    int _502 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _502) + clamp(int(floor(((_494.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _502 - 1)) * _498)) + clamp(int(floor(((_494.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _498 - 1);\n    vec4 _573 = fa_light_texel(param);\n    return ivec2(int(_573.x), int(_573.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1735 = fa_cluster_lookup(param);\n    fa_cl_slot = _1735.x;\n    fa_cl_local = _1735.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1899 = fa_linear_to_srgb(param);\n        c = _1899;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1907 = fa_srgb_to_linear(param_1);\n            c = _1907;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _185;\n    if (i.front_facing)\n    {\n        _185 = i.world_normal;\n    }\n    else\n    {\n        _185 = -i.world_normal;\n    }\n    vec3 _209 = normalize(i.world_tangent.xyz - (_185 * dot(_185, i.world_tangent.xyz)));\n    vec3 _237 = normalize(((_209 * m.x) + ((cross(_185, _209) * i.world_tangent.w) * m.y)) + (_185 * m.z));\n    vec3 _240;\n    if (i.front_facing)\n    {\n        _240 = _237;\n    }\n    else\n    {\n        _240 = -_237;\n    }\n    return _240;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1938 = fa_tex_fix(param_2, param_3);\n    vec4 _2925 = base_t;\n    _2925.x = _1938.x;\n    _2925.y = _1938.y;\n    _2925.z = _1938.z;\n    base_t = _2925;\n    vec4 _1952 = (_2925 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2840 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1984 = fa_tex_fix(param_6, param_7);\n        vec3 _1988 = (_1984 * 2.0) - vec3(1.0);\n        vec2 _1993 = _1988.xy * fa_mesh_fs_params[6].x;\n        vec3 _2933 = _1988;\n        _2933.x = _1993.x;\n        _2933.y = _1993.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2933;\n        _2840 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2022 = fa_tex_fix(param_12, param_13);\n    vec4 _2936 = mrt;\n    _2936.x = _2022.x;\n    _2936.y = _2022.y;\n    _2936.z = _2022.z;\n    mrt = _2936;\n    vec4 _2051 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2051.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2063 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2093 = fa_tex_fix(param_20, param_21);\n    float _2845 = fa_mesh_fs_params[20].x;\n    float _2846 = fa_mesh_fs_params[20].y;\n    float _2849 = fa_mesh_fs_params[20].z;\n    float _2848 = fa_mesh_fs_params[21].w;\n    float _2851 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2845 *= _2063.y;\n            _2846 *= _2063.z;\n            _2848 *= _2051.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2849 *= mrt.x;\n            _2851 *= mrt.w;\n        }\n    }\n    return Surface(_1952.xyz, _1952.w, _2840, clamp(fa_mesh_fs_params[5].x * _2022.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2022.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2063.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2093), _2845, _2846, fa_mesh_fs_params[21].xyz, _2848, _2849, fa_mesh_fs_params[20].w, _2851, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _296 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _302 = fa_light_texel(param_1);\n    float _305 = _302.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _311 = _305 < 0.5;\n    vec3 l;\n    if (_311)\n    {\n        l = normalize(_296.xyz);\n    }\n    else\n    {\n        vec3 _323 = _296.xyz - world_pos;\n        float _325 = length(_323);\n        dist = _325;\n        l = _323 / vec3(max(_325, 9.9999997473787516355514526367188e-05));\n        float _340 = _325 / max(_296.w, 0.001000000047497451305389404296875);\n        float _346 = clamp(1.0 - (_340 * _340), 0.0, 1.0);\n        atten = _346 * _346;\n        if (_305 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _360 = fa_light_texel(param_2);\n            float _370 = _360.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _376 = fa_light_texel(param_3);\n            float _377 = _376.x;\n            float cos_inner = _377;\n            if (_377 > 1.5)\n            {\n                cos_inner = mix(_370, 1.0, 0.25);\n            }\n            atten *= smoothstep(_370, cos_inner, dot(-l, normalize(_360.xyz)));\n        }\n    }\n    int _407;\n    if (_311)\n    {\n        _407 = 0;\n    }\n    else\n    {\n        _407 = (_305 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _302.xyz * atten, atten, 1.0, dist, _407);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _647;\n    if (i == 0)\n    {\n        _647 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _663;\n        if (i == 1)\n        {\n            _663 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _671;\n            if (i == 2)\n            {\n                _671 = fa_shadows[24].z;\n            }\n            else\n            {\n                _671 = fa_shadows[24].w;\n            }\n            _663 = _671;\n        }\n        _647 = _663;\n    }\n    return _647;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _704 = fa_shadow_depth(param, param_1);\n    float _708;\n    if (conv.x < 0.5)\n    {\n        _708 = _704;\n    }\n    else\n    {\n        _708 = (conv.y * conv.z) / (conv.z - (_704 * (conv.z - conv.y)));\n    }\n    return _708;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _635 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_635), sin(_635)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _754 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _768 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _754;\n            vec2 _787 = fa_shadow_vogel(param_3, param_4, param_5) * _768;\n            vec2 param_6 = uv + (_787 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _799 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_799 < (zr - (length(_787) * plane)))\n            {\n                sum += _799;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _843 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _843; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _843;\n        float param_11 = _754;\n        vec2 _862 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_862 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_862) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_843);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _904 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _909 = clamp(dot(n, l), 0.0, 1.0);\n    float _915 = sqrt(1.0 - (_909 * _909));\n    float _923 = min(_915 / max(_909, 0.20000000298023223876953125), 4.0);\n    float _928;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _928 = fa_shadows[26].y;\n    }\n    else\n    {\n        _928 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _953 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_928 * _915)), 1.0);\n    float _960 = _953.x;\n    bool _963 = _960 < fa_shadows[ci * 1 + 16].x;\n    bool _972;\n    if (!_963)\n    {\n        _972 = _960 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _972 = _963;\n    }\n    bool _981;\n    if (!_972)\n    {\n        _981 = _953.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _981 = _972;\n    }\n    bool _990;\n    if (!_981)\n    {\n        _990 = _953.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _990 = _981;\n    }\n    bool _997;\n    if (!_990)\n    {\n        _997 = _953.z > 1.0;\n    }\n    else\n    {\n        _997 = _990;\n    }\n    if (_997)\n    {\n        return -1.0;\n    }\n    float _1006;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1006 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1006 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _953.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _953.z - ((_1006 * (1.0 + (0.5 * _923))) / _904);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _904;\n    float param_5 = _904 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_923, 3.0)) * 0.5) / _904;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1434 = int(fa_shadows[25].x + 0.5);\n    if (_1434 < 1)\n    {\n        return 1.0;\n    }\n    float _1450 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1434 - 1;\n    if (_1450 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1462 = _1434 > 1;\n    bool _1469;\n    if (_1462)\n    {\n        _1469 = _1450 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1469 = _1462;\n    }\n    if (_1469)\n    {\n        ci = 1;\n    }\n    bool _1473 = _1434 > 2;\n    bool _1480;\n    if (_1473)\n    {\n        _1480 = _1450 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    if (_1480)\n    {\n        ci = 2;\n    }\n    bool _1484 = _1434 > 3;\n    bool _1491;\n    if (_1484)\n    {\n        _1491 = _1450 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1491 = _1484;\n    }\n    if (_1491)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1434)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1517 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1517;\n        if (_1517 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1542;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1542 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1542 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1561 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1542, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1572 = clamp((_1450 - (fa_shadow_split_at(param_7) - _1561)) / _1561, 0.0, 1.0);\n        if (_1572 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1434)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1593 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1593;\n                if (_1593 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1572);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1065 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1073;\n    if (!_1065)\n    {\n        _1073 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1073 = _1065;\n    }\n    if (_1073)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1086 = fa_light_texel(param);\n    float _1087 = _1086.x;\n    if (_1087 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1096 = int(_1087 + 0.5);\n    int param_1 = _1096;\n    vec4 _1100 = fa_light_texel(param_1);\n    int param_2 = _1096 + 1;\n    vec4 _1105 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1108 = _1100.y;\n    if (_1108 > 0.0)\n    {\n        float _1125 = 1.0 - smoothstep(0.75 * _1108, _1108, length(world - fa_shadows[27].xyz));\n        fade = _1125;\n        if (_1125 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1100.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1144 = world - fa_light_texel(param_3).xyz;\n        vec3 _1147 = abs(_1144);\n        float _1149 = _1147.x;\n        float _1151 = _1147.y;\n        bool _1152 = _1149 >= _1151;\n        bool _1160;\n        if (_1152)\n        {\n            _1160 = _1149 >= _1147.z;\n        }\n        else\n        {\n            _1160 = _1152;\n        }\n        int _1161;\n        if (_1160)\n        {\n            _1161 = (_1144.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1174;\n            if (_1151 >= _1147.z)\n            {\n                _1174 = (_1144.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1174 = (_1144.z > 0.0) ? 4 : 5;\n            }\n            _1161 = _1174;\n        }\n        face = _1161;\n    }\n    int _1193 = (_1096 + 2) + (face * 6);\n    int param_4 = _1193;\n    int param_5 = _1193 + 1;\n    int param_6 = _1193 + 3;\n    vec4 _1207 = fa_light_texel(param_6);\n    int param_7 = _1193 + 4;\n    vec4 _1212 = fa_light_texel(param_7);\n    int param_8 = _1193 + 5;\n    vec4 _1217 = fa_light_texel(param_8);\n    float _1229 = _1217.x * max(dot(_1207, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1234 = clamp(dot(n, l), 0.0, 1.0);\n    float _1257 = clamp(dot(n, _1207.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1280 = min(sqrt(1.0 - (_1257 * _1257)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1207, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1283 = _1105.y;\n    float _1285;\n    if (_1283 > 0.0)\n    {\n        _1285 = _1283;\n    }\n    else\n    {\n        _1285 = 1.5 * _1229;\n    }\n    vec4 _1305 = vec4(world + (n * (_1285 * sqrt(1.0 - (_1234 * _1234)))), 1.0);\n    float _1309 = dot(_1207, _1305);\n    float _1312 = _1217.y;\n    if (_1309 < _1312)\n    {\n        return 1.0;\n    }\n    vec2 _1327 = vec2(dot(fa_light_texel(param_4), _1305), dot(fa_light_texel(param_5), _1305)) / vec2(_1309);\n    float _1329 = _1327.x;\n    bool _1332 = _1329 < _1212.x;\n    bool _1341;\n    if (!_1332)\n    {\n        _1341 = _1329 > _1212.z;\n    }\n    else\n    {\n        _1341 = _1332;\n    }\n    bool _1350;\n    if (!_1341)\n    {\n        _1350 = _1327.y < _1212.y;\n    }\n    else\n    {\n        _1350 = _1341;\n    }\n    bool _1359;\n    if (!_1350)\n    {\n        _1359 = _1327.y > _1212.w;\n    }\n    else\n    {\n        _1359 = _1350;\n    }\n    if (_1359)\n    {\n        return 1.0;\n    }\n    float _1365 = _1105.x;\n    float _1367;\n    if (_1365 > 0.0)\n    {\n        _1367 = _1365;\n    }\n    else\n    {\n        _1367 = 1.5 * _1229;\n    }\n    vec2 param_10 = _1327;\n    vec4 param_11 = _1212;\n    float param_12 = _1309 - (_1367 * (1.0 + (0.5 * _1280)));\n    float param_13 = _1229;\n    float param_14 = 1.0;\n    float param_15 = _1217.z * 0.25;\n    float param_16 = (_1229 * min(_1280, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1312, _1217.z);\n    int param_18 = int(_1100.z + 0.5);\n    float param_19 = _1100.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _1762 = fa_lm.z > 0.5;\n    bool _1768;\n    if (_1762)\n    {\n        int param = li;\n        _1768 = fa_light_baked(param);\n    }\n    else\n    {\n        _1768 = _1762;\n    }\n    if (_1768)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _1791 = fa_light_sample(param_2, param_3);\n    vec3 _2825 = _1791.direction;\n    vec3 _2820 = _1791.color;\n    float _2827 = _1791.attenuation;\n    float _2822 = _1791.shadow;\n    int _2830 = _1791.type;\n    if ((_2830 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _2825;\n        float _1805 = fa_shadow_factor(param_4, param_5);\n        _2822 = _1805;\n        _2820 *= _1805;\n    }\n    else\n    {\n        bool _1816 = _2830 != 0;\n        bool _1822;\n        if (_1816)\n        {\n            _1822 = _2827 > 0.0;\n        }\n        else\n        {\n            _1822 = _1816;\n        }\n        if (_1822)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _2825;\n            float _1834 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _2822 = _1834;\n            _2820 *= _1834;\n        }\n    }\n    return LightSample(_2825, _2820, _2827, _2822, _1791._distance, _2830);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1617 = int(fa_shadows[25].x + 0.5);\n    float _1627 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1632 = _1617 > 0;\n    bool _1641;\n    if (_1632)\n    {\n        int param = _1617 - 1;\n        _1641 = _1627 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1641 = _1632;\n    }\n    if (_1641)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1648 = _1617 > 1;\n        bool _1655;\n        if (_1648)\n        {\n            _1655 = _1627 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1655 = _1648;\n        }\n        if (_1655)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1661 = _1617 > 2;\n        bool _1668;\n        if (_1661)\n        {\n            _1668 = _1627 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1668 = _1661;\n        }\n        if (_1668)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1674 = _1617 > 3;\n        bool _1681;\n        if (_1674)\n        {\n            _1681 = _1627 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1681 = _1674;\n        }\n        if (_1681)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2636 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2636 = -_2636;\n    }\n    vec3 _2237 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing);\n    Surface _2245 = fa_standard_surface(param_1);\n    vec3 _2675 = _2245.albedo;\n    float _2676 = _2245.alpha;\n    vec3 _2677 = _2245.normal;\n    float _2678 = _2245.metallic;\n    float _2679 = _2245.roughness;\n    float _2680 = _2245.occlusion;\n    vec3 _2681 = _2245.emission;\n    float _2682 = _2245.clearcoat;\n    float _2683 = _2245.clearcoat_roughness;\n    vec3 _2684 = _2245.sheen_color;\n    float _2685 = _2245.sheen_roughness;\n    float _2686 = _2245.anisotropy;\n    float _2687 = _2245.anisotropy_rotation;\n    float _2688 = _2245.specular;\n    float _2689 = _2245.ior;\n    vec3 _2690 = _2245.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing);\n    Surface param_3 = _2245;\n    surface(param_2, param_3);\n    _2675 = param_3.albedo;\n    _2676 = param_3.alpha;\n    _2677 = param_3.normal;\n    _2678 = param_3.metallic;\n    _2679 = param_3.roughness;\n    _2680 = param_3.occlusion;\n    _2681 = param_3.emission;\n    _2682 = param_3.clearcoat;\n    _2683 = param_3.clearcoat_roughness;\n    _2684 = param_3.sheen_color;\n    _2685 = param_3.sheen_roughness;\n    _2686 = param_3.anisotropy;\n    _2687 = param_3.anisotropy_rotation;\n    _2688 = param_3.specular;\n    _2689 = param_3.ior;\n    _2690 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2675;\n    }\n    else\n    {\n        vec3 _2266 = _2677;\n        vec3 _2267 = normalize(_2266);\n        _2677 = _2267;\n        vec3 param_4 = _2267;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing);\n        Surface param_6 = Surface(_2675, _2676, _2677, _2678, _2679, _2680, _2681, _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690);\n        vec3 param_7 = fa_indirect_diffuse(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _2286 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2286; ln++)\n        {\n            int param_8 = ln;\n            int _2299 = fa_cl_light(param_8);\n            bool _2302 = fa_lm.z > 0.5;\n            bool _2308;\n            if (_2302)\n            {\n                int param_9 = _2299;\n                _2308 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _2308 = _2302;\n            }\n            if (_2308)\n            {\n                continue;\n            }\n            int param_10 = _2299;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2636;\n            SurfaceInput param_13 = SurfaceInput(fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing);\n            Surface param_14 = Surface(_2675, _2676, _2677, _2678, _2679, _2680, _2681, _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690);\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    vec3 _2335 = result;\n    vec3 _2336 = _2335 + _2681;\n    result = _2336;\n    vec3 param_16 = _2336;\n    vec3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2345 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2352;\n    if (!_2345)\n    {\n        _2352 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2352 = _2345;\n    }\n    if (_2352)\n    {\n        vec3 _2361 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2367 = dot(_2361, fa_mesh_fs_params[9].xyz);\n        bool _2371 = fa_mesh_fs_params[9].w > 0.5;\n        float _2372;\n        if (_2371)\n        {\n            _2372 = _2367;\n        }\n        else\n        {\n            _2372 = length(_2361);\n        }\n        float _2384 = _2372 - fa_mesh_fs_params[8].x;\n        if (_2384 > 0.0)\n        {\n            float _2393 = fa_mesh_fs_params[7].w * _2384;\n            float tau = _2393 * _2393;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2409;\n                if (_2371)\n                {\n                    _2409 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2367);\n                }\n                else\n                {\n                    _2409 = fa_mesh_fs_params[0].y;\n                }\n                float _2430 = mix(_2409, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2372, 0.0, 1.0));\n                float _2434 = fa_world_pos.y - _2430;\n                float _2439 = _2430 - fa_mesh_fs_params[8].z;\n                float _2444 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2447 = _2439 <= 0.0;\n                bool _2448 = !_2447;\n                bool _2454;\n                if (_2448)\n                {\n                    _2454 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2454 = _2447;\n                }\n                float _2455;\n                if (_2454)\n                {\n                    _2455 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2455 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2439, 80.0));\n                }\n                bool _2482;\n                if (_2448)\n                {\n                    _2482 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2482 = _2447;\n                }\n                float _2483;\n                if (_2482)\n                {\n                    _2483 = fa_mesh_fs_params[8].y * _2439;\n                }\n                else\n                {\n                    _2483 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2439, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2508 = _2444 <= 0.0;\n                bool _2515;\n                if (!_2508)\n                {\n                    _2515 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2515 = _2508;\n                }\n                float _2516;\n                if (_2515)\n                {\n                    _2516 = fa_mesh_fs_params[8].y * _2444;\n                }\n                else\n                {\n                    _2516 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2444, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2543;\n                if (abs(_2434) < 0.001000000047497451305389404296875)\n                {\n                    _2543 = _2455;\n                }\n                else\n                {\n                    _2543 = (_2516 - _2483) / _2434;\n                }\n                tau += (_2384 * max(_2543, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2676);\n}\n\n",
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
            "inst_name": "_421",
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
            "inst_name": "_657",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[24];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    bool _426 = fa_mesh_fs_params[19].x < 0.0;\n    bool _433;\n    if (!_426)\n    {\n        _433 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _433 = _426;\n    }\n    bool _441;\n    if (!_433)\n    {\n        _441 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _441 = _433;\n    }\n    bool _448;\n    if (!_441)\n    {\n        _448 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _448 = _441;\n    }\n    bool _455;\n    if (!_448)\n    {\n        _455 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _455 = _448;\n    }\n    if (_455)\n    {\n        return ivec2(0);\n    }\n    vec4 _465 = vec4(world_pos, 1.0);\n    float _472 = dot(fa_mesh_fs_params[16], _465);\n    if (!(_472 > 9.9999999747524270787835121154785e-07))\n    {\n        return ivec2(0);\n    }\n    vec2 _494 = vec2(dot(fa_mesh_fs_params[14], _465), dot(fa_mesh_fs_params[15], _465)) / vec2(_472);\n    int _498 = int(fa_mesh_fs_params[18].x);\n    int _502 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _502) + clamp(int(floor(((_494.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _502 - 1)) * _498)) + clamp(int(floor(((_494.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _498 - 1);\n    vec4 _573 = fa_light_texel(param);\n    return ivec2(int(_573.x), int(_573.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1735 = fa_cluster_lookup(param);\n    fa_cl_slot = _1735.x;\n    fa_cl_local = _1735.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1899 = fa_linear_to_srgb(param);\n        c = _1899;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1907 = fa_srgb_to_linear(param_1);\n            c = _1907;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _185;\n    if (i.front_facing)\n    {\n        _185 = i.world_normal;\n    }\n    else\n    {\n        _185 = -i.world_normal;\n    }\n    vec3 _209 = normalize(i.world_tangent.xyz - (_185 * dot(_185, i.world_tangent.xyz)));\n    vec3 _237 = normalize(((_209 * m.x) + ((cross(_185, _209) * i.world_tangent.w) * m.y)) + (_185 * m.z));\n    vec3 _240;\n    if (i.front_facing)\n    {\n        _240 = _237;\n    }\n    else\n    {\n        _240 = -_237;\n    }\n    return _240;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1938 = fa_tex_fix(param_2, param_3);\n    vec4 _2925 = base_t;\n    _2925.x = _1938.x;\n    _2925.y = _1938.y;\n    _2925.z = _1938.z;\n    base_t = _2925;\n    vec4 _1952 = (_2925 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2840 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1984 = fa_tex_fix(param_6, param_7);\n        vec3 _1988 = (_1984 * 2.0) - vec3(1.0);\n        vec2 _1993 = _1988.xy * fa_mesh_fs_params[6].x;\n        vec3 _2933 = _1988;\n        _2933.x = _1993.x;\n        _2933.y = _1993.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2933;\n        _2840 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2022 = fa_tex_fix(param_12, param_13);\n    vec4 _2936 = mrt;\n    _2936.x = _2022.x;\n    _2936.y = _2022.y;\n    _2936.z = _2022.z;\n    mrt = _2936;\n    vec4 _2051 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _2051.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2063 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2093 = fa_tex_fix(param_20, param_21);\n    float _2845 = fa_mesh_fs_params[20].x;\n    float _2846 = fa_mesh_fs_params[20].y;\n    float _2849 = fa_mesh_fs_params[20].z;\n    float _2848 = fa_mesh_fs_params[21].w;\n    float _2851 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _2845 *= _2063.y;\n            _2846 *= _2063.z;\n            _2848 *= _2051.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _2849 *= mrt.x;\n            _2851 *= mrt.w;\n        }\n    }\n    return Surface(_1952.xyz, _1952.w, _2840, clamp(fa_mesh_fs_params[5].x * _2022.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2022.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2063.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2093), _2845, _2846, fa_mesh_fs_params[21].xyz, _2848, _2849, fa_mesh_fs_params[20].w, _2851, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = (li * 4) + 3;\n    return fa_light_texel(param).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = (li * 4) + 1;\n    return fa_light_texel(param).w;\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _296 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _302 = fa_light_texel(param_1);\n    float _305 = _302.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _311 = _305 < 0.5;\n    vec3 l;\n    if (_311)\n    {\n        l = normalize(_296.xyz);\n    }\n    else\n    {\n        vec3 _323 = _296.xyz - world_pos;\n        float _325 = length(_323);\n        dist = _325;\n        l = _323 / vec3(max(_325, 9.9999997473787516355514526367188e-05));\n        float _340 = _325 / max(_296.w, 0.001000000047497451305389404296875);\n        float _346 = clamp(1.0 - (_340 * _340), 0.0, 1.0);\n        atten = _346 * _346;\n        if (_305 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _360 = fa_light_texel(param_2);\n            float _370 = _360.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _376 = fa_light_texel(param_3);\n            float _377 = _376.x;\n            float cos_inner = _377;\n            if (_377 > 1.5)\n            {\n                cos_inner = mix(_370, 1.0, 0.25);\n            }\n            atten *= smoothstep(_370, cos_inner, dot(-l, normalize(_360.xyz)));\n        }\n    }\n    int _407;\n    if (_311)\n    {\n        _407 = 0;\n    }\n    else\n    {\n        _407 = (_305 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _302.xyz * atten, atten, 1.0, dist, _407);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _647;\n    if (i == 0)\n    {\n        _647 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _663;\n        if (i == 1)\n        {\n            _663 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _671;\n            if (i == 2)\n            {\n                _671 = fa_shadows[24].z;\n            }\n            else\n            {\n                _671 = fa_shadows[24].w;\n            }\n            _663 = _671;\n        }\n        _647 = _663;\n    }\n    return _647;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _704 = fa_shadow_depth(param, param_1);\n    float _708;\n    if (conv.x < 0.5)\n    {\n        _708 = _704;\n    }\n    else\n    {\n        _708 = (conv.y * conv.z) / (conv.z - (_704 * (conv.z - conv.y)));\n    }\n    return _708;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _635 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_635), sin(_635)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _754 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _768 = clamp((k * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _754;\n            vec2 _787 = fa_shadow_vogel(param_3, param_4, param_5) * _768;\n            vec2 param_6 = uv + (_787 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _799 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_799 < (zr - (length(_787) * plane)))\n            {\n                sum += _799;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(zr - (sum / cnt), 0.0) * unit) * k) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _843 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _843; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _843;\n        float param_11 = _754;\n        vec2 _862 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_862 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_862) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_843);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _904 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _909 = clamp(dot(n, l), 0.0, 1.0);\n    float _915 = sqrt(1.0 - (_909 * _909));\n    float _923 = min(_915 / max(_909, 0.20000000298023223876953125), 4.0);\n    float _928;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _928 = fa_shadows[26].y;\n    }\n    else\n    {\n        _928 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _953 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_928 * _915)), 1.0);\n    float _960 = _953.x;\n    bool _963 = _960 < fa_shadows[ci * 1 + 16].x;\n    bool _972;\n    if (!_963)\n    {\n        _972 = _960 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _972 = _963;\n    }\n    bool _981;\n    if (!_972)\n    {\n        _981 = _953.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _981 = _972;\n    }\n    bool _990;\n    if (!_981)\n    {\n        _990 = _953.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _990 = _981;\n    }\n    bool _997;\n    if (!_990)\n    {\n        _997 = _953.z > 1.0;\n    }\n    else\n    {\n        _997 = _990;\n    }\n    if (_997)\n    {\n        return -1.0;\n    }\n    float _1006;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1006 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1006 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _953.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _953.z - ((_1006 * (1.0 + (0.5 * _923))) / _904);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _904;\n    float param_5 = _904 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_923, 3.0)) * 0.5) / _904;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1434 = int(fa_shadows[25].x + 0.5);\n    if (_1434 < 1)\n    {\n        return 1.0;\n    }\n    float _1450 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1434 - 1;\n    if (_1450 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1462 = _1434 > 1;\n    bool _1469;\n    if (_1462)\n    {\n        _1469 = _1450 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1469 = _1462;\n    }\n    if (_1469)\n    {\n        ci = 1;\n    }\n    bool _1473 = _1434 > 2;\n    bool _1480;\n    if (_1473)\n    {\n        _1480 = _1450 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1480 = _1473;\n    }\n    if (_1480)\n    {\n        ci = 2;\n    }\n    bool _1484 = _1434 > 3;\n    bool _1491;\n    if (_1484)\n    {\n        _1491 = _1450 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1491 = _1484;\n    }\n    if (_1491)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1434)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1517 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1517;\n        if (_1517 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1542;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1542 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1542 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1561 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1542, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1572 = clamp((_1450 - (fa_shadow_split_at(param_7) - _1561)) / _1561, 0.0, 1.0);\n        if (_1572 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1434)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1593 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1593;\n                if (_1593 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1572);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 world, vec3 n, vec3 l)\n{\n    bool _1065 = fa_mesh_fs_params[5].z < 0.5;\n    bool _1073;\n    if (!_1065)\n    {\n        _1073 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _1073 = _1065;\n    }\n    if (_1073)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _1086 = fa_light_texel(param);\n    float _1087 = _1086.x;\n    if (_1087 < 0.0)\n    {\n        return 1.0;\n    }\n    int _1096 = int(_1087 + 0.5);\n    int param_1 = _1096;\n    vec4 _1100 = fa_light_texel(param_1);\n    int param_2 = _1096 + 1;\n    vec4 _1105 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _1108 = _1100.y;\n    if (_1108 > 0.0)\n    {\n        float _1125 = 1.0 - smoothstep(0.75 * _1108, _1108, length(world - fa_shadows[27].xyz));\n        fade = _1125;\n        if (_1125 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_1100.x > 1.5)\n    {\n        int param_3 = li * 4;\n        vec3 _1144 = world - fa_light_texel(param_3).xyz;\n        vec3 _1147 = abs(_1144);\n        float _1149 = _1147.x;\n        float _1151 = _1147.y;\n        bool _1152 = _1149 >= _1151;\n        bool _1160;\n        if (_1152)\n        {\n            _1160 = _1149 >= _1147.z;\n        }\n        else\n        {\n            _1160 = _1152;\n        }\n        int _1161;\n        if (_1160)\n        {\n            _1161 = (_1144.x > 0.0) ? 0 : 1;\n        }\n        else\n        {\n            int _1174;\n            if (_1151 >= _1147.z)\n            {\n                _1174 = (_1144.y > 0.0) ? 2 : 3;\n            }\n            else\n            {\n                _1174 = (_1144.z > 0.0) ? 4 : 5;\n            }\n            _1161 = _1174;\n        }\n        face = _1161;\n    }\n    int _1193 = (_1096 + 2) + (face * 6);\n    int param_4 = _1193;\n    int param_5 = _1193 + 1;\n    int param_6 = _1193 + 3;\n    vec4 _1207 = fa_light_texel(param_6);\n    int param_7 = _1193 + 4;\n    vec4 _1212 = fa_light_texel(param_7);\n    int param_8 = _1193 + 5;\n    vec4 _1217 = fa_light_texel(param_8);\n    float _1229 = _1217.x * max(dot(_1207, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _1234 = clamp(dot(n, l), 0.0, 1.0);\n    float _1257 = clamp(dot(n, _1207.xyz), -1.0, 1.0);\n    int param_9 = li * 4;\n    float _1280 = min(sqrt(1.0 - (_1257 * _1257)) / max(abs(dot(n, world - fa_light_texel(param_9).xyz)) / max(dot(_1207, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _1283 = _1105.y;\n    float _1285;\n    if (_1283 > 0.0)\n    {\n        _1285 = _1283;\n    }\n    else\n    {\n        _1285 = 1.5 * _1229;\n    }\n    vec4 _1305 = vec4(world + (n * (_1285 * sqrt(1.0 - (_1234 * _1234)))), 1.0);\n    float _1309 = dot(_1207, _1305);\n    float _1312 = _1217.y;\n    if (_1309 < _1312)\n    {\n        return 1.0;\n    }\n    vec2 _1327 = vec2(dot(fa_light_texel(param_4), _1305), dot(fa_light_texel(param_5), _1305)) / vec2(_1309);\n    float _1329 = _1327.x;\n    bool _1332 = _1329 < _1212.x;\n    bool _1341;\n    if (!_1332)\n    {\n        _1341 = _1329 > _1212.z;\n    }\n    else\n    {\n        _1341 = _1332;\n    }\n    bool _1350;\n    if (!_1341)\n    {\n        _1350 = _1327.y < _1212.y;\n    }\n    else\n    {\n        _1350 = _1341;\n    }\n    bool _1359;\n    if (!_1350)\n    {\n        _1359 = _1327.y > _1212.w;\n    }\n    else\n    {\n        _1359 = _1350;\n    }\n    if (_1359)\n    {\n        return 1.0;\n    }\n    float _1365 = _1105.x;\n    float _1367;\n    if (_1365 > 0.0)\n    {\n        _1367 = _1365;\n    }\n    else\n    {\n        _1367 = 1.5 * _1229;\n    }\n    vec2 param_10 = _1327;\n    vec4 param_11 = _1212;\n    float param_12 = _1309 - (_1367 * (1.0 + (0.5 * _1280)));\n    float param_13 = _1229;\n    float param_14 = 1.0;\n    float param_15 = _1217.z * 0.25;\n    float param_16 = (_1229 * min(_1280, 3.0)) * 0.5;\n    vec3 param_17 = vec3(1.0, _1312, _1217.z);\n    int param_18 = int(_1100.z + 0.5);\n    float param_19 = _1100.w;\n    return mix(1.0, fa_shadow_filter(param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18, param_19), fade);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _1762 = fa_lm.z > 0.5;\n    bool _1768;\n    if (_1762)\n    {\n        int param = li;\n        _1768 = fa_light_baked(param);\n    }\n    else\n    {\n        _1768 = _1762;\n    }\n    if (_1768)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    LightSample _1791 = fa_light_sample(param_2, param_3);\n    vec3 _2825 = _1791.direction;\n    vec3 _2820 = _1791.color;\n    float _2827 = _1791.attenuation;\n    float _2822 = _1791.shadow;\n    int _2830 = _1791.type;\n    if ((_2830 == 0) && (li == 0))\n    {\n        vec3 param_4 = gn;\n        vec3 param_5 = _2825;\n        float _1805 = fa_shadow_factor(param_4, param_5);\n        _2822 = _1805;\n        _2820 *= _1805;\n    }\n    else\n    {\n        bool _1816 = _2830 != 0;\n        bool _1822;\n        if (_1816)\n        {\n            _1822 = _2827 > 0.0;\n        }\n        else\n        {\n            _1822 = _1816;\n        }\n        if (_1822)\n        {\n            int param_6 = li;\n            vec3 param_7 = world_pos;\n            vec3 param_8 = gn;\n            vec3 param_9 = _2825;\n            float _1834 = fa_shadow_local(param_6, param_7, param_8, param_9);\n            _2822 = _1834;\n            _2820 *= _1834;\n        }\n    }\n    return LightSample(_2825, _2820, _2827, _2822, _1791._distance, _2830);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1617 = int(fa_shadows[25].x + 0.5);\n    float _1627 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1632 = _1617 > 0;\n    bool _1641;\n    if (_1632)\n    {\n        int param = _1617 - 1;\n        _1641 = _1627 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1641 = _1632;\n    }\n    if (_1641)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1648 = _1617 > 1;\n        bool _1655;\n        if (_1648)\n        {\n            _1655 = _1627 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1655 = _1648;\n        }\n        if (_1655)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1661 = _1617 > 2;\n        bool _1668;\n        if (_1661)\n        {\n            _1668 = _1627 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1668 = _1661;\n        }\n        if (_1668)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1674 = _1617 > 3;\n        bool _1681;\n        if (_1674)\n        {\n            _1681 = _1627 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1681 = _1674;\n        }\n        if (_1681)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2636 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2636 = -_2636;\n    }\n    vec3 _2237 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing);\n    Surface _2245 = fa_standard_surface(param_1);\n    vec3 _2675 = _2245.albedo;\n    float _2676 = _2245.alpha;\n    vec3 _2677 = _2245.normal;\n    float _2678 = _2245.metallic;\n    float _2679 = _2245.roughness;\n    float _2680 = _2245.occlusion;\n    vec3 _2681 = _2245.emission;\n    float _2682 = _2245.clearcoat;\n    float _2683 = _2245.clearcoat_roughness;\n    vec3 _2684 = _2245.sheen_color;\n    float _2685 = _2245.sheen_roughness;\n    float _2686 = _2245.anisotropy;\n    float _2687 = _2245.anisotropy_rotation;\n    float _2688 = _2245.specular;\n    float _2689 = _2245.ior;\n    vec3 _2690 = _2245.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing);\n    Surface param_3 = _2245;\n    surface(param_2, param_3);\n    _2675 = param_3.albedo;\n    _2676 = param_3.alpha;\n    _2677 = param_3.normal;\n    _2678 = param_3.metallic;\n    _2679 = param_3.roughness;\n    _2680 = param_3.occlusion;\n    _2681 = param_3.emission;\n    _2682 = param_3.clearcoat;\n    _2683 = param_3.clearcoat_roughness;\n    _2684 = param_3.sheen_color;\n    _2685 = param_3.sheen_roughness;\n    _2686 = param_3.anisotropy;\n    _2687 = param_3.anisotropy_rotation;\n    _2688 = param_3.specular;\n    _2689 = param_3.ior;\n    _2690 = param_3.specular_color;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2675;\n    }\n    else\n    {\n        vec3 _2266 = _2677;\n        vec3 _2267 = normalize(_2266);\n        _2677 = _2267;\n        vec3 param_4 = _2267;\n        SurfaceInput param_5 = SurfaceInput(fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing);\n        Surface param_6 = Surface(_2675, _2676, _2677, _2678, _2679, _2680, _2681, _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690);\n        vec3 param_7 = fa_indirect_diffuse(param_4);\n        vec3 lit = ambient(param_5, param_6, param_7);\n        int _2286 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2286; ln++)\n        {\n            int param_8 = ln;\n            int _2299 = fa_cl_light(param_8);\n            bool _2302 = fa_lm.z > 0.5;\n            bool _2308;\n            if (_2302)\n            {\n                int param_9 = _2299;\n                _2308 = fa_light_baked(param_9);\n            }\n            else\n            {\n                _2308 = _2302;\n            }\n            if (_2308)\n            {\n                continue;\n            }\n            int param_10 = _2299;\n            vec3 param_11 = fa_world_pos;\n            vec3 param_12 = _2636;\n            SurfaceInput param_13 = SurfaceInput(fa_world_pos, _2636, fa_world_tangent, fa_uv, fa_vertex_color, _2237, gl_FrontFacing);\n            Surface param_14 = Surface(_2675, _2676, _2677, _2678, _2679, _2680, _2681, _2682, _2683, _2684, _2685, _2686, _2687, _2688, _2689, _2690);\n            LightSample param_15 = fa_light_shadowed(param_10, param_11, param_12);\n            lit += light(param_13, param_14, param_15);\n        }\n        result = lit;\n    }\n    vec3 _2335 = result;\n    vec3 _2336 = _2335 + _2681;\n    result = _2336;\n    vec3 param_16 = _2336;\n    vec3 param_17 = fa_world_pos;\n    result = fa_shadow_debug(param_16, param_17);\n    bool _2345 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2352;\n    if (!_2345)\n    {\n        _2352 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2352 = _2345;\n    }\n    if (_2352)\n    {\n        vec3 _2361 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2367 = dot(_2361, fa_mesh_fs_params[9].xyz);\n        bool _2371 = fa_mesh_fs_params[9].w > 0.5;\n        float _2372;\n        if (_2371)\n        {\n            _2372 = _2367;\n        }\n        else\n        {\n            _2372 = length(_2361);\n        }\n        float _2384 = _2372 - fa_mesh_fs_params[8].x;\n        if (_2384 > 0.0)\n        {\n            float _2393 = fa_mesh_fs_params[7].w * _2384;\n            float tau = _2393 * _2393;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2409;\n                if (_2371)\n                {\n                    _2409 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2367);\n                }\n                else\n                {\n                    _2409 = fa_mesh_fs_params[0].y;\n                }\n                float _2430 = mix(_2409, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2372, 0.0, 1.0));\n                float _2434 = fa_world_pos.y - _2430;\n                float _2439 = _2430 - fa_mesh_fs_params[8].z;\n                float _2444 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2447 = _2439 <= 0.0;\n                bool _2448 = !_2447;\n                bool _2454;\n                if (_2448)\n                {\n                    _2454 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2454 = _2447;\n                }\n                float _2455;\n                if (_2454)\n                {\n                    _2455 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2455 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2439, 80.0));\n                }\n                bool _2482;\n                if (_2448)\n                {\n                    _2482 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2482 = _2447;\n                }\n                float _2483;\n                if (_2482)\n                {\n                    _2483 = fa_mesh_fs_params[8].y * _2439;\n                }\n                else\n                {\n                    _2483 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2439, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2508 = _2444 <= 0.0;\n                bool _2515;\n                if (!_2508)\n                {\n                    _2515 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2515 = _2508;\n                }\n                float _2516;\n                if (_2515)\n                {\n                    _2516 = fa_mesh_fs_params[8].y * _2444;\n                }\n                else\n                {\n                    _2516 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2444, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2543;\n                if (abs(_2434) < 0.001000000047497451305389404296875)\n                {\n                    _2543 = _2455;\n                }\n                else\n                {\n                    _2543 = (_2516 - _2483) / _2434;\n                }\n                tau += (_2384 * max(_2543, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2676);\n}\n\n",
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
            "inst_name": "_421",
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
            "inst_name": "_657",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
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
