{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "e0c1f830a27b422ba9d050f4a118de89d0d8c6a78e3cc09d7dad74ea546b40a2",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4355[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1404 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1411;\n    if (!_1404)\n    {\n        _1411 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1411 = _1404;\n    }\n    bool _1419;\n    if (!_1411)\n    {\n        _1419 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1419 = _1411;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    bool _1433;\n    if (!_1426)\n    {\n        _1433 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1433 = _1426;\n    }\n    if (_1433)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1443 = vec4(world_pos, 1.0);\n    float _1449 = dot(fa_mesh_fs_params[16], _1443);\n    if (!(_1449 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1471 = vec2(dot(fa_mesh_fs_params[14], _1443), dot(fa_mesh_fs_params[15], _1443)) / vec2(_1449);\n    int _1475 = int(fa_mesh_fs_params[18].x);\n    int _1479 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1479) + clamp(int(floor(((_1471.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1479 - 1)) * _1475)) + clamp(int(floor(((_1471.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1475 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1555 = fa_cluster_texel(param);\n    return ivec2(int(_1555.x), int(_1555.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5181 = fa_cluster_lookup(param);\n    fa_cl_slot = _5181.x;\n    fa_cl_local = _5181.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5557 = fa_linear_to_srgb(param);\n        c = _5557;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5565 = fa_srgb_to_linear(param_1);\n            c = _5565;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _355;\n    if (i.front_facing)\n    {\n        _355 = i.world_normal;\n    }\n    else\n    {\n        _355 = -i.world_normal;\n    }\n    vec3 _379 = normalize(i.world_tangent.xyz - (_355 * dot(_355, i.world_tangent.xyz)));\n    vec3 _407 = normalize(((_379 * m.x) + ((cross(_355, _379) * i.world_tangent.w) * m.y)) + (_355 * m.z));\n    vec3 _410;\n    if (i.front_facing)\n    {\n        _410 = _407;\n    }\n    else\n    {\n        _410 = -_407;\n    }\n    return _410;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5597 = fa_tex_fix(param_2, param_3);\n    vec4 _6765 = base_t;\n    _6765.x = _5597.x;\n    _6765.y = _5597.y;\n    _6765.z = _5597.z;\n    base_t = _6765;\n    vec4 _5611 = (_6765 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6550 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5645 = fa_tex_fix(param_6, param_7);\n        vec3 _5648 = (_5645 * 2.0) - vec3(1.0);\n        vec2 _5653 = _5648.xy * fa_mesh_fs_params[6].x;\n        vec3 _6773 = _5648;\n        _6773.x = _5653.x;\n        _6773.y = _5653.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6773;\n        _6550 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5683 = fa_tex_fix(param_12, param_13);\n    vec4 _6776 = mrt;\n    _6776.x = _5683.x;\n    _6776.y = _5683.y;\n    _6776.z = _5683.z;\n    mrt = _6776;\n    vec4 _5713 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5713.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5724 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5756 = fa_tex_fix(param_20, param_21);\n    float _6555 = fa_mesh_fs_params[20].x;\n    float _6556 = fa_mesh_fs_params[20].y;\n    float _6559 = fa_mesh_fs_params[20].z;\n    float _6558 = fa_mesh_fs_params[21].w;\n    float _6561 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6555 *= _5724.y;\n            _6556 *= _5724.z;\n            _6558 *= _5713.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6559 *= mrt.x;\n            _6561 *= mrt.w;\n        }\n    }\n    return Surface(_5611.xyz, _5611.w, _6550, clamp(fa_mesh_fs_params[5].x * _5683.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5683.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5724.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5756), _6555, _6556, fa_mesh_fs_params[21].xyz, _6558, _6559, fa_mesh_fs_params[20].w, _6561, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1635 = rect.zw - rect.xy;\n    vec2 _1639 = _1635 * atlas;\n    vec2 _1643 = ddx * _1639;\n    vec2 _1647 = ddy * _1639;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1635), clamp(0.5 * log2(max(max(dot(_1643, _1643), dot(_1647, _1647)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1680 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1687;\n    if (!_1680)\n    {\n        _1687 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1687 = _1680;\n    }\n    if (_1687)\n    {\n        return;\n    }\n    vec3 _1693 = dFdx(world_pos);\n    vec3 _1696 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1700 = fa_cluster_texel(param);\n    int _1704 = int(_1700.w);\n    if (_1704 < 1)\n    {\n        return;\n    }\n    int _1714 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1714;\n    vec4 _1718 = fa_light_texel(param_1);\n    vec2 _1721 = _1718.yz;\n    int _1725 = int(_1718.w);\n    int param_2 = _1714 + 1;\n    vec4 _1730 = fa_light_texel(param_2);\n    float _1731 = _1730.x;\n    int _1737 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1741 = int(_1700.z);\n    vec3 _2006;\n    for (int k = 0; k < _1704; k++)\n    {\n        int _1754 = _1741 + k;\n        int param_3 = _1725 + (_1754 >> 2);\n        int _1771 = (_1714 + 2) + (int(fa_light_texel(param_3)[_1754 & 3]) * 7);\n        int param_4 = _1771 + 6;\n        vec4 _1776 = fa_light_texel(param_4);\n        if (((int(_1776.w + 0.5) >> _1737) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1771;\n        vec4 _1791 = fa_light_texel(param_5);\n        int param_6 = _1771 + 1;\n        vec4 _1796 = fa_light_texel(param_6);\n        int param_7 = _1771 + 2;\n        vec4 _1801 = fa_light_texel(param_7);\n        vec3 _1804 = _1791.xyz;\n        float _1809 = dot(_1804, world_pos) + _1791.w;\n        vec3 _1811 = _1796.xyz;\n        float _1816 = dot(_1811, world_pos) + _1796.w;\n        vec3 _1818 = _1801.xyz;\n        float _1823 = dot(_1818, world_pos) + _1801.w;\n        bool _1828 = abs(_1809) > 0.5;\n        bool _1836;\n        if (!_1828)\n        {\n            _1836 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1836 = _1828;\n        }\n        bool _1844;\n        if (!_1836)\n        {\n            _1844 = abs(_1823) > 0.5;\n        }\n        else\n        {\n            _1844 = _1836;\n        }\n        if (_1844)\n        {\n            continue;\n        }\n        float _1859 = clamp(dot(geo_normal, normalize(_1818)) * _1776.z, 0.0, 1.0);\n        if (_1859 <= 0.0)\n        {\n            continue;\n        }\n        float _1879 = (clamp((0.5 - abs(_1823)) * 10.0, 0.0, 1.0) * _1859) * _1776.x;\n        vec2 _1887 = vec2(_1809 + 0.5, 0.5 - _1816);\n        vec2 _1897 = vec2(dot(_1804, _1693), dot(_1811, _1693));\n        vec2 _1907 = vec2(dot(_1804, _1696), dot(_1811, _1696));\n        int param_8 = _1771 + 5;\n        vec4 _1912 = fa_light_texel(param_8);\n        int param_9 = _1771 + 3;\n        vec4 _1917 = fa_light_texel(param_9);\n        int param_10 = _1771 + 4;\n        vec4 _1922 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1912.xyz;\n        bool _1932 = _1917.z > _1917.x;\n        if (_1932)\n        {\n            vec4 param_11 = _1917;\n            vec2 param_12 = _1887;\n            vec2 param_13 = _1721;\n            vec2 param_14 = _1897;\n            vec2 param_15 = _1907;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1731 > 0.5) && (_1731 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1958 = fa_dc_to_linear(param_16);\n                vec4 _6638 = tx;\n                _6638.x = _1958.x;\n                _6638.y = _1958.y;\n                _6638.z = _1958.z;\n                tx = _6638;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1879 * tex_a) * _1912.w, 0.0, 1.0)));\n        if (_1922.z > _1922.x)\n        {\n            vec4 param_17 = _1922;\n            vec2 param_18 = _1887;\n            vec2 param_19 = _1721;\n            vec2 param_20 = _1897;\n            vec2 param_21 = _1907;\n            vec4 _2002 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1731 > 1.5)\n            {\n                vec3 param_22 = _2002.xyz;\n                vec3 _2012 = fa_dc_to_srgb(param_22);\n                _2006 = _2012;\n            }\n            else\n            {\n                _2006 = _2002.xyz;\n            }\n            vec3 _2021 = (_2006 * 2.0) - vec3(1.0);\n            vec2 _2026 = _2021.xy * _1776.y;\n            vec3 _2048 = (normalize(_1804) * _2026.x) + (normalize(_1811) * _2026.y);\n            vec3 _2051 = normalize(normal);\n            normal = normalize(mix(_2051, normalize((_2051 * max(_2021.z, 0.0500000007450580596923828125)) + (_2048 - (_2051 * dot(_2051, _2048)))), vec3(clamp(_1879 * (_1932 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5151;\n    if (fa_lm.z > 0.5)\n    {\n        _5151 = 0.0;\n    }\n    else\n    {\n        _5151 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5162 = _5151 < 1.0;\n    bool _5168;\n    if (_5162)\n    {\n        int param = li;\n        _5168 = fa_light_baked(param);\n    }\n    else\n    {\n        _5168 = _5162;\n    }\n    return _5168 ? _5151 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _653 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _666 = (c - (ru * hx)) - p;\n        vec3 _672 = ru * (2.0 * hx);\n        float _678 = max(dot(_672, _672), 9.9999999392252902907785028219223e-09);\n        float _682 = dot(_666, _672);\n        float t = clamp((-_682) / _678, 0.0, 1.0);\n        if (_653)\n        {\n            float _697 = dot(r, _672);\n            float _703 = _678 - (_697 * _697);\n            if (abs(_703) > (9.9999997473787516355514526367188e-06 * _678))\n            {\n                t = clamp(((dot(r, _666) * _697) - _682) / _703, 0.0, 1.0);\n            }\n        }\n        return (p + _666) + (_672 * t);\n    }\n    vec3 q = p;\n    float _735 = dot(r, axis);\n    bool _743;\n    if (_653)\n    {\n        _743 = abs(_735) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _743 = _653;\n    }\n    if (_743)\n    {\n        float _753 = dot(c - p, axis) / _735;\n        if (_753 > 0.0)\n        {\n            q = p + (r * _753);\n        }\n    }\n    vec3 _766 = q - c;\n    vec2 xy = vec2(dot(_766, ru), dot(_766, uu));\n    if (shape > 0.5)\n    {\n        float _781 = length(xy);\n        if (_781 > hx)\n        {\n            xy *= (hx / _781);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _573 = dot(d, right);\n    float _577 = dot(d, up);\n    float _588;\n    if (((_573 * _573) + (_577 * _577)) > 1.0000000133514319600180897396058e-10)\n    {\n        _588 = atan(_577, _573) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _588 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_588 - floor(_588)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _422 = abs(d);\n    float _424 = _422.x;\n    float _426 = _422.y;\n    bool _427 = _424 >= _426;\n    bool _435;\n    if (_427)\n    {\n        _435 = _424 >= _422.z;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    int _436;\n    if (_435)\n    {\n        _436 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _451;\n        if (_426 >= _422.z)\n        {\n            _451 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _451 = (d.z > 0.0) ? 4 : 5;\n        }\n        _436 = _451;\n    }\n    return _436;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _819 = fa_light_base(param);\n    bool _823 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _819;\n    vec4 _827 = fa_light_texel(param_1);\n    int param_2 = _819 + 1;\n    vec4 _832 = fa_light_texel(param_2);\n    float _835 = _832.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _847 = _823 && (_835 > 2.5);\n    fa_light_is_area = _847;\n    bool _849 = _835 < 0.5;\n    vec3 l;\n    if (_849)\n    {\n        l = normalize(_827.xyz);\n        if (_823)\n        {\n            int param_3 = _819 + 6;\n            vec4 _863 = fa_light_texel(param_3);\n            if (_863.z > 0.5)\n            {\n                int param_4 = _819 + 4;\n                vec4 _873 = fa_light_texel(param_4);\n                int param_5 = _819 + 5;\n                vec4 _878 = fa_light_texel(param_5);\n                vec2 param_6 = _863.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _873.xyz) * _873.w, (-dot(world_pos, _878.xyz)) * _878.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _908 = _827.xyz;\n        vec3 _910 = _908 - world_pos;\n        vec3 to_light = _910;\n        float _913 = length(_910);\n        float reach = _913;\n        bool front = true;\n        if (_847)\n        {\n            int param_8 = _819 + 7;\n            reach = max(_913 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _819 + 4;\n            vec4 _937 = fa_light_texel(param_9);\n            int param_10 = _819 + 5;\n            vec4 _942 = fa_light_texel(param_10);\n            int param_11 = _819 + 6;\n            vec4 _947 = fa_light_texel(param_11);\n            float _948 = _947.w;\n            int param_12 = _819 + 2;\n            vec3 _955 = normalize(fa_light_texel(param_12).xyz);\n            bool _957 = _948 > 1.5;\n            bool _965;\n            if (!_957)\n            {\n                _965 = dot(_955, to_light) < 0.0;\n            }\n            else\n            {\n                _965 = _957;\n            }\n            front = _965;\n            vec3 r = vec3(0.0);\n            vec3 _974 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _978 = dot(n, n) > 0.5;\n            bool _986;\n            if (_978)\n            {\n                _986 = dot(_974, _974) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _986 = _978;\n            }\n            if (_986)\n            {\n                r = reflect(-normalize(_974), normalize(n));\n            }\n            vec3 param_13 = _908;\n            vec3 param_14 = _955;\n            vec3 param_15 = _937.xyz;\n            vec3 param_16 = _942.xyz;\n            float param_17 = _937.w;\n            float param_18 = _942.w;\n            float param_19 = _948;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1022 = length(to_light);\n        dist = _1022;\n        l = to_light / vec3(max(_1022, 9.9999997473787516355514526367188e-05));\n        float _1036 = reach / max(_827.w, 0.001000000047497451305389404296875);\n        float _1042 = clamp(1.0 - (_1036 * _1036), 0.0, 1.0);\n        float _1044;\n        if (front)\n        {\n            _1044 = _1042 * _1042;\n        }\n        else\n        {\n            _1044 = 0.0;\n        }\n        atten = _1044;\n        bool _1055 = _835 < 2.5;\n        if ((_835 > 1.5) && _1055)\n        {\n            int param_22 = _819 + 2;\n            vec4 _1063 = fa_light_texel(param_22);\n            float _1073 = _1063.w;\n            int param_23 = _819 + 3;\n            vec4 _1078 = fa_light_texel(param_23);\n            float _1079 = _1078.x;\n            float cos_inner = _1079;\n            if (_1079 > 1.5)\n            {\n                cos_inner = mix(_1073, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1073, cos_inner, dot(-l, normalize(_1063.xyz)));\n        }\n        if (_823 && (_835 < 1.5))\n        {\n            int param_24 = _819 + 6;\n            vec4 _1103 = fa_light_texel(param_24);\n            if (_1103.z > 0.5)\n            {\n                vec3 _1111 = -to_light;\n                int param_25 = _819 + 4;\n                int param_26 = _819 + 5;\n                vec3 _1125 = fa_light_texel(param_25).xyz;\n                vec3 _1129 = fa_light_texel(param_26).xyz;\n                vec3 _1138 = vec3(dot(_1111, _1125), dot(_1111, _1129), dot(_1111, cross(_1125, _1129)));\n                vec3 param_27 = _1138;\n                int _1142 = fa_cube_face(param_27);\n                int param_28 = _1142;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1169 = vec2(dot(_1138, cross(param_29, param_30)), dot(_1138, param_30)) / vec2(max(dot(_1138, param_29), 9.9999997473787516355514526367188e-05));\n                int _1173 = _1142 / 3;\n                vec2 param_31 = _1103.xy + (vec2(float(_1142 - (_1173 * 3)), float(_1173)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1169.x), 0.5 - (0.5 * _1169.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _819 + 7;\n            vec4 _1203 = fa_light_texel(param_33);\n            if (_1203.z > 0.5)\n            {\n                int param_34 = _819 + 2;\n                int param_35 = _819 + 4;\n                int param_36 = _819 + 5;\n                vec2 param_37 = _1203.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_823 && _1055)\n            {\n                int param_42 = _819 + 6;\n                vec4 _1250 = fa_light_texel(param_42);\n                int param_43 = _819 + 7;\n                vec4 _1255 = fa_light_texel(param_43);\n                bool _1258 = _1250.z > 0.5;\n                bool _1265;\n                if (!_1258)\n                {\n                    _1265 = _1255.z > 0.5;\n                }\n                else\n                {\n                    _1265 = _1258;\n                }\n                if (_1265)\n                {\n                    int param_44 = _819 + 2;\n                    vec4 _1272 = fa_light_texel(param_44);\n                    vec3 _1276 = normalize(_1272.xyz);\n                    int param_45 = _819 + 4;\n                    vec4 _1281 = fa_light_texel(param_45);\n                    int param_46 = _819 + 5;\n                    vec4 _1286 = fa_light_texel(param_46);\n                    if (_1258)\n                    {\n                        vec3 _1294 = -to_light;\n                        float _1301 = _1272.w;\n                        float _1317 = 0.5 / max(dot(_1294, _1276) * (sqrt(max(1.0 - (_1301 * _1301), 0.0)) / max(_1301, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1250.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1294, _1281.xyz) * _1317), 0.5 - (dot(_1294, _1286.xyz) * _1317));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1255.z > 0.5)\n                    {\n                        vec2 param_49 = _1255.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1276;\n                        vec3 param_52 = _1281.xyz;\n                        vec3 param_53 = _1286.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6356 = _832.xyz * atten;\n    if (_823)\n    {\n        _6356 *= fa_light_tint;\n    }\n    int _1386;\n    if (_849)\n    {\n        _1386 = 0;\n    }\n    else\n    {\n        _1386 = ((_835 > 1.5) && (_835 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6356, atten, 1.0, dist, _1386);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5380 = n < 0;\n    bool _5387;\n    if (!_5380)\n    {\n        _5387 = n >= fa_light_count();\n    }\n    else\n    {\n        _5387 = _5380;\n    }\n    if (_5387)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5395 = fa_cl_light(param);\n    int param_1 = _5395;\n    float _5399 = fa_baked_keep(param_1);\n    if (_5399 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5395;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5415 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5415.direction, _5415.color * _5399, _5415.attenuation * _5399, _5415.shadow, _5415._distance, _5415.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2175 = fa_shadow_depth(param, param_1);\n    float _2179;\n    if (conv.x < 0.5)\n    {\n        _2179 = _2175;\n    }\n    else\n    {\n        _2179 = (conv.y * conv.z) / (conv.z - (_2175 * (conv.z - conv.y)));\n    }\n    return _2179;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2225 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2231 = vec2(cos(_2225), sin(_2225));\n    vec2 dir = _2231;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2240;\n        if (k < 0.0)\n        {\n            _2240 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2240 = k;\n        }\n        float _2259 = clamp((_2240 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2278 = sqrt((float(i) + 0.5) * 0.0625) * _2259;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2278));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2292 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2292 < (zr - (_2278 * plane)))\n            {\n                sum += _2292;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2320 = sum / cnt;\n        float _2330;\n        if (k < 0.0)\n        {\n            _2330 = (-k) / max(_2320, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2330 = k;\n        }\n        radius = clamp(((max(zr - _2320, 0.0) * unit) * _2330) / texel_m, 1.5, 16.0);\n        dir = _2231;\n    }\n    float lit = 0.0;\n    int _2356 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2356; i_1++)\n    {\n        float _2375 = sqrt((float(i_1) + 0.5) / float(_2356)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2375));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2375 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2356);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2580 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2587;\n    if (!_2580)\n    {\n        _2587 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2587 = _2580;\n    }\n    if (_2587)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2600 = fa_light_texel(param);\n    float _2601 = _2600.x;\n    if (_2601 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2610 = int(_2601 + 0.5);\n    int param_1 = _2610;\n    vec4 _2614 = fa_light_texel(param_1);\n    int param_2 = _2610 + 1;\n    vec4 _2619 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2622 = _2614.y;\n    if (_2622 > 0.0)\n    {\n        float _2639 = 1.0 - smoothstep(0.75 * _2622, _2622, length(world - fa_shadows[27].xyz));\n        fade = _2639;\n        if (_2639 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2614.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2663 = (_2610 + 2) + (face * 6);\n    int param_4 = _2663;\n    int param_5 = _2663 + 1;\n    int param_6 = _2663 + 3;\n    vec4 _2677 = fa_light_texel(param_6);\n    int param_7 = _2663 + 4;\n    vec4 _2682 = fa_light_texel(param_7);\n    int param_8 = _2663 + 5;\n    vec4 _2687 = fa_light_texel(param_8);\n    float _2699 = _2687.x * max(dot(_2677, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2704 = clamp(dot(n, l), 0.0, 1.0);\n    float _2727 = clamp(dot(n, _2677.xyz), -1.0, 1.0);\n    float _2746 = min(sqrt(1.0 - (_2727 * _2727)) / max(abs(dot(n, world - lpos)) / max(dot(_2677, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2749 = _2619.y;\n    float _2751;\n    if (_2749 > 0.0)\n    {\n        _2751 = _2749;\n    }\n    else\n    {\n        _2751 = 1.5 * _2699;\n    }\n    vec4 _2771 = vec4(world + (n * (_2751 * sqrt(1.0 - (_2704 * _2704)))), 1.0);\n    float _2775 = dot(_2677, _2771);\n    float _2778 = _2687.y;\n    if (_2775 < _2778)\n    {\n        return 1.0;\n    }\n    vec2 _2793 = vec2(dot(fa_light_texel(param_4), _2771), dot(fa_light_texel(param_5), _2771)) / vec2(_2775);\n    float _2795 = _2793.x;\n    bool _2798 = _2795 < _2682.x;\n    bool _2807;\n    if (!_2798)\n    {\n        _2807 = _2795 > _2682.z;\n    }\n    else\n    {\n        _2807 = _2798;\n    }\n    bool _2816;\n    if (!_2807)\n    {\n        _2816 = _2793.y < _2682.y;\n    }\n    else\n    {\n        _2816 = _2807;\n    }\n    bool _2825;\n    if (!_2816)\n    {\n        _2825 = _2793.y > _2682.w;\n    }\n    else\n    {\n        _2825 = _2816;\n    }\n    if (_2825)\n    {\n        return 1.0;\n    }\n    float _2831 = _2619.x;\n    float _2833;\n    if (_2831 > 0.0)\n    {\n        _2833 = _2831;\n    }\n    else\n    {\n        _2833 = 1.5 * _2699;\n    }\n    vec2 param_9 = _2793;\n    vec4 param_10 = _2682;\n    float param_11 = _2775 - (_2833 * (1.0 + (0.5 * _2746)));\n    float param_12 = _2699;\n    float param_13 = 1.0;\n    float param_14 = _2687.z * 0.25;\n    float param_15 = (_2699 * min(_2746, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2778, _2687.z);\n    int param_17 = int(_2614.z + 0.5);\n    float param_18 = _2614.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3345 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3351;\n    if (_3345)\n    {\n        _3351 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3351 = _3345;\n    }\n    bool _3357;\n    if (_3351)\n    {\n        _3357 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3357 = _3351;\n    }\n    if (_3357)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3369 = fa_light_texel(param);\n        float _3370 = _3369.z;\n        if (_3370 > 0.5)\n        {\n            float _3383 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3386 = fwidth(_3383);\n            float _3390 = min(1.5 * _3386, 0.100000001490116119384765625 * _3383);\n            vec4 _3396 = vec4(world, 1.0);\n            float _3401 = dot(fa_mesh_fs_params[28], _3396);\n            if (_3401 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3418 = vec2(dot(fa_mesh_fs_params[26], _3396), dot(fa_mesh_fs_params[27], _3396)) / vec2(_3401);\n                float _3423 = (_3418.x * 0.5) + 0.5;\n                float _3427;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3427 = (_3418.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3427 = 0.5 - (_3418.y * 0.5);\n                }\n                bool _3443 = _3423 >= 0.0;\n                bool _3449;\n                if (_3443)\n                {\n                    _3449 = _3423 < 1.0;\n                }\n                else\n                {\n                    _3449 = _3443;\n                }\n                bool _3455;\n                if (_3449)\n                {\n                    _3455 = _3427 >= 0.0;\n                }\n                else\n                {\n                    _3455 = _3449;\n                }\n                bool _3461;\n                if (_3455)\n                {\n                    _3461 = _3427 < 1.0;\n                }\n                else\n                {\n                    _3461 = _3455;\n                }\n                if (_3461)\n                {\n                    ivec2 _3478 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3479 = clamp(ivec2(vec2(_3423, _3427) * fa_mesh_fs_params[24].zw), ivec2(0), _3478);\n                    ivec2 _3491;\n                    ivec2 _3497;\n                    ivec2 _3504;\n                    float _3555;\n                    float _3576;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3491 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3497 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3504 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3515 = bvec2(k == 3);\n                                    _3504 = ivec2(_3515.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3515.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3497 = _3504;\n                            }\n                            _3491 = _3497;\n                        }\n                        vec4 _3532 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3479 + _3491, ivec2(0), _3478), 0);\n                        bool _3535 = _3532.w > 0.5;\n                        bool _3549;\n                        if (_3535)\n                        {\n                            _3549 = abs(_3383 - _3532.x) <= (((0.00200000009499490261077880859375 * _3383) + 0.00999999977648258209228515625) + _3390);\n                        }\n                        else\n                        {\n                            _3549 = _3535;\n                        }\n                        if (_3549)\n                        {\n                            if (_3370 < 1.5)\n                            {\n                                _3555 = 1.0;\n                            }\n                            else\n                            {\n                                _3555 = (_3370 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3572 = mod(floor(_3532.z / _3555), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3576 = min(_3572, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3576 = _3572;\n                            }\n                            return _3576;\n                        }\n                    }\n                }\n            }\n            float _3601;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3601 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3601 = 1.0;\n            }\n            return _3601;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2118;\n    if (i == 0)\n    {\n        _2118 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2134;\n        if (i == 1)\n        {\n            _2134 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2142;\n            if (i == 2)\n            {\n                _2142 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2142 = fa_shadows[24].w;\n            }\n            _2134 = _2142;\n        }\n        _2118 = _2134;\n    }\n    return _2118;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2421 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2426 = clamp(dot(n, l), 0.0, 1.0);\n    float _2432 = sqrt(1.0 - (_2426 * _2426));\n    float _2440 = min(_2432 / max(_2426, 0.20000000298023223876953125), 4.0);\n    float _2445;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2445 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2445 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2470 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2445 * _2432)), 1.0);\n    float _2477 = _2470.x;\n    bool _2480 = _2477 < fa_shadows[ci * 1 + 16].x;\n    bool _2489;\n    if (!_2480)\n    {\n        _2489 = _2477 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2489 = _2480;\n    }\n    bool _2498;\n    if (!_2489)\n    {\n        _2498 = _2470.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2498 = _2489;\n    }\n    bool _2507;\n    if (!_2498)\n    {\n        _2507 = _2470.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2507 = _2498;\n    }\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = _2470.z > 1.0;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return -1.0;\n    }\n    float _2522;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2522 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2522 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2470.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2470.z - ((_2522 * (1.0 + (0.5 * _2440))) / _2421);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2421;\n    float param_5 = _2421 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2440, 3.0)) * 0.5) / _2421;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2900 = int(fa_shadows[25].x + 0.5);\n    if (_2900 < 1)\n    {\n        return 1.0;\n    }\n    float _2915 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2900 - 1;\n    if (_2915 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2927 = _2900 > 1;\n    bool _2934;\n    if (_2927)\n    {\n        _2934 = _2915 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2934 = _2927;\n    }\n    if (_2934)\n    {\n        ci = 1;\n    }\n    bool _2938 = _2900 > 2;\n    bool _2945;\n    if (_2938)\n    {\n        _2945 = _2915 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2945 = _2938;\n    }\n    if (_2945)\n    {\n        ci = 2;\n    }\n    bool _2949 = _2900 > 3;\n    bool _2956;\n    if (_2949)\n    {\n        _2956 = _2915 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2956 = _2949;\n    }\n    if (_2956)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2967 = min(_2900, 4);\n    float _3008;\n    for (int c = ci; c < _2967; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2987 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2987;\n            break;\n        }\n        if (_2987 < 0.0)\n        {\n            continue;\n        }\n        s = _2987;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3008 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3008 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3027 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3008, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2915 - (fa_shadow_split_at(param_7) - _3027)) / _3027, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3059;\n        if ((ci + 1) < _2900)\n        {\n            _3059 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3059 = 1.0;\n        }\n        s = mix(s, _3059, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3164 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3170;\n    if (_3164)\n    {\n        _3170 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3170 = _3164;\n    }\n    if (_3170)\n    {\n        float _3184 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3187 = fwidth(_3184);\n        vec4 _3197 = vec4(fa_world_pos, 1.0);\n        float _3203 = dot(fa_mesh_fs_params[28], _3197);\n        if (_3203 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3222 = vec2(dot(fa_mesh_fs_params[26], _3197), dot(fa_mesh_fs_params[27], _3197)) / vec2(_3203);\n            float _3227 = (_3222.x * 0.5) + 0.5;\n            float _3231;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3231 = (_3222.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3231 = 0.5 - (_3222.y * 0.5);\n            }\n            bool _3247 = _3227 >= 0.0;\n            bool _3253;\n            if (_3247)\n            {\n                _3253 = _3227 < 1.0;\n            }\n            else\n            {\n                _3253 = _3247;\n            }\n            bool _3259;\n            if (_3253)\n            {\n                _3259 = _3231 >= 0.0;\n            }\n            else\n            {\n                _3259 = _3253;\n            }\n            bool _3265;\n            if (_3259)\n            {\n                _3265 = _3231 < 1.0;\n            }\n            else\n            {\n                _3265 = _3259;\n            }\n            if (_3265)\n            {\n                vec4 _3291 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3227, _3231) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3294 = _3291.w > 0.5;\n                bool _3310;\n                if (_3294)\n                {\n                    _3310 = abs(_3184 - _3291.x) <= (((0.00200000009499490261077880859375 * _3184) + 0.00999999977648258209228515625) + min(1.5 * _3187, 0.100000001490116119384765625 * _3184));\n                }\n                else\n                {\n                    _3310 = _3294;\n                }\n                if (_3310)\n                {\n                    float _3316;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3316 = min(_3291.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3316 = _3291.y;\n                    }\n                    return _3316;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4895 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4902;\n    if (!_4895)\n    {\n        _4902 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4902 = _4895;\n    }\n    if (_4902)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4915 = fa_light_texel(param);\n    float _4916 = _4915.y;\n    float len = _4916;\n    if (_4916 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4928 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4937 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4928);\n    if (_4937 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4943 = len;\n    float _4946 = min(_4943, 0.89999997615814208984375 * dist);\n    len = _4946;\n    float _4951 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4928);\n    float _4956 = _4951 + (0.5 * _4946);\n    vec3 _4962 = world + (gn * _4951);\n    float _4964 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5025;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4979 = (float(k) + _4964) * 0.083333335816860198974609375;\n        vec3 _4987 = _4962 + (l * (_4979 * len));\n        vec4 _4993 = vec4(_4987, 1.0);\n        float _4998 = dot(fa_mesh_fs_params[28], _4993);\n        if (_4998 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5016 = vec2(dot(fa_mesh_fs_params[26], _4993), dot(fa_mesh_fs_params[27], _4993)) / vec2(_4998);\n        float _5020 = _5016.x * 0.5;\n        float _5021 = _5020 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5025 = (_5016.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5025 = 0.5 - (_5016.y * 0.5);\n        }\n        bool _5041 = _5021 < 0.0;\n        bool _5048;\n        if (!_5041)\n        {\n            _5048 = _5021 >= 1.0;\n        }\n        else\n        {\n            _5048 = _5041;\n        }\n        bool _5055;\n        if (!_5048)\n        {\n            _5055 = _5025 < 0.0;\n        }\n        else\n        {\n            _5055 = _5048;\n        }\n        bool _5062;\n        if (!_5055)\n        {\n            _5062 = _5025 >= 1.0;\n        }\n        else\n        {\n            _5062 = _5055;\n        }\n        if (_5062)\n        {\n            break;\n        }\n        vec4 _5086 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5021, _5025) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5086.w < 0.5)\n        {\n            continue;\n        }\n        float _5104 = (dot(fa_mesh_fs_params[29].xyz, _4987) + fa_mesh_fs_params[29].w) - _5086.x;\n        if ((_5104 > _4951) && (_5104 < _4956))\n        {\n            occ = max(occ, (1.0 - (_4979 * _4979)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5021, 0.5 - _5020), min(_5025, 1.0 - _5025))));\n        }\n    }\n    return 1.0 - (occ * _4937);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5207 = fa_baked_keep(param);\n    if (_5207 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5233 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6502 = _5233.color;\n    float _6503 = _5233.attenuation;\n    float _6504 = _5233.shadow;\n    bool _5236 = _5233.type == 0;\n    if (_5236 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5233.direction;\n        float _5247 = fa_shadow_factor(param_5, param_6);\n        _6504 = _5247;\n        _6502 *= _5247;\n    }\n    else\n    {\n        bool _5258 = _5233.type != 0;\n        bool _5264;\n        if (_5258)\n        {\n            _5264 = _6503 > 0.0;\n        }\n        else\n        {\n            _5264 = _5258;\n        }\n        if (_5264)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5233.direction;\n            float _5283 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6504 = _5283;\n            _6502 *= _5283;\n        }\n    }\n    bool _5293 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5299;\n    if (_5293)\n    {\n        _5299 = _6503 > 0.0;\n    }\n    else\n    {\n        _5299 = _5293;\n    }\n    if (_5299)\n    {\n        float _5306;\n        if (_5236)\n        {\n            _5306 = 1000000000.0;\n        }\n        else\n        {\n            _5306 = _5233._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5233.direction;\n        float param_18 = _5306;\n        float _5324 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6504 *= _5324;\n        _6502 *= _5324;\n    }\n    float _5337 = _6503;\n    float _5338 = _5337 * _5207;\n    _6503 = _5338;\n    vec3 _5342 = _6502;\n    vec3 _5343 = _5342 * _5207;\n    _6502 = _5343;\n    return LightSample(_5233.direction, _5343, _5338, _6504, _5233._distance, _5233.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5354 = n < 0;\n    bool _5361;\n    if (!_5354)\n    {\n        _5361 = n >= fa_light_count();\n    }\n    else\n    {\n        _5361 = _5354;\n    }\n    if (_5361)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5376 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5376;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4280 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4288 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4291 = int(_4280);\n    int _4294 = int(_4288);\n    float _4304 = _4288 - float(_4294);\n    int _4360 = (_4291 * 9) + _4294;\n    int _4380 = ((_4291 + 1) * 9) + _4294;\n    return mix(mix(_4355[_4360], _4355[_4360 + 1], _4304), mix(_4355[_4380], _4355[_4380 + 1], _4304), _4280 - float(_4291));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6368 = false;\n    float _6369 = 1.0;\n    float _6370 = 1.0;\n    float _6371 = 1.0;\n    float _6372 = 0.0;\n    float _6373 = 0.0;\n    float _6374 = 0.0;\n    float _6375 = 0.0;\n    float _6377 = 1.0;\n    bool _6378 = false;\n    vec3 _6379 = vec3(0.0);\n    float _6380 = 1.0;\n    float _6381 = 1.0;\n    float _6382 = 1.0;\n    float _6383 = 0.0;\n    float _6384 = 0.0;\n    vec3 _6385 = vec3(1.0, 0.0, 0.0);\n    vec3 _6386 = vec3(0.0, 0.0, 1.0);\n    float _6387 = 1.0;\n    float _6388 = 1.0;\n    float _4431 = clamp(s.specular, 0.0, 1.0);\n    float _4435 = clamp(s.ior, 1.0, 3.0);\n    bool _4440 = (_4431 != 1.0) || (_4435 != 1.5);\n    bool _4449;\n    if (!_4440)\n    {\n        _4449 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4449 = _4440;\n    }\n    if (_4449)\n    {\n        float _4457 = (_4435 - 1.0) / (_4435 + 1.0);\n        f0 = mix(min(vec3(_4457 * _4457) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4431, s.albedo, vec3(metallic));\n        _6369 = mix(_4431, 1.0, metallic);\n        _6368 = true;\n    }\n    float _4484 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4484 > 0.0)\n    {\n        float _4492 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6372 = _4484;\n        _6373 = _4492;\n        float _4499 = _4492 * _4492;\n        _6374 = _4499;\n        _6375 = _4499 * _4499;\n        float _4511 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6377 = _4511;\n        _6370 = 1.0 - (_4484 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4511, 0.0, 1.0), 5.0))));\n        _6368 = true;\n    }\n    vec3 _4530 = max(s.sheen_color, vec3(0.0));\n    float _4539 = max(_4530.x, max(_4530.y, _4530.z));\n    if (_4539 > 0.0)\n    {\n        float _4547 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6378 = true;\n        _6379 = _4530;\n        _6380 = _4547;\n        _6381 = _4547 * _4547;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4547;\n        float _4564 = fa_sheen_albedo(param, param_1);\n        _6383 = _4564;\n        _6382 = 1.0 - min(_4539 * _4564, 1.0);\n        _6368 = true;\n    }\n    _6371 = _6370 * _6382;\n    float _4583 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4583 != 0.0)\n    {\n        vec3 _4598 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4598;\n        if (dot(_4598, _4598) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4610 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4610.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4610.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4610.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4614 = t;\n        vec3 _4615 = normalize(_4614);\n        t = _4615;\n        vec3 _4640 = normalize((_4615 * cos(s.anisotropy_rotation)) + ((cross(n, _4615) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6385 = _4640;\n        _6386 = cross(n, _4640);\n        float _4650 = roughness * roughness;\n        float _4656 = mix(_4650, 1.0, _4583 * _4583);\n        bool _4658 = _4583 > 0.0;\n        _6387 = _4658 ? _4656 : _4650;\n        _6388 = _4658 ? _4650 : _4656;\n        _6384 = _4583;\n        _6368 = true;\n    }\n    return FaLayers(_6368, _6369, _6370, _6371, _6372, _6373, _6374, _6375, i.world_normal, _6377, _6378, _6379, _6380, _6381, _6382, _6383, _6384, _6385, _6386, _6387, _6388);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4212 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4215 = _4212.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4215 * _4215, exp2((-9.27999973297119140625) * ndv)) * _4215) + _4212.y)) + _4212.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3648 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3651 = _3648.x;\n    float _3653 = _3648.z;\n    vec2 e = vec2(_3651, _3653);\n    if (_3648.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3653)) * ((_3651 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3651)) * ((_3653 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3700;\n    if (lv == 0)\n    {\n        _3700 = 0.0;\n    }\n    else\n    {\n        _3700 = res + 2.0;\n    }\n    float _3710;\n    if (lv == 0)\n    {\n        _3710 = 0.0;\n    }\n    else\n    {\n        _3710 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3700, _3710)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3756;\n    if (res > 64.5)\n    {\n        _3756 = 5.0;\n    }\n    else\n    {\n        _3756 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3771 = clamp(rough, 0.0, 1.0) * (_3756 - 1.0);\n    int _3778 = int(min(floor(_3771), _3756 - 2.0));\n    float _3783 = _3771 - float(_3778);\n    vec3 param = d;\n    vec2 _3787 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3778;\n    vec2 param_4 = _3787;\n    vec3 _3797 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3783 < 0.00200000009499490261077880859375)\n    {\n        return _3797;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3778 + 1;\n    vec2 param_8 = _3787;\n    return mix(_3797, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3783));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3834 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3841 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3848 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3854 = dot(bx.xyz, d);\n    float _3858 = dot(by.xyz, d);\n    float _3862 = dot(bz.xyz, d);\n    float _3868;\n    if (_3854 > 9.9999999747524270787835121154785e-07)\n    {\n        _3868 = (1.0 - _3834) / _3854;\n    }\n    else\n    {\n        float _3882;\n        if (_3854 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3882 = ((-1.0) - _3834) / _3854;\n        }\n        else\n        {\n            _3882 = 1000000015047466219876688855040.0;\n        }\n        _3868 = _3882;\n    }\n    float tx = _3868;\n    float _3899;\n    if (_3858 > 9.9999999747524270787835121154785e-07)\n    {\n        _3899 = (1.0 - _3841) / _3858;\n    }\n    else\n    {\n        float _3912;\n        if (_3858 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3912 = ((-1.0) - _3841) / _3858;\n        }\n        else\n        {\n            _3912 = 1000000015047466219876688855040.0;\n        }\n        _3899 = _3912;\n    }\n    float ty = _3899;\n    float _3928;\n    if (_3862 > 9.9999999747524270787835121154785e-07)\n    {\n        _3928 = (1.0 - _3848) / _3862;\n    }\n    else\n    {\n        float _3941;\n        if (_3862 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3941 = ((-1.0) - _3848) / _3862;\n        }\n        else\n        {\n            _3941 = 1000000015047466219876688855040.0;\n        }\n        _3928 = _3941;\n    }\n    float _3953 = tx;\n    float _3956 = (_3953 > 0.0) ? _3953 : 1000000015047466219876688855040.0;\n    tx = _3956;\n    float _3957 = ty;\n    float _3960 = (_3957 > 0.0) ? _3957 : 1000000015047466219876688855040.0;\n    ty = _3960;\n    float _3970 = min(_3956, min(_3960, (_3928 > 0.0) ? _3928 : 1000000015047466219876688855040.0));\n    if (_3970 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3986 = (fa_world_pos + (d * _3970)) - posw.xyz;\n    vec3 _3991;\n    if (dot(_3986, _3986) > 1.0000000133514319600180897396058e-10)\n    {\n        _3991 = normalize(_3986);\n    }\n    else\n    {\n        _3991 = d;\n    }\n    return _3991;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4037 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4037 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4067 = rough * rough;\n            float _4098 = 0.60000002384185791015625 * _4067;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4067)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4098, 0.0500000007450580596923828125 + _4098, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4067 * 0.60000002384185791015625));\n        }\n        outc = base * _4037;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4157 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4157 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4189 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4189 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4691;\n        if (L.aniso >= 0.0)\n        {\n            _4691 = L.b;\n        }\n        else\n        {\n            _4691 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4691, v), _4691), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4727 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4727.x) + (vec3(L.f90) * _4727.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4785 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4785.x) + _4785.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4254 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4254.x) + vec3(_4254.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4824 = clamp(s.metallic, 0.0, 1.0);\n    float _4828 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4835 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4824));\n    vec3 f0 = _4835;\n    vec3 _4839 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4839;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4824;\n    float param_5 = _4828;\n    vec3 param_6 = _4835;\n    FaLayers _4856 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4856.on)\n    {\n        FaLayers param_7 = _4856;\n        vec3 param_8 = _4839;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4828;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4839;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4828;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5445 = fa_light_unshadowed(param, param_1);\n        float _5453 = dot(_5445.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5453 > bestPower)\n        {\n            bestPower = _5453;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5482 = fa_light(param_2, param_3);\n        float _5490;\n        if (dot(s.normal, _5482.direction) > 0.5)\n        {\n            _5490 = 1.0;\n        }\n        else\n        {\n            _5490 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5482.color) * _5490);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3087 = int(fa_shadows[25].x + 0.5);\n    float _3097 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3102 = _3087 > 0;\n    bool _3111;\n    if (_3102)\n    {\n        int param = _3087 - 1;\n        _3111 = _3097 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3111 = _3102;\n    }\n    if (_3111)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3117 = _3087 > 1;\n        bool _3124;\n        if (_3117)\n        {\n            _3124 = _3097 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3124 = _3117;\n        }\n        if (_3124)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3130 = _3087 > 2;\n        bool _3137;\n        if (_3130)\n        {\n            _3137 = _3097 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3137 = _3130;\n        }\n        if (_3137)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3143 = _3087 > 3;\n        bool _3150;\n        if (_3143)\n        {\n            _3150 = _3097 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3150 = _3143;\n        }\n        if (_3150)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6222 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6222 = -_6222;\n    }\n    vec3 _5892 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6222, fa_world_tangent, fa_uv, fa_vertex_color, _5892, gl_FrontFacing);\n    Surface _5900 = fa_standard_surface(param_1);\n    vec3 _6253 = _5900.albedo;\n    float _6254 = _5900.alpha;\n    vec3 _6255 = _5900.normal;\n    float _6256 = _5900.metallic;\n    float _6257 = _5900.roughness;\n    float _6258 = _5900.occlusion;\n    vec3 _6259 = _5900.emission;\n    float _6260 = _5900.clearcoat;\n    float _6261 = _5900.clearcoat_roughness;\n    vec3 _6262 = _5900.sheen_color;\n    float _6263 = _5900.sheen_roughness;\n    float _6264 = _5900.anisotropy;\n    float _6265 = _5900.anisotropy_rotation;\n    float _6266 = _5900.specular;\n    float _6267 = _5900.ior;\n    vec3 _6268 = _5900.specular_color;\n    float _6269 = _5900.transmission;\n    float _6270 = _5900.thickness;\n    vec3 _6271 = _5900.attenuation_color;\n    float _6272 = _5900.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6222, fa_world_tangent, fa_uv, fa_vertex_color, _5892, gl_FrontFacing);\n    Surface param_3 = _5900;\n    surface(param_2, param_3);\n    _6253 = param_3.albedo;\n    _6254 = param_3.alpha;\n    _6255 = param_3.normal;\n    _6256 = param_3.metallic;\n    _6257 = param_3.roughness;\n    _6258 = param_3.occlusion;\n    _6259 = param_3.emission;\n    _6260 = param_3.clearcoat;\n    _6261 = param_3.clearcoat_roughness;\n    _6262 = param_3.sheen_color;\n    _6263 = param_3.sheen_roughness;\n    _6264 = param_3.anisotropy;\n    _6265 = param_3.anisotropy_rotation;\n    _6266 = param_3.specular;\n    _6267 = param_3.ior;\n    _6268 = param_3.specular_color;\n    _6269 = param_3.transmission;\n    _6270 = param_3.thickness;\n    _6271 = param_3.attenuation_color;\n    _6272 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6222;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6253 = param_6;\n    _6255 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6253;\n    }\n    else\n    {\n        vec3 _5939 = _6255;\n        vec3 _5940 = normalize(_5939);\n        _6255 = _5940;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6222, fa_world_tangent, fa_uv, fa_vertex_color, _5892, gl_FrontFacing);\n        Surface param_9 = Surface(_6253, _6254, _5940, _6256, _6257, _6258, _6259, _6260, _6261, _6262, _6263, _6264, _6265, _6266, _6267, _6268, _6269, _6270, _6271, _6272);\n        vec3 _5951 = lighting(param_8, param_9);\n        result = _5951;\n    }\n    vec3 _5955 = result;\n    vec3 _5956 = _5955 + _6259;\n    result = _5956;\n    vec3 param_10 = _5956;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5965 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5972;\n    if (!_5965)\n    {\n        _5972 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5972 = _5965;\n    }\n    if (_5972)\n    {\n        vec3 _5981 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5987 = dot(_5981, fa_mesh_fs_params[9].xyz);\n        bool _5991 = fa_mesh_fs_params[9].w > 0.5;\n        float _5992;\n        if (_5991)\n        {\n            _5992 = _5987;\n        }\n        else\n        {\n            _5992 = length(_5981);\n        }\n        float _6004 = _5992 - fa_mesh_fs_params[8].x;\n        if (_6004 > 0.0)\n        {\n            float _6013 = fa_mesh_fs_params[7].w * _6004;\n            float tau = _6013 * _6013;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6029;\n                if (_5991)\n                {\n                    _6029 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5987);\n                }\n                else\n                {\n                    _6029 = fa_mesh_fs_params[0].y;\n                }\n                float _6050 = mix(_6029, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5992, 0.0, 1.0));\n                float _6054 = fa_world_pos.y - _6050;\n                float _6059 = _6050 - fa_mesh_fs_params[8].z;\n                float _6064 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6067 = _6059 <= 0.0;\n                bool _6068 = !_6067;\n                bool _6074;\n                if (_6068)\n                {\n                    _6074 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6074 = _6067;\n                }\n                float _6075;\n                if (_6074)\n                {\n                    _6075 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6075 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6059, 80.0));\n                }\n                bool _6102;\n                if (_6068)\n                {\n                    _6102 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6102 = _6067;\n                }\n                float _6103;\n                if (_6102)\n                {\n                    _6103 = fa_mesh_fs_params[8].y * _6059;\n                }\n                else\n                {\n                    _6103 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6059, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6128 = _6064 <= 0.0;\n                bool _6135;\n                if (!_6128)\n                {\n                    _6135 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6135 = _6128;\n                }\n                float _6136;\n                if (_6135)\n                {\n                    _6136 = fa_mesh_fs_params[8].y * _6064;\n                }\n                else\n                {\n                    _6136 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6064, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6163;\n                if (abs(_6054) < 0.001000000047497451305389404296875)\n                {\n                    _6163 = _6075;\n                }\n                else\n                {\n                    _6163 = (_6136 - _6103) / _6054;\n                }\n                tau += (_6004 * max(_6163, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6254);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_475",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2128",
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
            "inst_name": "_5496",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4355[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[54];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 10) uniform sampler2D fa_probe_atlas_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1404 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1411;\n    if (!_1404)\n    {\n        _1411 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1411 = _1404;\n    }\n    bool _1419;\n    if (!_1411)\n    {\n        _1419 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1419 = _1411;\n    }\n    bool _1426;\n    if (!_1419)\n    {\n        _1426 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1426 = _1419;\n    }\n    bool _1433;\n    if (!_1426)\n    {\n        _1433 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1433 = _1426;\n    }\n    if (_1433)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1443 = vec4(world_pos, 1.0);\n    float _1449 = dot(fa_mesh_fs_params[16], _1443);\n    if (!(_1449 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1471 = vec2(dot(fa_mesh_fs_params[14], _1443), dot(fa_mesh_fs_params[15], _1443)) / vec2(_1449);\n    int _1475 = int(fa_mesh_fs_params[18].x);\n    int _1479 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1479) + clamp(int(floor(((_1471.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1479 - 1)) * _1475)) + clamp(int(floor(((_1471.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1475 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1555 = fa_cluster_texel(param);\n    return ivec2(int(_1555.x), int(_1555.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5181 = fa_cluster_lookup(param);\n    fa_cl_slot = _5181.x;\n    fa_cl_local = _5181.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5557 = fa_linear_to_srgb(param);\n        c = _5557;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5565 = fa_srgb_to_linear(param_1);\n            c = _5565;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _355;\n    if (i.front_facing)\n    {\n        _355 = i.world_normal;\n    }\n    else\n    {\n        _355 = -i.world_normal;\n    }\n    vec3 _379 = normalize(i.world_tangent.xyz - (_355 * dot(_355, i.world_tangent.xyz)));\n    vec3 _407 = normalize(((_379 * m.x) + ((cross(_355, _379) * i.world_tangent.w) * m.y)) + (_355 * m.z));\n    vec3 _410;\n    if (i.front_facing)\n    {\n        _410 = _407;\n    }\n    else\n    {\n        _410 = -_407;\n    }\n    return _410;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5597 = fa_tex_fix(param_2, param_3);\n    vec4 _6765 = base_t;\n    _6765.x = _5597.x;\n    _6765.y = _5597.y;\n    _6765.z = _5597.z;\n    base_t = _6765;\n    vec4 _5611 = (_6765 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6550 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5645 = fa_tex_fix(param_6, param_7);\n        vec3 _5648 = (_5645 * 2.0) - vec3(1.0);\n        vec2 _5653 = _5648.xy * fa_mesh_fs_params[6].x;\n        vec3 _6773 = _5648;\n        _6773.x = _5653.x;\n        _6773.y = _5653.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _6773;\n        _6550 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5683 = fa_tex_fix(param_12, param_13);\n    vec4 _6776 = mrt;\n    _6776.x = _5683.x;\n    _6776.y = _5683.y;\n    _6776.z = _5683.z;\n    mrt = _6776;\n    vec4 _5713 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5713.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5724 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5756 = fa_tex_fix(param_20, param_21);\n    float _6555 = fa_mesh_fs_params[20].x;\n    float _6556 = fa_mesh_fs_params[20].y;\n    float _6559 = fa_mesh_fs_params[20].z;\n    float _6558 = fa_mesh_fs_params[21].w;\n    float _6561 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6555 *= _5724.y;\n            _6556 *= _5724.z;\n            _6558 *= _5713.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6559 *= mrt.x;\n            _6561 *= mrt.w;\n        }\n    }\n    return Surface(_5611.xyz, _5611.w, _6550, clamp(fa_mesh_fs_params[5].x * _5683.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5683.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5724.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5756), _6555, _6556, fa_mesh_fs_params[21].xyz, _6558, _6559, fa_mesh_fs_params[20].w, _6561, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1635 = rect.zw - rect.xy;\n    vec2 _1639 = _1635 * atlas;\n    vec2 _1643 = ddx * _1639;\n    vec2 _1647 = ddy * _1639;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1635), clamp(0.5 * log2(max(max(dot(_1643, _1643), dot(_1647, _1647)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1680 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1687;\n    if (!_1680)\n    {\n        _1687 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1687 = _1680;\n    }\n    if (_1687)\n    {\n        return;\n    }\n    vec3 _1693 = dFdx(world_pos);\n    vec3 _1696 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1700 = fa_cluster_texel(param);\n    int _1704 = int(_1700.w);\n    if (_1704 < 1)\n    {\n        return;\n    }\n    int _1714 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1714;\n    vec4 _1718 = fa_light_texel(param_1);\n    vec2 _1721 = _1718.yz;\n    int _1725 = int(_1718.w);\n    int param_2 = _1714 + 1;\n    vec4 _1730 = fa_light_texel(param_2);\n    float _1731 = _1730.x;\n    int _1737 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1741 = int(_1700.z);\n    vec3 _2006;\n    for (int k = 0; k < _1704; k++)\n    {\n        int _1754 = _1741 + k;\n        int param_3 = _1725 + (_1754 >> 2);\n        int _1771 = (_1714 + 2) + (int(fa_light_texel(param_3)[_1754 & 3]) * 7);\n        int param_4 = _1771 + 6;\n        vec4 _1776 = fa_light_texel(param_4);\n        if (((int(_1776.w + 0.5) >> _1737) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1771;\n        vec4 _1791 = fa_light_texel(param_5);\n        int param_6 = _1771 + 1;\n        vec4 _1796 = fa_light_texel(param_6);\n        int param_7 = _1771 + 2;\n        vec4 _1801 = fa_light_texel(param_7);\n        vec3 _1804 = _1791.xyz;\n        float _1809 = dot(_1804, world_pos) + _1791.w;\n        vec3 _1811 = _1796.xyz;\n        float _1816 = dot(_1811, world_pos) + _1796.w;\n        vec3 _1818 = _1801.xyz;\n        float _1823 = dot(_1818, world_pos) + _1801.w;\n        bool _1828 = abs(_1809) > 0.5;\n        bool _1836;\n        if (!_1828)\n        {\n            _1836 = abs(_1816) > 0.5;\n        }\n        else\n        {\n            _1836 = _1828;\n        }\n        bool _1844;\n        if (!_1836)\n        {\n            _1844 = abs(_1823) > 0.5;\n        }\n        else\n        {\n            _1844 = _1836;\n        }\n        if (_1844)\n        {\n            continue;\n        }\n        float _1859 = clamp(dot(geo_normal, normalize(_1818)) * _1776.z, 0.0, 1.0);\n        if (_1859 <= 0.0)\n        {\n            continue;\n        }\n        float _1879 = (clamp((0.5 - abs(_1823)) * 10.0, 0.0, 1.0) * _1859) * _1776.x;\n        vec2 _1887 = vec2(_1809 + 0.5, 0.5 - _1816);\n        vec2 _1897 = vec2(dot(_1804, _1693), dot(_1811, _1693));\n        vec2 _1907 = vec2(dot(_1804, _1696), dot(_1811, _1696));\n        int param_8 = _1771 + 5;\n        vec4 _1912 = fa_light_texel(param_8);\n        int param_9 = _1771 + 3;\n        vec4 _1917 = fa_light_texel(param_9);\n        int param_10 = _1771 + 4;\n        vec4 _1922 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1912.xyz;\n        bool _1932 = _1917.z > _1917.x;\n        if (_1932)\n        {\n            vec4 param_11 = _1917;\n            vec2 param_12 = _1887;\n            vec2 param_13 = _1721;\n            vec2 param_14 = _1897;\n            vec2 param_15 = _1907;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1731 > 0.5) && (_1731 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1958 = fa_dc_to_linear(param_16);\n                vec4 _6638 = tx;\n                _6638.x = _1958.x;\n                _6638.y = _1958.y;\n                _6638.z = _1958.z;\n                tx = _6638;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1879 * tex_a) * _1912.w, 0.0, 1.0)));\n        if (_1922.z > _1922.x)\n        {\n            vec4 param_17 = _1922;\n            vec2 param_18 = _1887;\n            vec2 param_19 = _1721;\n            vec2 param_20 = _1897;\n            vec2 param_21 = _1907;\n            vec4 _2002 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1731 > 1.5)\n            {\n                vec3 param_22 = _2002.xyz;\n                vec3 _2012 = fa_dc_to_srgb(param_22);\n                _2006 = _2012;\n            }\n            else\n            {\n                _2006 = _2002.xyz;\n            }\n            vec3 _2021 = (_2006 * 2.0) - vec3(1.0);\n            vec2 _2026 = _2021.xy * _1776.y;\n            vec3 _2048 = (normalize(_1804) * _2026.x) + (normalize(_1811) * _2026.y);\n            vec3 _2051 = normalize(normal);\n            normal = normalize(mix(_2051, normalize((_2051 * max(_2021.z, 0.0500000007450580596923828125)) + (_2048 - (_2051 * dot(_2051, _2048)))), vec3(clamp(_1879 * (_1932 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5151;\n    if (fa_lm.z > 0.5)\n    {\n        _5151 = 0.0;\n    }\n    else\n    {\n        _5151 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5162 = _5151 < 1.0;\n    bool _5168;\n    if (_5162)\n    {\n        int param = li;\n        _5168 = fa_light_baked(param);\n    }\n    else\n    {\n        _5168 = _5162;\n    }\n    return _5168 ? _5151 : 1.0;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _653 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _666 = (c - (ru * hx)) - p;\n        vec3 _672 = ru * (2.0 * hx);\n        float _678 = max(dot(_672, _672), 9.9999999392252902907785028219223e-09);\n        float _682 = dot(_666, _672);\n        float t = clamp((-_682) / _678, 0.0, 1.0);\n        if (_653)\n        {\n            float _697 = dot(r, _672);\n            float _703 = _678 - (_697 * _697);\n            if (abs(_703) > (9.9999997473787516355514526367188e-06 * _678))\n            {\n                t = clamp(((dot(r, _666) * _697) - _682) / _703, 0.0, 1.0);\n            }\n        }\n        return (p + _666) + (_672 * t);\n    }\n    vec3 q = p;\n    float _735 = dot(r, axis);\n    bool _743;\n    if (_653)\n    {\n        _743 = abs(_735) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _743 = _653;\n    }\n    if (_743)\n    {\n        float _753 = dot(c - p, axis) / _735;\n        if (_753 > 0.0)\n        {\n            q = p + (r * _753);\n        }\n    }\n    vec3 _766 = q - c;\n    vec2 xy = vec2(dot(_766, ru), dot(_766, uu));\n    if (shape > 0.5)\n    {\n        float _781 = length(xy);\n        if (_781 > hx)\n        {\n            xy *= (hx / _781);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _573 = dot(d, right);\n    float _577 = dot(d, up);\n    float _588;\n    if (((_573 * _573) + (_577 * _577)) > 1.0000000133514319600180897396058e-10)\n    {\n        _588 = atan(_577, _573) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _588 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_588 - floor(_588)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _422 = abs(d);\n    float _424 = _422.x;\n    float _426 = _422.y;\n    bool _427 = _424 >= _426;\n    bool _435;\n    if (_427)\n    {\n        _435 = _424 >= _422.z;\n    }\n    else\n    {\n        _435 = _427;\n    }\n    int _436;\n    if (_435)\n    {\n        _436 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _451;\n        if (_426 >= _422.z)\n        {\n            _451 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _451 = (d.z > 0.0) ? 4 : 5;\n        }\n        _436 = _451;\n    }\n    return _436;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _819 = fa_light_base(param);\n    bool _823 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _819;\n    vec4 _827 = fa_light_texel(param_1);\n    int param_2 = _819 + 1;\n    vec4 _832 = fa_light_texel(param_2);\n    float _835 = _832.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _847 = _823 && (_835 > 2.5);\n    fa_light_is_area = _847;\n    bool _849 = _835 < 0.5;\n    vec3 l;\n    if (_849)\n    {\n        l = normalize(_827.xyz);\n        if (_823)\n        {\n            int param_3 = _819 + 6;\n            vec4 _863 = fa_light_texel(param_3);\n            if (_863.z > 0.5)\n            {\n                int param_4 = _819 + 4;\n                vec4 _873 = fa_light_texel(param_4);\n                int param_5 = _819 + 5;\n                vec4 _878 = fa_light_texel(param_5);\n                vec2 param_6 = _863.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _873.xyz) * _873.w, (-dot(world_pos, _878.xyz)) * _878.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _908 = _827.xyz;\n        vec3 _910 = _908 - world_pos;\n        vec3 to_light = _910;\n        float _913 = length(_910);\n        float reach = _913;\n        bool front = true;\n        if (_847)\n        {\n            int param_8 = _819 + 7;\n            reach = max(_913 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _819 + 4;\n            vec4 _937 = fa_light_texel(param_9);\n            int param_10 = _819 + 5;\n            vec4 _942 = fa_light_texel(param_10);\n            int param_11 = _819 + 6;\n            vec4 _947 = fa_light_texel(param_11);\n            float _948 = _947.w;\n            int param_12 = _819 + 2;\n            vec3 _955 = normalize(fa_light_texel(param_12).xyz);\n            bool _957 = _948 > 1.5;\n            bool _965;\n            if (!_957)\n            {\n                _965 = dot(_955, to_light) < 0.0;\n            }\n            else\n            {\n                _965 = _957;\n            }\n            front = _965;\n            vec3 r = vec3(0.0);\n            vec3 _974 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _978 = dot(n, n) > 0.5;\n            bool _986;\n            if (_978)\n            {\n                _986 = dot(_974, _974) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _986 = _978;\n            }\n            if (_986)\n            {\n                r = reflect(-normalize(_974), normalize(n));\n            }\n            vec3 param_13 = _908;\n            vec3 param_14 = _955;\n            vec3 param_15 = _937.xyz;\n            vec3 param_16 = _942.xyz;\n            float param_17 = _937.w;\n            float param_18 = _942.w;\n            float param_19 = _948;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1022 = length(to_light);\n        dist = _1022;\n        l = to_light / vec3(max(_1022, 9.9999997473787516355514526367188e-05));\n        float _1036 = reach / max(_827.w, 0.001000000047497451305389404296875);\n        float _1042 = clamp(1.0 - (_1036 * _1036), 0.0, 1.0);\n        float _1044;\n        if (front)\n        {\n            _1044 = _1042 * _1042;\n        }\n        else\n        {\n            _1044 = 0.0;\n        }\n        atten = _1044;\n        bool _1055 = _835 < 2.5;\n        if ((_835 > 1.5) && _1055)\n        {\n            int param_22 = _819 + 2;\n            vec4 _1063 = fa_light_texel(param_22);\n            float _1073 = _1063.w;\n            int param_23 = _819 + 3;\n            vec4 _1078 = fa_light_texel(param_23);\n            float _1079 = _1078.x;\n            float cos_inner = _1079;\n            if (_1079 > 1.5)\n            {\n                cos_inner = mix(_1073, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1073, cos_inner, dot(-l, normalize(_1063.xyz)));\n        }\n        if (_823 && (_835 < 1.5))\n        {\n            int param_24 = _819 + 6;\n            vec4 _1103 = fa_light_texel(param_24);\n            if (_1103.z > 0.5)\n            {\n                vec3 _1111 = -to_light;\n                int param_25 = _819 + 4;\n                int param_26 = _819 + 5;\n                vec3 _1125 = fa_light_texel(param_25).xyz;\n                vec3 _1129 = fa_light_texel(param_26).xyz;\n                vec3 _1138 = vec3(dot(_1111, _1125), dot(_1111, _1129), dot(_1111, cross(_1125, _1129)));\n                vec3 param_27 = _1138;\n                int _1142 = fa_cube_face(param_27);\n                int param_28 = _1142;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1169 = vec2(dot(_1138, cross(param_29, param_30)), dot(_1138, param_30)) / vec2(max(dot(_1138, param_29), 9.9999997473787516355514526367188e-05));\n                int _1173 = _1142 / 3;\n                vec2 param_31 = _1103.xy + (vec2(float(_1142 - (_1173 * 3)), float(_1173)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1169.x), 0.5 - (0.5 * _1169.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _819 + 7;\n            vec4 _1203 = fa_light_texel(param_33);\n            if (_1203.z > 0.5)\n            {\n                int param_34 = _819 + 2;\n                int param_35 = _819 + 4;\n                int param_36 = _819 + 5;\n                vec2 param_37 = _1203.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_823 && _1055)\n            {\n                int param_42 = _819 + 6;\n                vec4 _1250 = fa_light_texel(param_42);\n                int param_43 = _819 + 7;\n                vec4 _1255 = fa_light_texel(param_43);\n                bool _1258 = _1250.z > 0.5;\n                bool _1265;\n                if (!_1258)\n                {\n                    _1265 = _1255.z > 0.5;\n                }\n                else\n                {\n                    _1265 = _1258;\n                }\n                if (_1265)\n                {\n                    int param_44 = _819 + 2;\n                    vec4 _1272 = fa_light_texel(param_44);\n                    vec3 _1276 = normalize(_1272.xyz);\n                    int param_45 = _819 + 4;\n                    vec4 _1281 = fa_light_texel(param_45);\n                    int param_46 = _819 + 5;\n                    vec4 _1286 = fa_light_texel(param_46);\n                    if (_1258)\n                    {\n                        vec3 _1294 = -to_light;\n                        float _1301 = _1272.w;\n                        float _1317 = 0.5 / max(dot(_1294, _1276) * (sqrt(max(1.0 - (_1301 * _1301), 0.0)) / max(_1301, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1250.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1294, _1281.xyz) * _1317), 0.5 - (dot(_1294, _1286.xyz) * _1317));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1255.z > 0.5)\n                    {\n                        vec2 param_49 = _1255.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1276;\n                        vec3 param_52 = _1281.xyz;\n                        vec3 param_53 = _1286.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6356 = _832.xyz * atten;\n    if (_823)\n    {\n        _6356 *= fa_light_tint;\n    }\n    int _1386;\n    if (_849)\n    {\n        _1386 = 0;\n    }\n    else\n    {\n        _1386 = ((_835 > 1.5) && (_835 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6356, atten, 1.0, dist, _1386);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _5380 = n < 0;\n    bool _5387;\n    if (!_5380)\n    {\n        _5387 = n >= fa_light_count();\n    }\n    else\n    {\n        _5387 = _5380;\n    }\n    if (_5387)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _5395 = fa_cl_light(param);\n    int param_1 = _5395;\n    float _5399 = fa_baked_keep(param_1);\n    if (_5399 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _5395;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _5415 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_5415.direction, _5415.color * _5399, _5415.attenuation * _5399, _5415.shadow, _5415._distance, _5415.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2175 = fa_shadow_depth(param, param_1);\n    float _2179;\n    if (conv.x < 0.5)\n    {\n        _2179 = _2175;\n    }\n    else\n    {\n        _2179 = (conv.y * conv.z) / (conv.z - (_2175 * (conv.z - conv.y)));\n    }\n    return _2179;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2225 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2231 = vec2(cos(_2225), sin(_2225));\n    vec2 dir = _2231;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2240;\n        if (k < 0.0)\n        {\n            _2240 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2240 = k;\n        }\n        float _2259 = clamp((_2240 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2278 = sqrt((float(i) + 0.5) * 0.0625) * _2259;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2278));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2292 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2292 < (zr - (_2278 * plane)))\n            {\n                sum += _2292;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2320 = sum / cnt;\n        float _2330;\n        if (k < 0.0)\n        {\n            _2330 = (-k) / max(_2320, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2330 = k;\n        }\n        radius = clamp(((max(zr - _2320, 0.0) * unit) * _2330) / texel_m, 1.5, 16.0);\n        dir = _2231;\n    }\n    float lit = 0.0;\n    int _2356 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2356; i_1++)\n    {\n        float _2375 = sqrt((float(i_1) + 0.5) / float(_2356)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2375));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2375 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2356);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2580 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2587;\n    if (!_2580)\n    {\n        _2587 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2587 = _2580;\n    }\n    if (_2587)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2600 = fa_light_texel(param);\n    float _2601 = _2600.x;\n    if (_2601 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2610 = int(_2601 + 0.5);\n    int param_1 = _2610;\n    vec4 _2614 = fa_light_texel(param_1);\n    int param_2 = _2610 + 1;\n    vec4 _2619 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2622 = _2614.y;\n    if (_2622 > 0.0)\n    {\n        float _2639 = 1.0 - smoothstep(0.75 * _2622, _2622, length(world - fa_shadows[27].xyz));\n        fade = _2639;\n        if (_2639 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2614.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2663 = (_2610 + 2) + (face * 6);\n    int param_4 = _2663;\n    int param_5 = _2663 + 1;\n    int param_6 = _2663 + 3;\n    vec4 _2677 = fa_light_texel(param_6);\n    int param_7 = _2663 + 4;\n    vec4 _2682 = fa_light_texel(param_7);\n    int param_8 = _2663 + 5;\n    vec4 _2687 = fa_light_texel(param_8);\n    float _2699 = _2687.x * max(dot(_2677, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2704 = clamp(dot(n, l), 0.0, 1.0);\n    float _2727 = clamp(dot(n, _2677.xyz), -1.0, 1.0);\n    float _2746 = min(sqrt(1.0 - (_2727 * _2727)) / max(abs(dot(n, world - lpos)) / max(dot(_2677, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2749 = _2619.y;\n    float _2751;\n    if (_2749 > 0.0)\n    {\n        _2751 = _2749;\n    }\n    else\n    {\n        _2751 = 1.5 * _2699;\n    }\n    vec4 _2771 = vec4(world + (n * (_2751 * sqrt(1.0 - (_2704 * _2704)))), 1.0);\n    float _2775 = dot(_2677, _2771);\n    float _2778 = _2687.y;\n    if (_2775 < _2778)\n    {\n        return 1.0;\n    }\n    vec2 _2793 = vec2(dot(fa_light_texel(param_4), _2771), dot(fa_light_texel(param_5), _2771)) / vec2(_2775);\n    float _2795 = _2793.x;\n    bool _2798 = _2795 < _2682.x;\n    bool _2807;\n    if (!_2798)\n    {\n        _2807 = _2795 > _2682.z;\n    }\n    else\n    {\n        _2807 = _2798;\n    }\n    bool _2816;\n    if (!_2807)\n    {\n        _2816 = _2793.y < _2682.y;\n    }\n    else\n    {\n        _2816 = _2807;\n    }\n    bool _2825;\n    if (!_2816)\n    {\n        _2825 = _2793.y > _2682.w;\n    }\n    else\n    {\n        _2825 = _2816;\n    }\n    if (_2825)\n    {\n        return 1.0;\n    }\n    float _2831 = _2619.x;\n    float _2833;\n    if (_2831 > 0.0)\n    {\n        _2833 = _2831;\n    }\n    else\n    {\n        _2833 = 1.5 * _2699;\n    }\n    vec2 param_9 = _2793;\n    vec4 param_10 = _2682;\n    float param_11 = _2775 - (_2833 * (1.0 + (0.5 * _2746)));\n    float param_12 = _2699;\n    float param_13 = 1.0;\n    float param_14 = _2687.z * 0.25;\n    float param_15 = (_2699 * min(_2746, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2778, _2687.z);\n    int param_17 = int(_2614.z + 0.5);\n    float param_18 = _2614.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3345 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3351;\n    if (_3345)\n    {\n        _3351 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3351 = _3345;\n    }\n    bool _3357;\n    if (_3351)\n    {\n        _3357 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3357 = _3351;\n    }\n    if (_3357)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3369 = fa_light_texel(param);\n        float _3370 = _3369.z;\n        if (_3370 > 0.5)\n        {\n            float _3383 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3386 = fwidth(_3383);\n            float _3390 = min(1.5 * _3386, 0.100000001490116119384765625 * _3383);\n            vec4 _3396 = vec4(world, 1.0);\n            float _3401 = dot(fa_mesh_fs_params[28], _3396);\n            if (_3401 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3418 = vec2(dot(fa_mesh_fs_params[26], _3396), dot(fa_mesh_fs_params[27], _3396)) / vec2(_3401);\n                float _3423 = (_3418.x * 0.5) + 0.5;\n                float _3427;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3427 = (_3418.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3427 = 0.5 - (_3418.y * 0.5);\n                }\n                bool _3443 = _3423 >= 0.0;\n                bool _3449;\n                if (_3443)\n                {\n                    _3449 = _3423 < 1.0;\n                }\n                else\n                {\n                    _3449 = _3443;\n                }\n                bool _3455;\n                if (_3449)\n                {\n                    _3455 = _3427 >= 0.0;\n                }\n                else\n                {\n                    _3455 = _3449;\n                }\n                bool _3461;\n                if (_3455)\n                {\n                    _3461 = _3427 < 1.0;\n                }\n                else\n                {\n                    _3461 = _3455;\n                }\n                if (_3461)\n                {\n                    ivec2 _3478 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3479 = clamp(ivec2(vec2(_3423, _3427) * fa_mesh_fs_params[24].zw), ivec2(0), _3478);\n                    ivec2 _3491;\n                    ivec2 _3497;\n                    ivec2 _3504;\n                    float _3555;\n                    float _3576;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3491 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3497 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3504 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3515 = bvec2(k == 3);\n                                    _3504 = ivec2(_3515.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3515.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3497 = _3504;\n                            }\n                            _3491 = _3497;\n                        }\n                        vec4 _3532 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3479 + _3491, ivec2(0), _3478), 0);\n                        bool _3535 = _3532.w > 0.5;\n                        bool _3549;\n                        if (_3535)\n                        {\n                            _3549 = abs(_3383 - _3532.x) <= (((0.00200000009499490261077880859375 * _3383) + 0.00999999977648258209228515625) + _3390);\n                        }\n                        else\n                        {\n                            _3549 = _3535;\n                        }\n                        if (_3549)\n                        {\n                            if (_3370 < 1.5)\n                            {\n                                _3555 = 1.0;\n                            }\n                            else\n                            {\n                                _3555 = (_3370 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3572 = mod(floor(_3532.z / _3555), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3576 = min(_3572, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3576 = _3572;\n                            }\n                            return _3576;\n                        }\n                    }\n                }\n            }\n            float _3601;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3601 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3601 = 1.0;\n            }\n            return _3601;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2118;\n    if (i == 0)\n    {\n        _2118 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2134;\n        if (i == 1)\n        {\n            _2134 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2142;\n            if (i == 2)\n            {\n                _2142 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2142 = fa_shadows[24].w;\n            }\n            _2134 = _2142;\n        }\n        _2118 = _2134;\n    }\n    return _2118;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2421 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2426 = clamp(dot(n, l), 0.0, 1.0);\n    float _2432 = sqrt(1.0 - (_2426 * _2426));\n    float _2440 = min(_2432 / max(_2426, 0.20000000298023223876953125), 4.0);\n    float _2445;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2445 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2445 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2470 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2445 * _2432)), 1.0);\n    float _2477 = _2470.x;\n    bool _2480 = _2477 < fa_shadows[ci * 1 + 16].x;\n    bool _2489;\n    if (!_2480)\n    {\n        _2489 = _2477 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2489 = _2480;\n    }\n    bool _2498;\n    if (!_2489)\n    {\n        _2498 = _2470.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2498 = _2489;\n    }\n    bool _2507;\n    if (!_2498)\n    {\n        _2507 = _2470.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2507 = _2498;\n    }\n    bool _2514;\n    if (!_2507)\n    {\n        _2514 = _2470.z > 1.0;\n    }\n    else\n    {\n        _2514 = _2507;\n    }\n    if (_2514)\n    {\n        return -1.0;\n    }\n    float _2522;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2522 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2522 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2470.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2470.z - ((_2522 * (1.0 + (0.5 * _2440))) / _2421);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2421;\n    float param_5 = _2421 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2440, 3.0)) * 0.5) / _2421;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2900 = int(fa_shadows[25].x + 0.5);\n    if (_2900 < 1)\n    {\n        return 1.0;\n    }\n    float _2915 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2900 - 1;\n    if (_2915 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2927 = _2900 > 1;\n    bool _2934;\n    if (_2927)\n    {\n        _2934 = _2915 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2934 = _2927;\n    }\n    if (_2934)\n    {\n        ci = 1;\n    }\n    bool _2938 = _2900 > 2;\n    bool _2945;\n    if (_2938)\n    {\n        _2945 = _2915 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2945 = _2938;\n    }\n    if (_2945)\n    {\n        ci = 2;\n    }\n    bool _2949 = _2900 > 3;\n    bool _2956;\n    if (_2949)\n    {\n        _2956 = _2915 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2956 = _2949;\n    }\n    if (_2956)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2967 = min(_2900, 4);\n    float _3008;\n    for (int c = ci; c < _2967; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2987 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2987;\n            break;\n        }\n        if (_2987 < 0.0)\n        {\n            continue;\n        }\n        s = _2987;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3008 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3008 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3027 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3008, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2915 - (fa_shadow_split_at(param_7) - _3027)) / _3027, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3059;\n        if ((ci + 1) < _2900)\n        {\n            _3059 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3059 = 1.0;\n        }\n        s = mix(s, _3059, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3164 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3170;\n    if (_3164)\n    {\n        _3170 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3170 = _3164;\n    }\n    if (_3170)\n    {\n        float _3184 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3187 = fwidth(_3184);\n        vec4 _3197 = vec4(fa_world_pos, 1.0);\n        float _3203 = dot(fa_mesh_fs_params[28], _3197);\n        if (_3203 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3222 = vec2(dot(fa_mesh_fs_params[26], _3197), dot(fa_mesh_fs_params[27], _3197)) / vec2(_3203);\n            float _3227 = (_3222.x * 0.5) + 0.5;\n            float _3231;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3231 = (_3222.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3231 = 0.5 - (_3222.y * 0.5);\n            }\n            bool _3247 = _3227 >= 0.0;\n            bool _3253;\n            if (_3247)\n            {\n                _3253 = _3227 < 1.0;\n            }\n            else\n            {\n                _3253 = _3247;\n            }\n            bool _3259;\n            if (_3253)\n            {\n                _3259 = _3231 >= 0.0;\n            }\n            else\n            {\n                _3259 = _3253;\n            }\n            bool _3265;\n            if (_3259)\n            {\n                _3265 = _3231 < 1.0;\n            }\n            else\n            {\n                _3265 = _3259;\n            }\n            if (_3265)\n            {\n                vec4 _3291 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3227, _3231) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3294 = _3291.w > 0.5;\n                bool _3310;\n                if (_3294)\n                {\n                    _3310 = abs(_3184 - _3291.x) <= (((0.00200000009499490261077880859375 * _3184) + 0.00999999977648258209228515625) + min(1.5 * _3187, 0.100000001490116119384765625 * _3184));\n                }\n                else\n                {\n                    _3310 = _3294;\n                }\n                if (_3310)\n                {\n                    float _3316;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3316 = min(_3291.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3316 = _3291.y;\n                    }\n                    return _3316;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4895 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4902;\n    if (!_4895)\n    {\n        _4902 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4902 = _4895;\n    }\n    if (_4902)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4915 = fa_light_texel(param);\n    float _4916 = _4915.y;\n    float len = _4916;\n    if (_4916 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4928 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4937 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4928);\n    if (_4937 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4943 = len;\n    float _4946 = min(_4943, 0.89999997615814208984375 * dist);\n    len = _4946;\n    float _4951 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4928);\n    float _4956 = _4951 + (0.5 * _4946);\n    vec3 _4962 = world + (gn * _4951);\n    float _4964 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5025;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4979 = (float(k) + _4964) * 0.083333335816860198974609375;\n        vec3 _4987 = _4962 + (l * (_4979 * len));\n        vec4 _4993 = vec4(_4987, 1.0);\n        float _4998 = dot(fa_mesh_fs_params[28], _4993);\n        if (_4998 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5016 = vec2(dot(fa_mesh_fs_params[26], _4993), dot(fa_mesh_fs_params[27], _4993)) / vec2(_4998);\n        float _5020 = _5016.x * 0.5;\n        float _5021 = _5020 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5025 = (_5016.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5025 = 0.5 - (_5016.y * 0.5);\n        }\n        bool _5041 = _5021 < 0.0;\n        bool _5048;\n        if (!_5041)\n        {\n            _5048 = _5021 >= 1.0;\n        }\n        else\n        {\n            _5048 = _5041;\n        }\n        bool _5055;\n        if (!_5048)\n        {\n            _5055 = _5025 < 0.0;\n        }\n        else\n        {\n            _5055 = _5048;\n        }\n        bool _5062;\n        if (!_5055)\n        {\n            _5062 = _5025 >= 1.0;\n        }\n        else\n        {\n            _5062 = _5055;\n        }\n        if (_5062)\n        {\n            break;\n        }\n        vec4 _5086 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5021, _5025) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5086.w < 0.5)\n        {\n            continue;\n        }\n        float _5104 = (dot(fa_mesh_fs_params[29].xyz, _4987) + fa_mesh_fs_params[29].w) - _5086.x;\n        if ((_5104 > _4951) && (_5104 < _4956))\n        {\n            occ = max(occ, (1.0 - (_4979 * _4979)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5021, 0.5 - _5020), min(_5025, 1.0 - _5025))));\n        }\n    }\n    return 1.0 - (occ * _4937);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5207 = fa_baked_keep(param);\n    if (_5207 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5233 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6502 = _5233.color;\n    float _6503 = _5233.attenuation;\n    float _6504 = _5233.shadow;\n    bool _5236 = _5233.type == 0;\n    if (_5236 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5233.direction;\n        float _5247 = fa_shadow_factor(param_5, param_6);\n        _6504 = _5247;\n        _6502 *= _5247;\n    }\n    else\n    {\n        bool _5258 = _5233.type != 0;\n        bool _5264;\n        if (_5258)\n        {\n            _5264 = _6503 > 0.0;\n        }\n        else\n        {\n            _5264 = _5258;\n        }\n        if (_5264)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5233.direction;\n            float _5283 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _6504 = _5283;\n            _6502 *= _5283;\n        }\n    }\n    bool _5293 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5299;\n    if (_5293)\n    {\n        _5299 = _6503 > 0.0;\n    }\n    else\n    {\n        _5299 = _5293;\n    }\n    if (_5299)\n    {\n        float _5306;\n        if (_5236)\n        {\n            _5306 = 1000000000.0;\n        }\n        else\n        {\n            _5306 = _5233._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5233.direction;\n        float param_18 = _5306;\n        float _5324 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6504 *= _5324;\n        _6502 *= _5324;\n    }\n    float _5337 = _6503;\n    float _5338 = _5337 * _5207;\n    _6503 = _5338;\n    vec3 _5342 = _6502;\n    vec3 _5343 = _5342 * _5207;\n    _6502 = _5343;\n    return LightSample(_5233.direction, _5343, _5338, _6504, _5233._distance, _5233.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _5354 = n < 0;\n    bool _5361;\n    if (!_5354)\n    {\n        _5361 = n >= fa_light_count();\n    }\n    else\n    {\n        _5361 = _5354;\n    }\n    if (_5361)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _5376 = fa_light_shadowed(param_1, param_2, param_3);\n    return _5376;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4280 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4288 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4291 = int(_4280);\n    int _4294 = int(_4288);\n    float _4304 = _4288 - float(_4294);\n    int _4360 = (_4291 * 9) + _4294;\n    int _4380 = ((_4291 + 1) * 9) + _4294;\n    return mix(mix(_4355[_4360], _4355[_4360 + 1], _4304), mix(_4355[_4380], _4355[_4380 + 1], _4304), _4280 - float(_4291));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6368 = false;\n    float _6369 = 1.0;\n    float _6370 = 1.0;\n    float _6371 = 1.0;\n    float _6372 = 0.0;\n    float _6373 = 0.0;\n    float _6374 = 0.0;\n    float _6375 = 0.0;\n    float _6377 = 1.0;\n    bool _6378 = false;\n    vec3 _6379 = vec3(0.0);\n    float _6380 = 1.0;\n    float _6381 = 1.0;\n    float _6382 = 1.0;\n    float _6383 = 0.0;\n    float _6384 = 0.0;\n    vec3 _6385 = vec3(1.0, 0.0, 0.0);\n    vec3 _6386 = vec3(0.0, 0.0, 1.0);\n    float _6387 = 1.0;\n    float _6388 = 1.0;\n    float _4431 = clamp(s.specular, 0.0, 1.0);\n    float _4435 = clamp(s.ior, 1.0, 3.0);\n    bool _4440 = (_4431 != 1.0) || (_4435 != 1.5);\n    bool _4449;\n    if (!_4440)\n    {\n        _4449 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4449 = _4440;\n    }\n    if (_4449)\n    {\n        float _4457 = (_4435 - 1.0) / (_4435 + 1.0);\n        f0 = mix(min(vec3(_4457 * _4457) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4431, s.albedo, vec3(metallic));\n        _6369 = mix(_4431, 1.0, metallic);\n        _6368 = true;\n    }\n    float _4484 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4484 > 0.0)\n    {\n        float _4492 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6372 = _4484;\n        _6373 = _4492;\n        float _4499 = _4492 * _4492;\n        _6374 = _4499;\n        _6375 = _4499 * _4499;\n        float _4511 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6377 = _4511;\n        _6370 = 1.0 - (_4484 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4511, 0.0, 1.0), 5.0))));\n        _6368 = true;\n    }\n    vec3 _4530 = max(s.sheen_color, vec3(0.0));\n    float _4539 = max(_4530.x, max(_4530.y, _4530.z));\n    if (_4539 > 0.0)\n    {\n        float _4547 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6378 = true;\n        _6379 = _4530;\n        _6380 = _4547;\n        _6381 = _4547 * _4547;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4547;\n        float _4564 = fa_sheen_albedo(param, param_1);\n        _6383 = _4564;\n        _6382 = 1.0 - min(_4539 * _4564, 1.0);\n        _6368 = true;\n    }\n    _6371 = _6370 * _6382;\n    float _4583 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4583 != 0.0)\n    {\n        vec3 _4598 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4598;\n        if (dot(_4598, _4598) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4610 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4610.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4610.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4610.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4614 = t;\n        vec3 _4615 = normalize(_4614);\n        t = _4615;\n        vec3 _4640 = normalize((_4615 * cos(s.anisotropy_rotation)) + ((cross(n, _4615) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6385 = _4640;\n        _6386 = cross(n, _4640);\n        float _4650 = roughness * roughness;\n        float _4656 = mix(_4650, 1.0, _4583 * _4583);\n        bool _4658 = _4583 > 0.0;\n        _6387 = _4658 ? _4656 : _4650;\n        _6388 = _4658 ? _4650 : _4656;\n        _6384 = _4583;\n        _6368 = true;\n    }\n    return FaLayers(_6368, _6369, _6370, _6371, _6372, _6373, _6374, _6375, i.world_normal, _6377, _6378, _6379, _6380, _6381, _6382, _6383, _6384, _6385, _6386, _6387, _6388);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4212 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4215 = _4212.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4215 * _4215, exp2((-9.27999973297119140625) * ndv)) * _4215) + _4212.y)) + _4212.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3648 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3651 = _3648.x;\n    float _3653 = _3648.z;\n    vec2 e = vec2(_3651, _3653);\n    if (_3648.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3653)) * ((_3651 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3651)) * ((_3653 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3700;\n    if (lv == 0)\n    {\n        _3700 = 0.0;\n    }\n    else\n    {\n        _3700 = res + 2.0;\n    }\n    float _3710;\n    if (lv == 0)\n    {\n        _3710 = 0.0;\n    }\n    else\n    {\n        _3710 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3700, _3710)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3756;\n    if (res > 64.5)\n    {\n        _3756 = 5.0;\n    }\n    else\n    {\n        _3756 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3771 = clamp(rough, 0.0, 1.0) * (_3756 - 1.0);\n    int _3778 = int(min(floor(_3771), _3756 - 2.0));\n    float _3783 = _3771 - float(_3778);\n    vec3 param = d;\n    vec2 _3787 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3778;\n    vec2 param_4 = _3787;\n    vec3 _3797 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3783 < 0.00200000009499490261077880859375)\n    {\n        return _3797;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3778 + 1;\n    vec2 param_8 = _3787;\n    return mix(_3797, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3783));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3834 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3841 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3848 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3854 = dot(bx.xyz, d);\n    float _3858 = dot(by.xyz, d);\n    float _3862 = dot(bz.xyz, d);\n    float _3868;\n    if (_3854 > 9.9999999747524270787835121154785e-07)\n    {\n        _3868 = (1.0 - _3834) / _3854;\n    }\n    else\n    {\n        float _3882;\n        if (_3854 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3882 = ((-1.0) - _3834) / _3854;\n        }\n        else\n        {\n            _3882 = 1000000015047466219876688855040.0;\n        }\n        _3868 = _3882;\n    }\n    float tx = _3868;\n    float _3899;\n    if (_3858 > 9.9999999747524270787835121154785e-07)\n    {\n        _3899 = (1.0 - _3841) / _3858;\n    }\n    else\n    {\n        float _3912;\n        if (_3858 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3912 = ((-1.0) - _3841) / _3858;\n        }\n        else\n        {\n            _3912 = 1000000015047466219876688855040.0;\n        }\n        _3899 = _3912;\n    }\n    float ty = _3899;\n    float _3928;\n    if (_3862 > 9.9999999747524270787835121154785e-07)\n    {\n        _3928 = (1.0 - _3848) / _3862;\n    }\n    else\n    {\n        float _3941;\n        if (_3862 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3941 = ((-1.0) - _3848) / _3862;\n        }\n        else\n        {\n            _3941 = 1000000015047466219876688855040.0;\n        }\n        _3928 = _3941;\n    }\n    float _3953 = tx;\n    float _3956 = (_3953 > 0.0) ? _3953 : 1000000015047466219876688855040.0;\n    tx = _3956;\n    float _3957 = ty;\n    float _3960 = (_3957 > 0.0) ? _3957 : 1000000015047466219876688855040.0;\n    ty = _3960;\n    float _3970 = min(_3956, min(_3960, (_3928 > 0.0) ? _3928 : 1000000015047466219876688855040.0));\n    if (_3970 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3986 = (fa_world_pos + (d * _3970)) - posw.xyz;\n    vec3 _3991;\n    if (dot(_3986, _3986) > 1.0000000133514319600180897396058e-10)\n    {\n        _3991 = normalize(_3986);\n    }\n    else\n    {\n        _3991 = d;\n    }\n    return _3991;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4037 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4037 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4067 = rough * rough;\n            float _4098 = 0.60000002384185791015625 * _4067;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4067)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4098, 0.0500000007450580596923828125 + _4098, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4067 * 0.60000002384185791015625));\n        }\n        outc = base * _4037;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4157 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4157 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4189 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4189 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4691;\n        if (L.aniso >= 0.0)\n        {\n            _4691 = L.b;\n        }\n        else\n        {\n            _4691 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4691, v), _4691), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4727 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4727.x) + (vec3(L.f90) * _4727.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4785 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4785.x) + _4785.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4254 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4254.x) + vec3(_4254.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4824 = clamp(s.metallic, 0.0, 1.0);\n    float _4828 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4835 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4824));\n    vec3 f0 = _4835;\n    vec3 _4839 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4839;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4824;\n    float param_5 = _4828;\n    vec3 param_6 = _4835;\n    FaLayers _4856 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4856.on)\n    {\n        FaLayers param_7 = _4856;\n        vec3 param_8 = _4839;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4828;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4839;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4828;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _5445 = fa_light_unshadowed(param, param_1);\n        float _5453 = dot(_5445.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_5453 > bestPower)\n        {\n            bestPower = _5453;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _5482 = fa_light(param_2, param_3);\n        float _5490;\n        if (dot(s.normal, _5482.direction) > 0.5)\n        {\n            _5490 = 1.0;\n        }\n        else\n        {\n            _5490 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _5482.color) * _5490);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3087 = int(fa_shadows[25].x + 0.5);\n    float _3097 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3102 = _3087 > 0;\n    bool _3111;\n    if (_3102)\n    {\n        int param = _3087 - 1;\n        _3111 = _3097 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3111 = _3102;\n    }\n    if (_3111)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3117 = _3087 > 1;\n        bool _3124;\n        if (_3117)\n        {\n            _3124 = _3097 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3124 = _3117;\n        }\n        if (_3124)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3130 = _3087 > 2;\n        bool _3137;\n        if (_3130)\n        {\n            _3137 = _3097 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3137 = _3130;\n        }\n        if (_3137)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3143 = _3087 > 3;\n        bool _3150;\n        if (_3143)\n        {\n            _3150 = _3097 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3150 = _3143;\n        }\n        if (_3150)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6222 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6222 = -_6222;\n    }\n    vec3 _5892 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6222, fa_world_tangent, fa_uv, fa_vertex_color, _5892, gl_FrontFacing);\n    Surface _5900 = fa_standard_surface(param_1);\n    vec3 _6253 = _5900.albedo;\n    float _6254 = _5900.alpha;\n    vec3 _6255 = _5900.normal;\n    float _6256 = _5900.metallic;\n    float _6257 = _5900.roughness;\n    float _6258 = _5900.occlusion;\n    vec3 _6259 = _5900.emission;\n    float _6260 = _5900.clearcoat;\n    float _6261 = _5900.clearcoat_roughness;\n    vec3 _6262 = _5900.sheen_color;\n    float _6263 = _5900.sheen_roughness;\n    float _6264 = _5900.anisotropy;\n    float _6265 = _5900.anisotropy_rotation;\n    float _6266 = _5900.specular;\n    float _6267 = _5900.ior;\n    vec3 _6268 = _5900.specular_color;\n    float _6269 = _5900.transmission;\n    float _6270 = _5900.thickness;\n    vec3 _6271 = _5900.attenuation_color;\n    float _6272 = _5900.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6222, fa_world_tangent, fa_uv, fa_vertex_color, _5892, gl_FrontFacing);\n    Surface param_3 = _5900;\n    surface(param_2, param_3);\n    _6253 = param_3.albedo;\n    _6254 = param_3.alpha;\n    _6255 = param_3.normal;\n    _6256 = param_3.metallic;\n    _6257 = param_3.roughness;\n    _6258 = param_3.occlusion;\n    _6259 = param_3.emission;\n    _6260 = param_3.clearcoat;\n    _6261 = param_3.clearcoat_roughness;\n    _6262 = param_3.sheen_color;\n    _6263 = param_3.sheen_roughness;\n    _6264 = param_3.anisotropy;\n    _6265 = param_3.anisotropy_rotation;\n    _6266 = param_3.specular;\n    _6267 = param_3.ior;\n    _6268 = param_3.specular_color;\n    _6269 = param_3.transmission;\n    _6270 = param_3.thickness;\n    _6271 = param_3.attenuation_color;\n    _6272 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6222;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6253 = param_6;\n    _6255 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6253;\n    }\n    else\n    {\n        vec3 _5939 = _6255;\n        vec3 _5940 = normalize(_5939);\n        _6255 = _5940;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6222, fa_world_tangent, fa_uv, fa_vertex_color, _5892, gl_FrontFacing);\n        Surface param_9 = Surface(_6253, _6254, _5940, _6256, _6257, _6258, _6259, _6260, _6261, _6262, _6263, _6264, _6265, _6266, _6267, _6268, _6269, _6270, _6271, _6272);\n        vec3 _5951 = lighting(param_8, param_9);\n        result = _5951;\n    }\n    vec3 _5955 = result;\n    vec3 _5956 = _5955 + _6259;\n    result = _5956;\n    vec3 param_10 = _5956;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _5965 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5972;\n    if (!_5965)\n    {\n        _5972 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5972 = _5965;\n    }\n    if (_5972)\n    {\n        vec3 _5981 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5987 = dot(_5981, fa_mesh_fs_params[9].xyz);\n        bool _5991 = fa_mesh_fs_params[9].w > 0.5;\n        float _5992;\n        if (_5991)\n        {\n            _5992 = _5987;\n        }\n        else\n        {\n            _5992 = length(_5981);\n        }\n        float _6004 = _5992 - fa_mesh_fs_params[8].x;\n        if (_6004 > 0.0)\n        {\n            float _6013 = fa_mesh_fs_params[7].w * _6004;\n            float tau = _6013 * _6013;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6029;\n                if (_5991)\n                {\n                    _6029 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5987);\n                }\n                else\n                {\n                    _6029 = fa_mesh_fs_params[0].y;\n                }\n                float _6050 = mix(_6029, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5992, 0.0, 1.0));\n                float _6054 = fa_world_pos.y - _6050;\n                float _6059 = _6050 - fa_mesh_fs_params[8].z;\n                float _6064 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6067 = _6059 <= 0.0;\n                bool _6068 = !_6067;\n                bool _6074;\n                if (_6068)\n                {\n                    _6074 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6074 = _6067;\n                }\n                float _6075;\n                if (_6074)\n                {\n                    _6075 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6075 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6059, 80.0));\n                }\n                bool _6102;\n                if (_6068)\n                {\n                    _6102 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6102 = _6067;\n                }\n                float _6103;\n                if (_6102)\n                {\n                    _6103 = fa_mesh_fs_params[8].y * _6059;\n                }\n                else\n                {\n                    _6103 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6059, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6128 = _6064 <= 0.0;\n                bool _6135;\n                if (!_6128)\n                {\n                    _6135 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6135 = _6128;\n                }\n                float _6136;\n                if (_6135)\n                {\n                    _6136 = fa_mesh_fs_params[8].y * _6064;\n                }\n                else\n                {\n                    _6136 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6064, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6163;\n                if (abs(_6054) < 0.001000000047497451305389404296875)\n                {\n                    _6163 = _6075;\n                }\n                else\n                {\n                    _6163 = (_6136 - _6103) / _6054;\n                }\n                tau += (_6004 * max(_6163, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6254);\n}\n\n",
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
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_475",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
            "inst_name": "_2128",
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
            "inst_name": "_5496",
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
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
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
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
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
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _458 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_458, 1.0);\n    fa_world_pos = _458;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_458 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_57",
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
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_225",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _723 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_723, 1.0);\n    fa_world_pos = _723;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_723 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[54];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _892 = base_t;\n    _892.x = _230.x;\n    _892.y = _230.y;\n    _892.z = _230.z;\n    base_t = _892;\n    vec4 _246 = (_892 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _847 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _900 = _286;\n        _900.x = _291.x;\n        _900.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _900;\n        _847 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _903 = mrt;\n    _903.x = _322.x;\n    _903.y = _322.y;\n    _903.z = _322.z;\n    mrt = _903;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _852 = fa_mesh_fs_params[20].x;\n    float _853 = fa_mesh_fs_params[20].y;\n    float _856 = fa_mesh_fs_params[20].z;\n    float _855 = fa_mesh_fs_params[21].w;\n    float _858 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _852 *= _366.y;\n            _853 *= _366.z;\n            _855 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _856 *= mrt.x;\n            _858 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _847, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _852, _853, fa_mesh_fs_params[21].xyz, _855, _856, fa_mesh_fs_params[20].w, _858, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _742 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _742 = -_742;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _742, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_74",
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
            "inst_name": "_213",
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
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_470",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 864,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 54,
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
          },
          {
            "texture": {
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
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
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
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
          }
        ]
      }
    }
  }
}
