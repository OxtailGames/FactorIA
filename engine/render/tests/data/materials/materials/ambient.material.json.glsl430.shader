{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "41c86c92dbb0093951c81b6ee249cbb5aa749f4b053c4954c67a5e43bd66f6f3",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _265 = _160.world_pos;\n    fa_world_pos = _265;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_265, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _399 = fa_mesh_fs_params[19].x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return vec4(0.0);\n    }\n    vec4 _438 = vec4(world_pos, 1.0);\n    float _445 = dot(fa_mesh_fs_params[16], _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _467 = vec2(dot(fa_mesh_fs_params[14], _438), dot(fa_mesh_fs_params[15], _438)) / vec2(_445);\n    int _471 = int(fa_mesh_fs_params[18].x);\n    int _475 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _471 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _551 = fa_cluster_texel(param);\n    return ivec2(int(_551.x), int(_551.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1792 = fa_cluster_lookup(param);\n    fa_cl_slot = _1792.x;\n    fa_cl_local = _1792.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1888 = fa_linear_to_srgb(param);\n        c = _1888;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1896 = fa_srgb_to_linear(param_1);\n            c = _1896;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _175;\n    if (i.front_facing)\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    vec3 _199 = normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    vec3 _227 = normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    vec3 _230;\n    if (i.front_facing)\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1927 = fa_tex_fix(param_2, param_3);\n    vec4 _2682 = base_t;\n    _2682.x = _1927.x;\n    _2682.y = _1927.y;\n    _2682.z = _1927.z;\n    base_t = _2682;\n    vec4 _1941 = (_2682 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2612 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1973 = fa_tex_fix(param_6, param_7);\n        vec3 _1976 = (_1973 * 2.0) - vec3(1.0);\n        vec2 _1981 = _1976.xy * fa_mesh_fs_params[6].x;\n        vec3 _2690 = _1976;\n        _2690.x = _1981.x;\n        _2690.y = _1981.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2690;\n        _2612 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2010 = fa_tex_fix(param_12, param_13);\n    vec4 _2693 = mrt;\n    _2693.x = _2010.x;\n    _2693.y = _2010.y;\n    _2693.z = _2010.z;\n    mrt = _2693;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2049 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2076 = fa_tex_fix(param_20, param_21);\n    return Surface(_1941.xyz, _1941.w, _2612, clamp(fa_mesh_fs_params[5].x * _2010.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2010.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2049.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2076));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _632 = rect.zw - rect.xy;\n    vec2 _636 = _632 * atlas;\n    vec2 _640 = ddx * _636;\n    vec2 _644 = ddy * _636;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _632), clamp(0.5 * log2(max(max(dot(_640, _640), dot(_644, _644)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _679 = dFdx(world_pos);\n    vec3 _682 = dFdy(world_pos);\n    bool _685 = fa_mesh_fs_params[10].y < 0.5;\n    bool _692;\n    if (!_685)\n    {\n        _692 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _692 = _685;\n    }\n    if (_692)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _699 = fa_cluster_texel(param);\n    int _703 = int(_699.w);\n    if (_703 < 1)\n    {\n        return;\n    }\n    int _713 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _713;\n    vec4 _717 = fa_light_texel(param_1);\n    vec2 _720 = _717.yz;\n    int _724 = int(_717.w);\n    int param_2 = _713 + 1;\n    vec4 _729 = fa_light_texel(param_2);\n    float _730 = _729.x;\n    int _736 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _740 = int(_699.z);\n    vec3 _1006;\n    for (int k = 0; k < _703; k++)\n    {\n        int _753 = _740 + k;\n        int param_3 = _724 + (_753 >> 2);\n        int _771 = (_713 + 2) + (int(fa_light_texel(param_3)[_753 & 3]) * 7);\n        int param_4 = _771 + 6;\n        vec4 _776 = fa_light_texel(param_4);\n        if (((int(_776.w + 0.5) >> _736) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _771;\n        vec4 _791 = fa_light_texel(param_5);\n        int param_6 = _771 + 1;\n        vec4 _796 = fa_light_texel(param_6);\n        int param_7 = _771 + 2;\n        vec4 _801 = fa_light_texel(param_7);\n        vec3 _804 = _791.xyz;\n        float _809 = dot(_804, world_pos) + _791.w;\n        vec3 _811 = _796.xyz;\n        float _816 = dot(_811, world_pos) + _796.w;\n        vec3 _818 = _801.xyz;\n        float _823 = dot(_818, world_pos) + _801.w;\n        bool _828 = abs(_809) > 0.5;\n        bool _836;\n        if (!_828)\n        {\n            _836 = abs(_816) > 0.5;\n        }\n        else\n        {\n            _836 = _828;\n        }\n        bool _844;\n        if (!_836)\n        {\n            _844 = abs(_823) > 0.5;\n        }\n        else\n        {\n            _844 = _836;\n        }\n        if (_844)\n        {\n            continue;\n        }\n        float _859 = clamp(dot(geo_normal, normalize(_818)) * _776.z, 0.0, 1.0);\n        if (_859 <= 0.0)\n        {\n            continue;\n        }\n        float _879 = (clamp((0.5 - abs(_823)) * 10.0, 0.0, 1.0) * _859) * _776.x;\n        vec2 _887 = vec2(_809 + 0.5, 0.5 - _816);\n        vec2 _897 = vec2(dot(_804, _679), dot(_811, _679));\n        vec2 _907 = vec2(dot(_804, _682), dot(_811, _682));\n        int param_8 = _771 + 5;\n        vec4 _912 = fa_light_texel(param_8);\n        int param_9 = _771 + 3;\n        vec4 _917 = fa_light_texel(param_9);\n        int param_10 = _771 + 4;\n        vec4 _922 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _912.xyz;\n        bool _932 = _917.z > _917.x;\n        if (_932)\n        {\n            vec4 param_11 = _917;\n            vec2 param_12 = _887;\n            vec2 param_13 = _720;\n            vec2 param_14 = _897;\n            vec2 param_15 = _907;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_730 > 0.5) && (_730 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _958 = fa_dc_to_linear(param_16);\n                vec4 _2650 = tx;\n                _2650.x = _958.x;\n                _2650.y = _958.y;\n                _2650.z = _958.z;\n                tx = _2650;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_879 * tex_a) * _912.w, 0.0, 1.0)));\n        if (_922.z > _922.x)\n        {\n            vec4 param_17 = _922;\n            vec2 param_18 = _887;\n            vec2 param_19 = _720;\n            vec2 param_20 = _897;\n            vec2 param_21 = _907;\n            vec4 _1002 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_730 > 1.5)\n            {\n                vec3 param_22 = _1002.xyz;\n                vec3 _1012 = fa_dc_to_srgb(param_22);\n                _1006 = _1012;\n            }\n            else\n            {\n                _1006 = _1002.xyz;\n            }\n            vec3 _1022 = (_1006 * 2.0) - vec3(1.0);\n            vec2 _1027 = _1022.xy * _776.y;\n            vec3 _1049 = (normalize(_804) * _1027.x) + (normalize(_811) * _1027.y);\n            vec3 _1052 = normalize(normal);\n            normal = normalize(mix(_1052, normalize((_1052 * max(_1022.z, 0.0500000007450580596923828125)) + (_1049 - (_1052 * dot(_1052, _1049)))), vec3(clamp(_879 * (_932 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _267 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _273 = fa_light_texel(param_1);\n    float _276 = _273.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _283 = _276 < 0.5;\n    vec3 l;\n    if (_283)\n    {\n        l = normalize(_267.xyz);\n    }\n    else\n    {\n        vec3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / vec3(max(_297, 9.9999997473787516355514526367188e-05));\n        float _312 = _297 / max(_267.w, 0.001000000047497451305389404296875);\n        float _318 = clamp(1.0 - (_312 * _312), 0.0, 1.0);\n        atten = _318 * _318;\n        if (_276 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _332 = fa_light_texel(param_2);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _349 = fa_light_texel(param_3);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5)\n            {\n                cos_inner = mix(_342, 1.0, 0.25);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _273.xyz * atten, atten, 1.0, dist, _380);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1124;\n    if (i == 0)\n    {\n        _1124 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1140;\n        if (i == 1)\n        {\n            _1140 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1148;\n            if (i == 2)\n            {\n                _1148 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1148 = fa_shadows[24].w;\n            }\n            _1140 = _1148;\n        }\n        _1124 = _1140;\n    }\n    return _1124;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1112 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1112), sin(_1112)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1186 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1191 = clamp(dot(n, l), 0.0, 1.0);\n    float _1197 = sqrt(1.0 - (_1191 * _1191));\n    float _1204 = min(_1197 / max(_1191, 0.20000000298023223876953125), 4.0);\n    float _1209;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1209 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1209 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1234 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1209 * _1197)), 1.0);\n    float _1241 = _1234.x;\n    bool _1244 = _1241 < fa_shadows[ci * 1 + 16].x;\n    bool _1253;\n    if (!_1244)\n    {\n        _1253 = _1241 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1253 = _1244;\n    }\n    bool _1262;\n    if (!_1253)\n    {\n        _1262 = _1234.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    bool _1271;\n    if (!_1262)\n    {\n        _1271 = _1234.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1271 = _1262;\n    }\n    bool _1278;\n    if (!_1271)\n    {\n        _1278 = _1234.z > 1.0;\n    }\n    else\n    {\n        _1278 = _1271;\n    }\n    if (_1278)\n    {\n        return -1.0;\n    }\n    float _1287;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1287 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1287 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1306 = _1234.z - ((_1287 * (1.0 + (0.5 * _1204))) / _1186);\n    float _1315 = ((fa_shadows[ci * 1 + 20].x * min(_1204, 3.0)) * 0.5) / _1186;\n    int _1324 = int(fa_shadows[25].z + 0.5);\n    if (_1324 == 1)\n    {\n        vec2 param = _1234.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1335 = fa_shadow_depth(param, param_1);\n        return float(_1306 <= _1335);\n    }\n    float _1342 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1345 = _1324 == 2;\n    if (_1345)\n    {\n        float _1359 = clamp(((fa_shadows[25].w * _1186) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1342;\n            vec2 _1378 = fa_shadow_vogel(param_2, param_3, param_4) * _1359;\n            vec2 param_5 = _1234.xy + (_1378 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1389 = fa_shadow_depth(param_5, param_6);\n            if (_1389 < (_1306 - (length(_1378) * _1315)))\n            {\n                sum += _1389;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1306 - (sum / cnt), 0.0) * _1186) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1433 = _1345 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1433; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1433;\n        float param_9 = _1342;\n        vec2 _1452 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1234.xy + (_1452 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1463 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1306 - (length(_1452) * _1315)) <= _1463);\n    }\n    return lit / float(_1433);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1493 = int(fa_shadows[25].x + 0.5);\n    if (_1493 < 1)\n    {\n        return 1.0;\n    }\n    float _1508 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1493 - 1;\n    if (_1508 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1520 = _1493 > 1;\n    bool _1527;\n    if (_1520)\n    {\n        _1527 = _1508 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        ci = 1;\n    }\n    bool _1531 = _1493 > 2;\n    bool _1538;\n    if (_1531)\n    {\n        _1538 = _1508 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1538 = _1531;\n    }\n    if (_1538)\n    {\n        ci = 2;\n    }\n    bool _1542 = _1493 > 3;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1508 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1493)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1575 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1575;\n        if (_1575 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1600;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1600 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1600 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1619 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1600, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1630 = clamp((_1508 - (fa_shadow_split_at(param_7) - _1619)) / _1619, 0.0, 1.0);\n        if (_1630 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1493)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1651 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1651;\n                if (_1651 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1630);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1820 = fa_light_sample(param, param_1);\n    vec3 _2597 = _1820.direction;\n    vec3 _2592 = _1820.color;\n    float _2594 = _1820.shadow;\n    int _2602 = _1820.type;\n    if ((_2602 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2597;\n        float _1834 = fa_shadow_factor(param_2, param_3);\n        _2594 = _1834;\n        _2592 *= _1834;\n    }\n    return LightSample(_2597, _2592, _1820.attenuation, _2594, _1820._distance, _2602);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1675 = int(fa_shadows[25].x + 0.5);\n    float _1685 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1690 = _1675 > 0;\n    bool _1699;\n    if (_1690)\n    {\n        int param = _1675 - 1;\n        _1699 = _1685 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1699 = _1690;\n    }\n    if (_1699)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1706 = _1675 > 1;\n        bool _1713;\n        if (_1706)\n        {\n            _1713 = _1685 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1713 = _1706;\n        }\n        if (_1713)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1719 = _1675 > 2;\n        bool _1726;\n        if (_1719)\n        {\n            _1726 = _1685 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1726 = _1719;\n        }\n        if (_1726)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1732 = _1675 > 3;\n        bool _1739;\n        if (_1732)\n        {\n            _1739 = _1685 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1739 = _1732;\n        }\n        if (_1739)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2475 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2475 = -_2475;\n    }\n    vec3 _2119 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing);\n    Surface _2127 = fa_standard_surface(param_1);\n    vec3 _2514 = _2127.albedo;\n    float _2515 = _2127.alpha;\n    vec3 _2516 = _2127.normal;\n    float _2517 = _2127.metallic;\n    float _2518 = _2127.roughness;\n    float _2519 = _2127.occlusion;\n    vec3 _2520 = _2127.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing);\n    Surface param_3 = _2127;\n    surface(param_2, param_3);\n    _2514 = param_3.albedo;\n    _2515 = param_3.alpha;\n    _2516 = param_3.normal;\n    _2517 = param_3.metallic;\n    _2518 = param_3.roughness;\n    _2519 = param_3.occlusion;\n    _2520 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2475;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2514 = param_6;\n    _2516 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2514;\n    }\n    else\n    {\n        vec3 _2165 = _2516;\n        vec3 _2166 = normalize(_2165);\n        _2516 = _2166;\n        vec3 param_8 = _2166;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing);\n        Surface param_10 = Surface(_2514, _2515, _2516, _2517, _2518, _2519, _2520);\n        vec3 param_11 = fa_ambient_light(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _2185 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2185; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12);\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _2475;\n            SurfaceInput param_16 = SurfaceInput(fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing);\n            Surface param_17 = Surface(_2514, _2515, _2516, _2517, _2518, _2519, _2520);\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    vec3 _2222 = result;\n    vec3 _2223 = _2222 + _2520;\n    result = _2223;\n    vec3 param_19 = _2223;\n    vec3 param_20 = fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20);\n    bool _2232 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2240;\n    if (!_2232)\n    {\n        _2240 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2240 = _2232;\n    }\n    if (_2240)\n    {\n        vec3 _2249 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2256 = dot(_2249, fa_mesh_fs_params[9].xyz);\n        bool _2260 = fa_mesh_fs_params[9].w > 0.5;\n        float _2261;\n        if (_2260)\n        {\n            _2261 = _2256;\n        }\n        else\n        {\n            _2261 = length(_2249);\n        }\n        float _2273 = _2261 - fa_mesh_fs_params[8].x;\n        if (_2273 > 0.0)\n        {\n            float _2282 = fa_mesh_fs_params[7].w * _2273;\n            float tau = _2282 * _2282;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2298;\n                if (_2260)\n                {\n                    _2298 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2256);\n                }\n                else\n                {\n                    _2298 = fa_mesh_fs_params[0].y;\n                }\n                float _2319 = mix(_2298, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2261, 0.0, 1.0));\n                float _2323 = fa_world_pos.y - _2319;\n                float _2328 = _2319 - fa_mesh_fs_params[8].z;\n                float _2333 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2336 = _2328 <= 0.0;\n                bool _2337 = !_2336;\n                bool _2343;\n                if (_2337)\n                {\n                    _2343 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2343 = _2336;\n                }\n                float _2344;\n                if (_2343)\n                {\n                    _2344 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2344 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2328, 80.0));\n                }\n                bool _2371;\n                if (_2337)\n                {\n                    _2371 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2371 = _2336;\n                }\n                float _2372;\n                if (_2371)\n                {\n                    _2372 = fa_mesh_fs_params[8].y * _2328;\n                }\n                else\n                {\n                    _2372 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2328, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2397 = _2333 <= 0.0;\n                bool _2404;\n                if (!_2397)\n                {\n                    _2404 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2404 = _2397;\n                }\n                float _2405;\n                if (_2404)\n                {\n                    _2405 = fa_mesh_fs_params[8].y * _2333;\n                }\n                else\n                {\n                    _2405 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2333, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2432;\n                if (abs(_2323) < 0.001000000047497451305389404296875)\n                {\n                    _2432 = _2344;\n                }\n                else\n                {\n                    _2432 = (_2405 - _2372) / _2323;\n                }\n                tau += (_2273 * max(_2432, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2515);\n}\n\n",
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
            "inst_name": "_394",
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
            "inst_name": "_1134",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _386 = _273.world_pos;\n    fa_world_pos = _386;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_386, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nuniform vec4 fa_shadows[29];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform samplerCube fa_irr_tex_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _399 = fa_mesh_fs_params[19].x < 0.0;\n    bool _406;\n    if (!_399)\n    {\n        _406 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _406 = _399;\n    }\n    bool _414;\n    if (!_406)\n    {\n        _414 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _414 = _406;\n    }\n    bool _421;\n    if (!_414)\n    {\n        _421 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _421 = _414;\n    }\n    bool _428;\n    if (!_421)\n    {\n        _428 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _428 = _421;\n    }\n    if (_428)\n    {\n        return vec4(0.0);\n    }\n    vec4 _438 = vec4(world_pos, 1.0);\n    float _445 = dot(fa_mesh_fs_params[16], _438);\n    if (!(_445 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _467 = vec2(dot(fa_mesh_fs_params[14], _438), dot(fa_mesh_fs_params[15], _438)) / vec2(_445);\n    int _471 = int(fa_mesh_fs_params[18].x);\n    int _475 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _475) + clamp(int(floor(((_467.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _475 - 1)) * _471)) + clamp(int(floor(((_467.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _471 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _551 = fa_cluster_texel(param);\n    return ivec2(int(_551.x), int(_551.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _1792 = fa_cluster_lookup(param);\n    fa_cl_slot = _1792.x;\n    fa_cl_local = _1792.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _1888 = fa_linear_to_srgb(param);\n        c = _1888;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _1896 = fa_srgb_to_linear(param_1);\n            c = _1896;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _175;\n    if (i.front_facing)\n    {\n        _175 = i.world_normal;\n    }\n    else\n    {\n        _175 = -i.world_normal;\n    }\n    vec3 _199 = normalize(i.world_tangent.xyz - (_175 * dot(_175, i.world_tangent.xyz)));\n    vec3 _227 = normalize(((_199 * m.x) + ((cross(_175, _199) * i.world_tangent.w) * m.y)) + (_175 * m.z));\n    vec3 _230;\n    if (i.front_facing)\n    {\n        _230 = _227;\n    }\n    else\n    {\n        _230 = -_227;\n    }\n    return _230;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _1927 = fa_tex_fix(param_2, param_3);\n    vec4 _2682 = base_t;\n    _2682.x = _1927.x;\n    _2682.y = _1927.y;\n    _2682.z = _1927.z;\n    base_t = _2682;\n    vec4 _1941 = (_2682 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _2612 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _1973 = fa_tex_fix(param_6, param_7);\n        vec3 _1976 = (_1973 * 2.0) - vec3(1.0);\n        vec2 _1981 = _1976.xy * fa_mesh_fs_params[6].x;\n        vec3 _2690 = _1976;\n        _2690.x = _1981.x;\n        _2690.y = _1981.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _2690;\n        _2612 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _2010 = fa_tex_fix(param_12, param_13);\n    vec4 _2693 = mrt;\n    _2693.x = _2010.x;\n    _2693.y = _2010.y;\n    _2693.z = _2010.z;\n    mrt = _2693;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _2049 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _2076 = fa_tex_fix(param_20, param_21);\n    return Surface(_1941.xyz, _1941.w, _2612, clamp(fa_mesh_fs_params[5].x * _2010.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _2010.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_2049.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _2076));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _632 = rect.zw - rect.xy;\n    vec2 _636 = _632 * atlas;\n    vec2 _640 = ddx * _636;\n    vec2 _644 = ddy * _636;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _632), clamp(0.5 * log2(max(max(dot(_640, _640), dot(_644, _644)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    vec3 _679 = dFdx(world_pos);\n    vec3 _682 = dFdy(world_pos);\n    bool _685 = fa_mesh_fs_params[10].y < 0.5;\n    bool _692;\n    if (!_685)\n    {\n        _692 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _692 = _685;\n    }\n    if (_692)\n    {\n        return;\n    }\n    vec3 param = world_pos;\n    vec4 _699 = fa_cluster_texel(param);\n    int _703 = int(_699.w);\n    if (_703 < 1)\n    {\n        return;\n    }\n    int _713 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _713;\n    vec4 _717 = fa_light_texel(param_1);\n    vec2 _720 = _717.yz;\n    int _724 = int(_717.w);\n    int param_2 = _713 + 1;\n    vec4 _729 = fa_light_texel(param_2);\n    float _730 = _729.x;\n    int _736 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _740 = int(_699.z);\n    vec3 _1006;\n    for (int k = 0; k < _703; k++)\n    {\n        int _753 = _740 + k;\n        int param_3 = _724 + (_753 >> 2);\n        int _771 = (_713 + 2) + (int(fa_light_texel(param_3)[_753 & 3]) * 7);\n        int param_4 = _771 + 6;\n        vec4 _776 = fa_light_texel(param_4);\n        if (((int(_776.w + 0.5) >> _736) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _771;\n        vec4 _791 = fa_light_texel(param_5);\n        int param_6 = _771 + 1;\n        vec4 _796 = fa_light_texel(param_6);\n        int param_7 = _771 + 2;\n        vec4 _801 = fa_light_texel(param_7);\n        vec3 _804 = _791.xyz;\n        float _809 = dot(_804, world_pos) + _791.w;\n        vec3 _811 = _796.xyz;\n        float _816 = dot(_811, world_pos) + _796.w;\n        vec3 _818 = _801.xyz;\n        float _823 = dot(_818, world_pos) + _801.w;\n        bool _828 = abs(_809) > 0.5;\n        bool _836;\n        if (!_828)\n        {\n            _836 = abs(_816) > 0.5;\n        }\n        else\n        {\n            _836 = _828;\n        }\n        bool _844;\n        if (!_836)\n        {\n            _844 = abs(_823) > 0.5;\n        }\n        else\n        {\n            _844 = _836;\n        }\n        if (_844)\n        {\n            continue;\n        }\n        float _859 = clamp(dot(geo_normal, normalize(_818)) * _776.z, 0.0, 1.0);\n        if (_859 <= 0.0)\n        {\n            continue;\n        }\n        float _879 = (clamp((0.5 - abs(_823)) * 10.0, 0.0, 1.0) * _859) * _776.x;\n        vec2 _887 = vec2(_809 + 0.5, 0.5 - _816);\n        vec2 _897 = vec2(dot(_804, _679), dot(_811, _679));\n        vec2 _907 = vec2(dot(_804, _682), dot(_811, _682));\n        int param_8 = _771 + 5;\n        vec4 _912 = fa_light_texel(param_8);\n        int param_9 = _771 + 3;\n        vec4 _917 = fa_light_texel(param_9);\n        int param_10 = _771 + 4;\n        vec4 _922 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _912.xyz;\n        bool _932 = _917.z > _917.x;\n        if (_932)\n        {\n            vec4 param_11 = _917;\n            vec2 param_12 = _887;\n            vec2 param_13 = _720;\n            vec2 param_14 = _897;\n            vec2 param_15 = _907;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_730 > 0.5) && (_730 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _958 = fa_dc_to_linear(param_16);\n                vec4 _2650 = tx;\n                _2650.x = _958.x;\n                _2650.y = _958.y;\n                _2650.z = _958.z;\n                tx = _2650;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_879 * tex_a) * _912.w, 0.0, 1.0)));\n        if (_922.z > _922.x)\n        {\n            vec4 param_17 = _922;\n            vec2 param_18 = _887;\n            vec2 param_19 = _720;\n            vec2 param_20 = _897;\n            vec2 param_21 = _907;\n            vec4 _1002 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_730 > 1.5)\n            {\n                vec3 param_22 = _1002.xyz;\n                vec3 _1012 = fa_dc_to_srgb(param_22);\n                _1006 = _1012;\n            }\n            else\n            {\n                _1006 = _1002.xyz;\n            }\n            vec3 _1022 = (_1006 * 2.0) - vec3(1.0);\n            vec2 _1027 = _1022.xy * _776.y;\n            vec3 _1049 = (normalize(_804) * _1027.x) + (normalize(_811) * _1027.y);\n            vec3 _1052 = normalize(normal);\n            normal = normalize(mix(_1052, normalize((_1052 * max(_1022.z, 0.0500000007450580596923828125)) + (_1049 - (_1052 * dot(_1052, _1049)))), vec3(clamp(_879 * (_932 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_irr_tex_fa_env_smp, n, 0.0).xyz;\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    return vec3(0.0, ambientColor.y, 0.0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    int param = li * 4;\n    vec4 _267 = fa_light_texel(param);\n    int param_1 = (li * 4) + 1;\n    vec4 _273 = fa_light_texel(param_1);\n    float _276 = _273.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _283 = _276 < 0.5;\n    vec3 l;\n    if (_283)\n    {\n        l = normalize(_267.xyz);\n    }\n    else\n    {\n        vec3 _295 = _267.xyz - world_pos;\n        float _297 = length(_295);\n        dist = _297;\n        l = _295 / vec3(max(_297, 9.9999997473787516355514526367188e-05));\n        float _312 = _297 / max(_267.w, 0.001000000047497451305389404296875);\n        float _318 = clamp(1.0 - (_312 * _312), 0.0, 1.0);\n        atten = _318 * _318;\n        if (_276 > 1.5)\n        {\n            int param_2 = (li * 4) + 2;\n            vec4 _332 = fa_light_texel(param_2);\n            float _342 = _332.w;\n            int param_3 = (li * 4) + 3;\n            vec4 _349 = fa_light_texel(param_3);\n            float _350 = _349.x;\n            float cos_inner = _350;\n            if (_350 > 1.5)\n            {\n                cos_inner = mix(_342, 1.0, 0.25);\n            }\n            atten *= smoothstep(_342, cos_inner, dot(-l, normalize(_332.xyz)));\n        }\n    }\n    int _380;\n    if (_283)\n    {\n        _380 = 0;\n    }\n    else\n    {\n        _380 = (_276 > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, _273.xyz * atten, atten, 1.0, dist, _380);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _1124;\n    if (i == 0)\n    {\n        _1124 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _1140;\n        if (i == 1)\n        {\n            _1140 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _1148;\n            if (i == 2)\n            {\n                _1148 = fa_shadows[24].z;\n            }\n            else\n            {\n                _1148 = fa_shadows[24].w;\n            }\n            _1140 = _1148;\n        }\n        _1124 = _1140;\n    }\n    return _1124;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _1112 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_1112), sin(_1112)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _1186 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _1191 = clamp(dot(n, l), 0.0, 1.0);\n    float _1197 = sqrt(1.0 - (_1191 * _1191));\n    float _1204 = min(_1197 / max(_1191, 0.20000000298023223876953125), 4.0);\n    float _1209;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _1209 = fa_shadows[26].y;\n    }\n    else\n    {\n        _1209 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _1234 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_1209 * _1197)), 1.0);\n    float _1241 = _1234.x;\n    bool _1244 = _1241 < fa_shadows[ci * 1 + 16].x;\n    bool _1253;\n    if (!_1244)\n    {\n        _1253 = _1241 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _1253 = _1244;\n    }\n    bool _1262;\n    if (!_1253)\n    {\n        _1262 = _1234.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _1262 = _1253;\n    }\n    bool _1271;\n    if (!_1262)\n    {\n        _1271 = _1234.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _1271 = _1262;\n    }\n    bool _1278;\n    if (!_1271)\n    {\n        _1278 = _1234.z > 1.0;\n    }\n    else\n    {\n        _1278 = _1271;\n    }\n    if (_1278)\n    {\n        return -1.0;\n    }\n    float _1287;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _1287 = fa_shadows[26].x;\n    }\n    else\n    {\n        _1287 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _1306 = _1234.z - ((_1287 * (1.0 + (0.5 * _1204))) / _1186);\n    float _1315 = ((fa_shadows[ci * 1 + 20].x * min(_1204, 3.0)) * 0.5) / _1186;\n    int _1324 = int(fa_shadows[25].z + 0.5);\n    if (_1324 == 1)\n    {\n        vec2 param = _1234.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _1335 = fa_shadow_depth(param, param_1);\n        return float(_1306 <= _1335);\n    }\n    float _1342 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _1345 = _1324 == 2;\n    if (_1345)\n    {\n        float _1359 = clamp(((fa_shadows[25].w * _1186) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _1342;\n            vec2 _1378 = fa_shadow_vogel(param_2, param_3, param_4) * _1359;\n            vec2 param_5 = _1234.xy + (_1378 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _1389 = fa_shadow_depth(param_5, param_6);\n            if (_1389 < (_1306 - (length(_1378) * _1315)))\n            {\n                sum += _1389;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_1306 - (sum / cnt), 0.0) * _1186) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _1433 = _1345 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _1433; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _1433;\n        float param_9 = _1342;\n        vec2 _1452 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _1234.xy + (_1452 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _1463 = fa_shadow_depth(param_10, param_11);\n        lit += float((_1306 - (length(_1452) * _1315)) <= _1463);\n    }\n    return lit / float(_1433);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _1493 = int(fa_shadows[25].x + 0.5);\n    if (_1493 < 1)\n    {\n        return 1.0;\n    }\n    float _1508 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _1493 - 1;\n    if (_1508 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _1520 = _1493 > 1;\n    bool _1527;\n    if (_1520)\n    {\n        _1527 = _1508 > fa_shadows[24].x;\n    }\n    else\n    {\n        _1527 = _1520;\n    }\n    if (_1527)\n    {\n        ci = 1;\n    }\n    bool _1531 = _1493 > 2;\n    bool _1538;\n    if (_1531)\n    {\n        _1538 = _1508 > fa_shadows[24].y;\n    }\n    else\n    {\n        _1538 = _1531;\n    }\n    if (_1538)\n    {\n        ci = 2;\n    }\n    bool _1542 = _1493 > 3;\n    bool _1549;\n    if (_1542)\n    {\n        _1549 = _1508 > fa_shadows[24].z;\n    }\n    else\n    {\n        _1549 = _1542;\n    }\n    if (_1549)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _1493)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _1575 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _1575;\n        if (_1575 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _1600;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _1600 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _1600 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _1619 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _1600, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _1630 = clamp((_1508 - (fa_shadow_split_at(param_7) - _1619)) / _1619, 0.0, 1.0);\n        if (_1630 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _1493)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _1651 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _1651;\n                if (_1651 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _1630);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _1820 = fa_light_sample(param, param_1);\n    vec3 _2597 = _1820.direction;\n    vec3 _2592 = _1820.color;\n    float _2594 = _1820.shadow;\n    int _2602 = _1820.type;\n    if ((_2602 == 0) && (li == 0))\n    {\n        vec3 param_2 = gn;\n        vec3 param_3 = _2597;\n        float _1834 = fa_shadow_factor(param_2, param_3);\n        _2594 = _1834;\n        _2592 *= _1834;\n    }\n    return LightSample(_2597, _2592, _1820.attenuation, _2594, _1820._distance, _2602);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _1675 = int(fa_shadows[25].x + 0.5);\n    float _1685 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _1690 = _1675 > 0;\n    bool _1699;\n    if (_1690)\n    {\n        int param = _1675 - 1;\n        _1699 = _1685 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _1699 = _1690;\n    }\n    if (_1699)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _1706 = _1675 > 1;\n        bool _1713;\n        if (_1706)\n        {\n            _1713 = _1685 > fa_shadows[24].x;\n        }\n        else\n        {\n            _1713 = _1706;\n        }\n        if (_1713)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _1719 = _1675 > 2;\n        bool _1726;\n        if (_1719)\n        {\n            _1726 = _1685 > fa_shadows[24].y;\n        }\n        else\n        {\n            _1726 = _1719;\n        }\n        if (_1726)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _1732 = _1675 > 3;\n        bool _1739;\n        if (_1732)\n        {\n            _1739 = _1685 > fa_shadows[24].z;\n        }\n        else\n        {\n            _1739 = _1732;\n        }\n        if (_1739)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _2475 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _2475 = -_2475;\n    }\n    vec3 _2119 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing);\n    Surface _2127 = fa_standard_surface(param_1);\n    vec3 _2514 = _2127.albedo;\n    float _2515 = _2127.alpha;\n    vec3 _2516 = _2127.normal;\n    float _2517 = _2127.metallic;\n    float _2518 = _2127.roughness;\n    float _2519 = _2127.occlusion;\n    vec3 _2520 = _2127.emission;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing);\n    Surface param_3 = _2127;\n    surface(param_2, param_3);\n    _2514 = param_3.albedo;\n    _2515 = param_3.alpha;\n    _2516 = param_3.normal;\n    _2517 = param_3.metallic;\n    _2518 = param_3.roughness;\n    _2519 = param_3.occlusion;\n    _2520 = param_3.emission;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _2475;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _2514 = param_6;\n    _2516 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _2514;\n    }\n    else\n    {\n        vec3 _2165 = _2516;\n        vec3 _2166 = normalize(_2165);\n        _2516 = _2166;\n        vec3 param_8 = _2166;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing);\n        Surface param_10 = Surface(_2514, _2515, _2516, _2517, _2518, _2519, _2520);\n        vec3 param_11 = fa_ambient_light(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _2185 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _2185; ln++)\n        {\n            int param_12 = ln;\n            int param_13 = fa_cl_light(param_12);\n            vec3 param_14 = fa_world_pos;\n            vec3 param_15 = _2475;\n            SurfaceInput param_16 = SurfaceInput(fa_world_pos, _2475, fa_world_tangent, fa_uv, fa_vertex_color, _2119, gl_FrontFacing);\n            Surface param_17 = Surface(_2514, _2515, _2516, _2517, _2518, _2519, _2520);\n            LightSample param_18 = fa_light_shadowed(param_13, param_14, param_15);\n            lit += light(param_16, param_17, param_18);\n        }\n        result = lit;\n    }\n    vec3 _2222 = result;\n    vec3 _2223 = _2222 + _2520;\n    result = _2223;\n    vec3 param_19 = _2223;\n    vec3 param_20 = fa_world_pos;\n    result = fa_shadow_debug(param_19, param_20);\n    bool _2232 = fa_mesh_fs_params[7].w > 0.0;\n    bool _2240;\n    if (!_2232)\n    {\n        _2240 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _2240 = _2232;\n    }\n    if (_2240)\n    {\n        vec3 _2249 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _2256 = dot(_2249, fa_mesh_fs_params[9].xyz);\n        bool _2260 = fa_mesh_fs_params[9].w > 0.5;\n        float _2261;\n        if (_2260)\n        {\n            _2261 = _2256;\n        }\n        else\n        {\n            _2261 = length(_2249);\n        }\n        float _2273 = _2261 - fa_mesh_fs_params[8].x;\n        if (_2273 > 0.0)\n        {\n            float _2282 = fa_mesh_fs_params[7].w * _2273;\n            float tau = _2282 * _2282;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _2298;\n                if (_2260)\n                {\n                    _2298 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _2256);\n                }\n                else\n                {\n                    _2298 = fa_mesh_fs_params[0].y;\n                }\n                float _2319 = mix(_2298, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _2261, 0.0, 1.0));\n                float _2323 = fa_world_pos.y - _2319;\n                float _2328 = _2319 - fa_mesh_fs_params[8].z;\n                float _2333 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _2336 = _2328 <= 0.0;\n                bool _2337 = !_2336;\n                bool _2343;\n                if (_2337)\n                {\n                    _2343 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2343 = _2336;\n                }\n                float _2344;\n                if (_2343)\n                {\n                    _2344 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _2344 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _2328, 80.0));\n                }\n                bool _2371;\n                if (_2337)\n                {\n                    _2371 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2371 = _2336;\n                }\n                float _2372;\n                if (_2371)\n                {\n                    _2372 = fa_mesh_fs_params[8].y * _2328;\n                }\n                else\n                {\n                    _2372 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2328, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _2397 = _2333 <= 0.0;\n                bool _2404;\n                if (!_2397)\n                {\n                    _2404 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _2404 = _2397;\n                }\n                float _2405;\n                if (_2404)\n                {\n                    _2405 = fa_mesh_fs_params[8].y * _2333;\n                }\n                else\n                {\n                    _2405 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _2333, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _2432;\n                if (abs(_2323) < 0.001000000047497451305389404296875)\n                {\n                    _2432 = _2344;\n                }\n                else\n                {\n                    _2432 = (_2405 - _2372) / _2323;\n                }\n                tau += (_2273 * max(_2432, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _2515);\n}\n\n",
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
            "inst_name": "_394",
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
            "inst_name": "_1134",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 29,
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
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
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
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    vec4 _241 = (_588 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _569 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _569, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_213",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[10];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n};\n\nuniform vec4 fa_mesh_fs_params[20];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _225 = fa_tex_fix(param_2, param_3);\n    vec4 _588 = base_t;\n    _588.x = _225.x;\n    _588.y = _225.y;\n    _588.z = _225.z;\n    base_t = _588;\n    vec4 _241 = (_588 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _569 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _275 = fa_tex_fix(param_6, param_7);\n        vec3 _279 = (_275 * 2.0) - vec3(1.0);\n        vec2 _284 = _279.xy * fa_mesh_fs_params[6].x;\n        vec3 _596 = _279;\n        _596.x = _284.x;\n        _596.y = _284.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _596;\n        _569 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _313 = fa_tex_fix(param_12, param_13);\n    vec4 _599 = mrt;\n    _599.x = _313.x;\n    _599.y = _313.y;\n    _599.z = _313.z;\n    mrt = _599;\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = texture(fa_occlusion_tex_fa_smp, i.uv).xxx;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _354 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _381 = fa_tex_fix(param_20, param_21);\n    return Surface(_241.xyz, _241.w, _569, clamp(fa_mesh_fs_params[5].x * _313.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _313.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_354.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _381));\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _516 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _516 = -_516;\n    }\n    vec3 _427 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _516, fa_world_tangent, fa_uv, fa_vertex_color, _427, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _442 = normalize(param_2.normal);\n    vec3 _457 = normalize(vec3(dot(fa_pre_r0, _442), dot(fa_pre_r1, _442), dot(fa_pre_r2, _442)));\n    float _469 = _457.z;\n    vec2 e = _457.xy / vec2((abs(_457.x) + abs(_457.y)) + abs(_469));\n    if (_469 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_213",
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
