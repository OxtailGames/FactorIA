{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "d5ad4ba00a2086cd5c3d6440d2be629e3ce9b0f8ede644c9a19112677c2fea28",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1382 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1389;\n    if (!_1382)\n    {\n        _1389 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1389 = _1382;\n    }\n    bool _1397;\n    if (!_1389)\n    {\n        _1397 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1397 = _1389;\n    }\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1411;\n    if (!_1404)\n    {\n        _1411 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1411 = _1404;\n    }\n    if (_1411)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1421 = vec4(world_pos, 1.0);\n    float _1427 = dot(fa_mesh_fs_params[16], _1421);\n    if (!(_1427 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1449 = vec2(dot(fa_mesh_fs_params[14], _1421), dot(fa_mesh_fs_params[15], _1421)) / vec2(_1427);\n    int _1453 = int(fa_mesh_fs_params[18].x);\n    int _1457 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1457) + clamp(int(floor(((_1449.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1457 - 1)) * _1453)) + clamp(int(floor(((_1449.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1453 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1533 = fa_cluster_texel(param);\n    return ivec2(int(_1533.x), int(_1533.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3782 = fa_cluster_lookup(param);\n    fa_cl_slot = _3782.x;\n    fa_cl_local = _3782.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3987 = fa_linear_to_srgb(param);\n        c = _3987;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3995 = fa_srgb_to_linear(param_1);\n            c = _3995;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _298;\n    if (i.front_facing)\n    {\n        _298 = i.world_normal;\n    }\n    else\n    {\n        _298 = -i.world_normal;\n    }\n    vec3 _322 = normalize(i.world_tangent.xyz - (_298 * dot(_298, i.world_tangent.xyz)));\n    vec3 _349 = normalize(((_322 * m.x) + ((cross(_298, _322) * i.world_tangent.w) * m.y)) + (_298 * m.z));\n    vec3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4026 = fa_tex_fix(param_2, param_3);\n    vec4 _5798 = base_t;\n    _5798.x = _4026.x;\n    _5798.y = _4026.y;\n    _5798.z = _4026.z;\n    base_t = _5798;\n    vec4 _4040 = (_5798 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5635 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4072 = fa_tex_fix(param_6, param_7);\n        vec3 _4075 = (_4072 * 2.0) - vec3(1.0);\n        vec2 _4080 = _4075.xy * fa_mesh_fs_params[6].x;\n        vec3 _5806 = _4075;\n        _5806.x = _4080.x;\n        _5806.y = _4080.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5806;\n        _5635 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4108 = fa_tex_fix(param_12, param_13);\n    vec4 _5809 = mrt;\n    _5809.x = _4108.x;\n    _5809.y = _4108.y;\n    _5809.z = _4108.z;\n    mrt = _5809;\n    vec4 _4136 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4136.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4147 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4177 = fa_tex_fix(param_20, param_21);\n    float _5640 = fa_mesh_fs_params[20].x;\n    float _5641 = fa_mesh_fs_params[20].y;\n    float _5644 = fa_mesh_fs_params[20].z;\n    float _5643 = fa_mesh_fs_params[21].w;\n    float _5646 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5640 *= _4147.y;\n            _5641 *= _4147.z;\n            _5643 *= _4136.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5644 *= mrt.x;\n            _5646 *= mrt.w;\n        }\n    }\n    return Surface(_4040.xyz, _4040.w, _5635, clamp(fa_mesh_fs_params[5].x * _4108.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4108.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4147.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4177), _5640, _5641, fa_mesh_fs_params[21].xyz, _5643, _5644, fa_mesh_fs_params[20].w, _5646, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1613 = rect.zw - rect.xy;\n    vec2 _1617 = _1613 * atlas;\n    vec2 _1621 = ddx * _1617;\n    vec2 _1625 = ddy * _1617;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1613), clamp(0.5 * log2(max(max(dot(_1621, _1621), dot(_1625, _1625)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1658 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1665;\n    if (!_1658)\n    {\n        _1665 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1665 = _1658;\n    }\n    if (_1665)\n    {\n        return;\n    }\n    vec3 _1671 = dFdx(world_pos);\n    vec3 _1674 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1678 = fa_cluster_texel(param);\n    int _1682 = int(_1678.w);\n    if (_1682 < 1)\n    {\n        return;\n    }\n    int _1692 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1692;\n    vec4 _1696 = fa_light_texel(param_1);\n    vec2 _1699 = _1696.yz;\n    int _1703 = int(_1696.w);\n    int param_2 = _1692 + 1;\n    vec4 _1708 = fa_light_texel(param_2);\n    float _1709 = _1708.x;\n    int _1715 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1719 = int(_1678.z);\n    vec3 _1984;\n    for (int k = 0; k < _1682; k++)\n    {\n        int _1732 = _1719 + k;\n        int param_3 = _1703 + (_1732 >> 2);\n        int _1749 = (_1692 + 2) + (int(fa_light_texel(param_3)[_1732 & 3]) * 7);\n        int param_4 = _1749 + 6;\n        vec4 _1754 = fa_light_texel(param_4);\n        if (((int(_1754.w + 0.5) >> _1715) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1749;\n        vec4 _1769 = fa_light_texel(param_5);\n        int param_6 = _1749 + 1;\n        vec4 _1774 = fa_light_texel(param_6);\n        int param_7 = _1749 + 2;\n        vec4 _1779 = fa_light_texel(param_7);\n        vec3 _1782 = _1769.xyz;\n        float _1787 = dot(_1782, world_pos) + _1769.w;\n        vec3 _1789 = _1774.xyz;\n        float _1794 = dot(_1789, world_pos) + _1774.w;\n        vec3 _1796 = _1779.xyz;\n        float _1801 = dot(_1796, world_pos) + _1779.w;\n        bool _1806 = abs(_1787) > 0.5;\n        bool _1814;\n        if (!_1806)\n        {\n            _1814 = abs(_1794) > 0.5;\n        }\n        else\n        {\n            _1814 = _1806;\n        }\n        bool _1822;\n        if (!_1814)\n        {\n            _1822 = abs(_1801) > 0.5;\n        }\n        else\n        {\n            _1822 = _1814;\n        }\n        if (_1822)\n        {\n            continue;\n        }\n        float _1837 = clamp(dot(geo_normal, normalize(_1796)) * _1754.z, 0.0, 1.0);\n        if (_1837 <= 0.0)\n        {\n            continue;\n        }\n        float _1857 = (clamp((0.5 - abs(_1801)) * 10.0, 0.0, 1.0) * _1837) * _1754.x;\n        vec2 _1865 = vec2(_1787 + 0.5, 0.5 - _1794);\n        vec2 _1875 = vec2(dot(_1782, _1671), dot(_1789, _1671));\n        vec2 _1885 = vec2(dot(_1782, _1674), dot(_1789, _1674));\n        int param_8 = _1749 + 5;\n        vec4 _1890 = fa_light_texel(param_8);\n        int param_9 = _1749 + 3;\n        vec4 _1895 = fa_light_texel(param_9);\n        int param_10 = _1749 + 4;\n        vec4 _1900 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1890.xyz;\n        bool _1910 = _1895.z > _1895.x;\n        if (_1910)\n        {\n            vec4 param_11 = _1895;\n            vec2 param_12 = _1865;\n            vec2 param_13 = _1699;\n            vec2 param_14 = _1875;\n            vec2 param_15 = _1885;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1709 > 0.5) && (_1709 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1936 = fa_dc_to_linear(param_16);\n                vec4 _5723 = tx;\n                _5723.x = _1936.x;\n                _5723.y = _1936.y;\n                _5723.z = _1936.z;\n                tx = _5723;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1857 * tex_a) * _1890.w, 0.0, 1.0)));\n        if (_1900.z > _1900.x)\n        {\n            vec4 param_17 = _1900;\n            vec2 param_18 = _1865;\n            vec2 param_19 = _1699;\n            vec2 param_20 = _1875;\n            vec2 param_21 = _1885;\n            vec4 _1980 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1709 > 1.5)\n            {\n                vec3 param_22 = _1980.xyz;\n                vec3 _1990 = fa_dc_to_srgb(param_22);\n                _1984 = _1990;\n            }\n            else\n            {\n                _1984 = _1980.xyz;\n            }\n            vec3 _1999 = (_1984 * 2.0) - vec3(1.0);\n            vec2 _2004 = _1999.xy * _1754.y;\n            vec3 _2026 = (normalize(_1782) * _2004.x) + (normalize(_1789) * _2004.y);\n            vec3 _2029 = normalize(normal);\n            normal = normalize(mix(_2029, normalize((_2029 * max(_1999.z, 0.0500000007450580596923828125)) + (_2026 - (_2029 * dot(_2029, _2026)))), vec3(clamp(_1857 * (_1910 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _388 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _391;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _391 = _388 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _391 = _388 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_391)\n        {\n            discard;\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3236 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3236;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3346 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3352 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3346 > 0.0005000000237487256526947021484375)\n    {\n        if (_3352)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3346;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3346;\n        }\n    }\n    bool _3404 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3404)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3435 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3435)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3352 || _3404) || _3435)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3256 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3259 = _3256.x;\n    float _3261 = _3256.z;\n    vec2 e = vec2(_3259, _3261);\n    if (_3256.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3261)) * ((_3259 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3259)) * ((_3261 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4291 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4296 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4301 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4306 = fa_light_texel(param_3);\n    bool _4309 = _4306.z < 0.5;\n    bool _4317;\n    if (!_4309)\n    {\n        _4317 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4317 = _4309;\n    }\n    if (_4317)\n    {\n        return vec3(0.0);\n    }\n    float _4324 = max(_4291.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4327 = _4296.xyz;\n    vec3 _4331 = _4291.xyz;\n    vec3 _4335 = (fa_world_pos - _4331) / vec3(_4324);\n    vec3 _4344 = min(_4335 + vec3(0.5), (_4327 - vec3(0.5)) - _4335);\n    float _4353 = min(_4344.x, min(_4344.y, _4344.z));\n    if (!(_4353 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4368 = _4327 - vec3(1.0);\n    vec3 _4369 = clamp(_4335, vec3(0.0), _4368);\n    vec3 _4377 = min(floor(_4369), max(_4327 - vec3(2.0), vec3(0.0)));\n    vec3 _4381 = _4369 - _4377;\n    vec3 _4393 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4324));\n    int _4398 = int(_4301.y + 0.5);\n    float _4403 = 0.3257350027561187744140625 * n.y;\n    float _4407 = 0.3257350027561187744140625 * n.z;\n    float _4411 = 0.3257350027561187744140625 * n.x;\n    float _4418 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4425 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4434 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4441 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4454 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4461 = 8 + int(_4306.w);\n    float _4488;\n    float _4501;\n    float _4515;\n    for (int k = 0; k < _4461; k++)\n    {\n        float _4474 = float(k & 1);\n        float _4478 = float((k >> 1) & 1);\n        float _4482 = float((k >> 2) & 1);\n        if (_4474 > 0.5)\n        {\n            _4488 = _4381.x;\n        }\n        else\n        {\n            _4488 = 1.0 - _4381.x;\n        }\n        if (_4478 > 0.5)\n        {\n            _4501 = _4381.y;\n        }\n        else\n        {\n            _4501 = 1.0 - _4381.y;\n        }\n        if (_4482 > 0.5)\n        {\n            _4515 = _4381.z;\n        }\n        else\n        {\n            _4515 = 1.0 - _4381.z;\n        }\n        float _4525 = (_4488 * _4501) * _4515;\n        if (!(_4525 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4538 = min(_4377 + vec3(_4474, _4478, _4482), _4368);\n        int _4558 = int(((_4301.x + _4538.x) + (_4296.x * (_4538.y + (_4296.y * _4538.z)))) + 0.5);\n        vec2 _4573 = vec2(float(_4558 % _4398) * 10.0, 1024.0 + (float(_4558 / _4398) * 11.0));\n        vec2 param_4 = _4573 + vec2(9.5, 10.5);\n        vec4 _4581 = fa_gi_fetch(param_4);\n        bool _4584 = _4581.y < 0.5;\n        bool _4593;\n        if (!_4584)\n        {\n            _4593 = _4581.x > _4306.y;\n        }\n        else\n        {\n            _4593 = _4584;\n        }\n        if (_4593)\n        {\n            continue;\n        }\n        vec3 _4605 = _4393 - (_4331 + (_4538 * _4324));\n        float _4608 = length(_4605);\n        vec3 _4614 = _4605 / vec3(max(_4608, 9.9999997473787516355514526367188e-05));\n        float _4624 = max(9.9999997473787516355514526367188e-05, (dot(-_4614, n) + 1.0) * 0.5);\n        float w = _4525 * (_4624 * _4624);\n        vec3 param_5 = _4614;\n        vec2 param_6 = (_4573 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4644 = fa_gi_fetch(param_6);\n        float _4651 = _4608 / max(_4301.z, 9.9999997473787516355514526367188e-05);\n        float _4654 = _4644.x;\n        if (_4651 > _4654)\n        {\n            float _4667 = max(_4644.y - (_4654 * _4654), 0.0);\n            float _4672 = _4651 - _4654;\n            float _4681 = _4667 / max(_4667 + (_4672 * _4672), 9.9999999600419720025001879548654e-13);\n            w *= ((_4681 * _4681) * _4681);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _4573 + vec2(0.5, 10.5);\n        vec2 param_8 = _4573 + vec2(1.5, 10.5);\n        vec2 param_9 = _4573 + vec2(2.5, 10.5);\n        vec2 param_10 = _4573 + vec2(3.5, 10.5);\n        vec2 param_11 = _4573 + vec2(4.5, 10.5);\n        vec2 param_12 = _4573 + vec2(5.5, 10.5);\n        vec2 param_13 = _4573 + vec2(6.5, 10.5);\n        vec2 param_14 = _4573 + vec2(7.5, 10.5);\n        vec2 param_15 = _4573 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4403)) + (fa_gi_fetch(param_9).xyz * _4407)) + (fa_gi_fetch(param_10).xyz * _4411)) + (fa_gi_fetch(param_11).xyz * _4418)) + (fa_gi_fetch(param_12).xyz * _4425)) + (fa_gi_fetch(param_13).xyz * _4434)) + (fa_gi_fetch(param_14).xyz * _4441)) + (fa_gi_fetch(param_15).xyz * _4454)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4353 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4808;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4808 = _4306.x;\n    }\n    else\n    {\n        _4808 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4301.w * _4808);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4832 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4837 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4842 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4842) && (k < 8); k++)\n    {\n        int param = _4837 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4832;\n        vec3 _4867 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4872 = param_3 * left;\n        acc += (_4867 * _4872);\n        left -= _4872;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4901 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _4901;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3752;\n    if (fa_lm.z > 0.5)\n    {\n        _3752 = 0.0;\n    }\n    else\n    {\n        _3752 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3763 = _3752 < 1.0;\n    bool _3769;\n    if (_3763)\n    {\n        int param = li;\n        _3769 = fa_light_baked(param);\n    }\n    else\n    {\n        _3769 = _3763;\n    }\n    return _3769 ? _3752 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _632 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _645 = (c - (ru * hx)) - p;\n        vec3 _651 = ru * (2.0 * hx);\n        float _657 = max(dot(_651, _651), 9.9999999392252902907785028219223e-09);\n        float _661 = dot(_645, _651);\n        float t = clamp((-_661) / _657, 0.0, 1.0);\n        if (_632)\n        {\n            float _676 = dot(r, _651);\n            float _682 = _657 - (_676 * _676);\n            if (abs(_682) > (9.9999997473787516355514526367188e-06 * _657))\n            {\n                t = clamp(((dot(r, _645) * _676) - _661) / _682, 0.0, 1.0);\n            }\n        }\n        return (p + _645) + (_651 * t);\n    }\n    vec3 q = p;\n    float _714 = dot(r, axis);\n    bool _722;\n    if (_632)\n    {\n        _722 = abs(_714) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _722 = _632;\n    }\n    if (_722)\n    {\n        float _732 = dot(c - p, axis) / _714;\n        if (_732 > 0.0)\n        {\n            q = p + (r * _732);\n        }\n    }\n    vec3 _745 = q - c;\n    vec2 xy = vec2(dot(_745, ru), dot(_745, uu));\n    if (shape > 0.5)\n    {\n        float _760 = length(xy);\n        if (_760 > hx)\n        {\n            xy *= (hx / _760);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _552 = dot(d, right);\n    float _556 = dot(d, up);\n    float _567;\n    if (((_552 * _552) + (_556 * _556)) > 1.0000000133514319600180897396058e-10)\n    {\n        _567 = atan(_556, _552) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _567 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_567 - floor(_567)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _408 = abs(d);\n    float _410 = _408.x;\n    float _412 = _408.y;\n    bool _413 = _410 >= _412;\n    bool _421;\n    if (_413)\n    {\n        _421 = _410 >= _408.z;\n    }\n    else\n    {\n        _421 = _413;\n    }\n    int _422;\n    if (_421)\n    {\n        _422 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _436;\n        if (_412 >= _408.z)\n        {\n            _436 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _436 = (d.z > 0.0) ? 4 : 5;\n        }\n        _422 = _436;\n    }\n    return _422;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _798 = fa_light_base(param);\n    bool _802 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _798;\n    vec4 _806 = fa_light_texel(param_1);\n    int param_2 = _798 + 1;\n    vec4 _811 = fa_light_texel(param_2);\n    float _814 = _811.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _826 = _802 && (_814 > 2.5);\n    fa_light_is_area = _826;\n    bool _828 = _814 < 0.5;\n    vec3 l;\n    if (_828)\n    {\n        l = normalize(_806.xyz);\n        if (_802)\n        {\n            int param_3 = _798 + 6;\n            vec4 _842 = fa_light_texel(param_3);\n            if (_842.z > 0.5)\n            {\n                int param_4 = _798 + 4;\n                vec4 _852 = fa_light_texel(param_4);\n                int param_5 = _798 + 5;\n                vec4 _857 = fa_light_texel(param_5);\n                vec2 param_6 = _842.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _852.xyz) * _852.w, (-dot(world_pos, _857.xyz)) * _857.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _887 = _806.xyz;\n        vec3 _889 = _887 - world_pos;\n        vec3 to_light = _889;\n        float _892 = length(_889);\n        float reach = _892;\n        bool front = true;\n        if (_826)\n        {\n            int param_8 = _798 + 7;\n            reach = max(_892 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _798 + 4;\n            vec4 _916 = fa_light_texel(param_9);\n            int param_10 = _798 + 5;\n            vec4 _921 = fa_light_texel(param_10);\n            int param_11 = _798 + 6;\n            vec4 _926 = fa_light_texel(param_11);\n            float _927 = _926.w;\n            int param_12 = _798 + 2;\n            vec3 _934 = normalize(fa_light_texel(param_12).xyz);\n            bool _936 = _927 > 1.5;\n            bool _944;\n            if (!_936)\n            {\n                _944 = dot(_934, to_light) < 0.0;\n            }\n            else\n            {\n                _944 = _936;\n            }\n            front = _944;\n            vec3 r = vec3(0.0);\n            vec3 _953 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _957 = dot(n, n) > 0.5;\n            bool _965;\n            if (_957)\n            {\n                _965 = dot(_953, _953) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _965 = _957;\n            }\n            if (_965)\n            {\n                r = reflect(-normalize(_953), normalize(n));\n            }\n            vec3 param_13 = _887;\n            vec3 param_14 = _934;\n            vec3 param_15 = _916.xyz;\n            vec3 param_16 = _921.xyz;\n            float param_17 = _916.w;\n            float param_18 = _921.w;\n            float param_19 = _927;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1001 = length(to_light);\n        dist = _1001;\n        l = to_light / vec3(max(_1001, 9.9999997473787516355514526367188e-05));\n        float _1015 = reach / max(_806.w, 0.001000000047497451305389404296875);\n        float _1021 = clamp(1.0 - (_1015 * _1015), 0.0, 1.0);\n        float _1023;\n        if (front)\n        {\n            _1023 = _1021 * _1021;\n        }\n        else\n        {\n            _1023 = 0.0;\n        }\n        atten = _1023;\n        bool _1034 = _814 < 2.5;\n        if ((_814 > 1.5) && _1034)\n        {\n            int param_22 = _798 + 2;\n            vec4 _1042 = fa_light_texel(param_22);\n            float _1052 = _1042.w;\n            int param_23 = _798 + 3;\n            vec4 _1057 = fa_light_texel(param_23);\n            float _1058 = _1057.x;\n            float cos_inner = _1058;\n            if (_1058 > 1.5)\n            {\n                cos_inner = mix(_1052, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1052, cos_inner, dot(-l, normalize(_1042.xyz)));\n        }\n        if (_802 && (_814 < 1.5))\n        {\n            int param_24 = _798 + 6;\n            vec4 _1082 = fa_light_texel(param_24);\n            if (_1082.z > 0.5)\n            {\n                vec3 _1090 = -to_light;\n                int param_25 = _798 + 4;\n                int param_26 = _798 + 5;\n                vec3 _1104 = fa_light_texel(param_25).xyz;\n                vec3 _1108 = fa_light_texel(param_26).xyz;\n                vec3 _1117 = vec3(dot(_1090, _1104), dot(_1090, _1108), dot(_1090, cross(_1104, _1108)));\n                vec3 param_27 = _1117;\n                int _1121 = fa_cube_face(param_27);\n                int param_28 = _1121;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1148 = vec2(dot(_1117, cross(param_29, param_30)), dot(_1117, param_30)) / vec2(max(dot(_1117, param_29), 9.9999997473787516355514526367188e-05));\n                int _1152 = _1121 / 3;\n                vec2 param_31 = _1082.xy + (vec2(float(_1121 - (_1152 * 3)), float(_1152)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1148.x), 0.5 - (0.5 * _1148.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _798 + 7;\n            vec4 _1182 = fa_light_texel(param_33);\n            if (_1182.z > 0.5)\n            {\n                int param_34 = _798 + 2;\n                int param_35 = _798 + 4;\n                int param_36 = _798 + 5;\n                vec2 param_37 = _1182.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_802 && _1034)\n            {\n                int param_42 = _798 + 6;\n                vec4 _1229 = fa_light_texel(param_42);\n                int param_43 = _798 + 7;\n                vec4 _1234 = fa_light_texel(param_43);\n                bool _1237 = _1229.z > 0.5;\n                bool _1244;\n                if (!_1237)\n                {\n                    _1244 = _1234.z > 0.5;\n                }\n                else\n                {\n                    _1244 = _1237;\n                }\n                if (_1244)\n                {\n                    int param_44 = _798 + 2;\n                    vec4 _1251 = fa_light_texel(param_44);\n                    vec3 _1255 = normalize(_1251.xyz);\n                    int param_45 = _798 + 4;\n                    vec4 _1260 = fa_light_texel(param_45);\n                    int param_46 = _798 + 5;\n                    vec4 _1265 = fa_light_texel(param_46);\n                    if (_1237)\n                    {\n                        vec3 _1273 = -to_light;\n                        float _1280 = _1251.w;\n                        float _1296 = 0.5 / max(dot(_1273, _1255) * (sqrt(max(1.0 - (_1280 * _1280), 0.0)) / max(_1280, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1229.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1273, _1260.xyz) * _1296), 0.5 - (dot(_1273, _1265.xyz) * _1296));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1234.z > 0.5)\n                    {\n                        vec2 param_49 = _1234.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1255;\n                        vec3 param_52 = _1260.xyz;\n                        vec3 param_53 = _1265.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5589 = _811.xyz * atten;\n    if (_802)\n    {\n        _5589 *= fa_light_tint;\n    }\n    int _1364;\n    if (_828)\n    {\n        _1364 = 0;\n    }\n    else\n    {\n        _1364 = ((_814 > 1.5) && (_814 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5589, atten, 1.0, dist, _1364);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2147 = fa_shadow_depth(param, param_1);\n    float _2151;\n    if (conv.x < 0.5)\n    {\n        _2151 = _2147;\n    }\n    else\n    {\n        _2151 = (conv.y * conv.z) / (conv.z - (_2147 * (conv.z - conv.y)));\n    }\n    return _2151;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2197 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2203 = vec2(cos(_2197), sin(_2197));\n    vec2 dir = _2203;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2212;\n        if (k < 0.0)\n        {\n            _2212 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2212 = k;\n        }\n        float _2231 = clamp((_2212 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2250 = sqrt((float(i) + 0.5) * 0.0625) * _2231;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2250));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2264 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2264 < (zr - (_2250 * plane)))\n            {\n                sum += _2264;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2292 = sum / cnt;\n        float _2302;\n        if (k < 0.0)\n        {\n            _2302 = (-k) / max(_2292, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2302 = k;\n        }\n        radius = clamp(((max(zr - _2292, 0.0) * unit) * _2302) / texel_m, 1.5, 16.0);\n        dir = _2203;\n    }\n    float lit = 0.0;\n    int _2328 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2328; i_1++)\n    {\n        float _2347 = sqrt((float(i_1) + 0.5) / float(_2328)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2347));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2347 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2328);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2552 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2559;\n    if (!_2552)\n    {\n        _2559 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2559 = _2552;\n    }\n    if (_2559)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2572 = fa_light_texel(param);\n    float _2573 = _2572.x;\n    if (_2573 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2582 = int(_2573 + 0.5);\n    int param_1 = _2582;\n    vec4 _2586 = fa_light_texel(param_1);\n    int param_2 = _2582 + 1;\n    vec4 _2591 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2594 = _2586.y;\n    if (_2594 > 0.0)\n    {\n        float _2611 = 1.0 - smoothstep(0.75 * _2594, _2594, length(world - fa_shadows[27].xyz));\n        fade = _2611;\n        if (_2611 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2586.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2635 = (_2582 + 2) + (face * 6);\n    int param_4 = _2635;\n    int param_5 = _2635 + 1;\n    int param_6 = _2635 + 3;\n    vec4 _2649 = fa_light_texel(param_6);\n    int param_7 = _2635 + 4;\n    vec4 _2654 = fa_light_texel(param_7);\n    int param_8 = _2635 + 5;\n    vec4 _2659 = fa_light_texel(param_8);\n    float _2671 = _2659.x * max(dot(_2649, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2676 = clamp(dot(n, l), 0.0, 1.0);\n    float _2699 = clamp(dot(n, _2649.xyz), -1.0, 1.0);\n    float _2718 = min(sqrt(1.0 - (_2699 * _2699)) / max(abs(dot(n, world - lpos)) / max(dot(_2649, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2721 = _2591.y;\n    float _2723;\n    if (_2721 > 0.0)\n    {\n        _2723 = _2721;\n    }\n    else\n    {\n        _2723 = 1.5 * _2671;\n    }\n    vec4 _2743 = vec4(world + (n * (_2723 * sqrt(1.0 - (_2676 * _2676)))), 1.0);\n    float _2747 = dot(_2649, _2743);\n    float _2750 = _2659.y;\n    if (_2747 < _2750)\n    {\n        return 1.0;\n    }\n    vec2 _2765 = vec2(dot(fa_light_texel(param_4), _2743), dot(fa_light_texel(param_5), _2743)) / vec2(_2747);\n    float _2767 = _2765.x;\n    bool _2770 = _2767 < _2654.x;\n    bool _2779;\n    if (!_2770)\n    {\n        _2779 = _2767 > _2654.z;\n    }\n    else\n    {\n        _2779 = _2770;\n    }\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2765.y < _2654.y;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    bool _2797;\n    if (!_2788)\n    {\n        _2797 = _2765.y > _2654.w;\n    }\n    else\n    {\n        _2797 = _2788;\n    }\n    if (_2797)\n    {\n        return 1.0;\n    }\n    float _2803 = _2591.x;\n    float _2805;\n    if (_2803 > 0.0)\n    {\n        _2805 = _2803;\n    }\n    else\n    {\n        _2805 = 1.5 * _2671;\n    }\n    vec2 param_9 = _2765;\n    vec4 param_10 = _2654;\n    float param_11 = _2747 - (_2805 * (1.0 + (0.5 * _2718)));\n    float param_12 = _2671;\n    float param_13 = 1.0;\n    float param_14 = _2659.z * 0.25;\n    float param_15 = (_2671 * min(_2718, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2750, _2659.z);\n    int param_17 = int(_2586.z + 0.5);\n    float param_18 = _2586.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2090;\n    if (i == 0)\n    {\n        _2090 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2106;\n        if (i == 1)\n        {\n            _2106 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2114;\n            if (i == 2)\n            {\n                _2114 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2114 = fa_shadows[24].w;\n            }\n            _2106 = _2114;\n        }\n        _2090 = _2106;\n    }\n    return _2090;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2393 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2398 = clamp(dot(n, l), 0.0, 1.0);\n    float _2404 = sqrt(1.0 - (_2398 * _2398));\n    float _2412 = min(_2404 / max(_2398, 0.20000000298023223876953125), 4.0);\n    float _2417;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2417 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2417 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2442 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2417 * _2404)), 1.0);\n    float _2449 = _2442.x;\n    bool _2452 = _2449 < fa_shadows[ci * 1 + 16].x;\n    bool _2461;\n    if (!_2452)\n    {\n        _2461 = _2449 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2461 = _2452;\n    }\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2442.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2479;\n    if (!_2470)\n    {\n        _2479 = _2442.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2479 = _2470;\n    }\n    bool _2486;\n    if (!_2479)\n    {\n        _2486 = _2442.z > 1.0;\n    }\n    else\n    {\n        _2486 = _2479;\n    }\n    if (_2486)\n    {\n        return -1.0;\n    }\n    float _2494;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2494 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2494 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2442.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2442.z - ((_2494 * (1.0 + (0.5 * _2412))) / _2393);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2393;\n    float param_5 = _2393 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2412, 3.0)) * 0.5) / _2393;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2872 = int(fa_shadows[25].x + 0.5);\n    if (_2872 < 1)\n    {\n        return 1.0;\n    }\n    float _2887 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2872 - 1;\n    if (_2887 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2899 = _2872 > 1;\n    bool _2906;\n    if (_2899)\n    {\n        _2906 = _2887 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2906 = _2899;\n    }\n    if (_2906)\n    {\n        ci = 1;\n    }\n    bool _2910 = _2872 > 2;\n    bool _2917;\n    if (_2910)\n    {\n        _2917 = _2887 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2917 = _2910;\n    }\n    if (_2917)\n    {\n        ci = 2;\n    }\n    bool _2921 = _2872 > 3;\n    bool _2928;\n    if (_2921)\n    {\n        _2928 = _2887 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2928 = _2921;\n    }\n    if (_2928)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2939 = min(_2872, 4);\n    float _2980;\n    for (int c = ci; c < _2939; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2959 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2959;\n            break;\n        }\n        if (_2959 < 0.0)\n        {\n            continue;\n        }\n        s = _2959;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2980 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2980 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2999 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2980, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2887 - (fa_shadow_split_at(param_7) - _2999)) / _2999, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3031;\n        if ((ci + 1) < _2872)\n        {\n            _3031 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3031 = 1.0;\n        }\n        s = mix(s, _3031, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3486 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3493;\n    if (!_3486)\n    {\n        _3493 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3493 = _3486;\n    }\n    if (_3493)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3506 = fa_light_texel(param);\n    float _3507 = _3506.y;\n    float len = _3507;\n    if (_3507 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3519 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3529 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3519);\n    if (_3529 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3535 = len;\n    float _3538 = min(_3535, 0.89999997615814208984375 * dist);\n    len = _3538;\n    float _3544 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3519);\n    float _3549 = _3544 + (0.5 * _3538);\n    vec3 _3555 = world + (gn * _3544);\n    float _3557 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3622;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3573 = (float(k) + _3557) * 0.083333335816860198974609375;\n        vec3 _3581 = _3555 + (l * (_3573 * len));\n        vec4 _3587 = vec4(_3581, 1.0);\n        float _3593 = dot(fa_mesh_fs_params[28], _3587);\n        if (_3593 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3613 = vec2(dot(fa_mesh_fs_params[26], _3587), dot(fa_mesh_fs_params[27], _3587)) / vec2(_3593);\n        float _3617 = _3613.x * 0.5;\n        float _3618 = _3617 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3622 = (_3613.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3622 = 0.5 - (_3613.y * 0.5);\n        }\n        bool _3638 = _3618 < 0.0;\n        bool _3645;\n        if (!_3638)\n        {\n            _3645 = _3618 >= 1.0;\n        }\n        else\n        {\n            _3645 = _3638;\n        }\n        bool _3652;\n        if (!_3645)\n        {\n            _3652 = _3622 < 0.0;\n        }\n        else\n        {\n            _3652 = _3645;\n        }\n        bool _3659;\n        if (!_3652)\n        {\n            _3659 = _3622 >= 1.0;\n        }\n        else\n        {\n            _3659 = _3652;\n        }\n        if (_3659)\n        {\n            break;\n        }\n        vec4 _3686 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3618, _3622) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_3686.w < 0.5)\n        {\n            continue;\n        }\n        float _3705 = (dot(fa_mesh_fs_params[29].xyz, _3581) + fa_mesh_fs_params[29].w) - _3686.x;\n        if ((_3705 > _3544) && (_3705 < _3549))\n        {\n            occ = max(occ, (1.0 - (_3573 * _3573)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3618, 0.5 - _3617), min(_3622, 1.0 - _3622))));\n        }\n    }\n    return 1.0 - (occ * _3529);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3808 = fa_baked_keep(param);\n    if (_3808 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3834 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5615 = _3834.color;\n    float _5616 = _3834.attenuation;\n    float _5617 = _3834.shadow;\n    bool _3837 = _3834.type == 0;\n    if (_3837 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3834.direction;\n        float _3848 = fa_shadow_factor(param_5, param_6);\n        _5617 = _3848;\n        _5615 *= _3848;\n    }\n    else\n    {\n        bool _3859 = _3834.type != 0;\n        bool _3865;\n        if (_3859)\n        {\n            _3865 = _5616 > 0.0;\n        }\n        else\n        {\n            _3865 = _3859;\n        }\n        if (_3865)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3834.direction;\n            float _3884 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5617 = _3884;\n            _5615 *= _3884;\n        }\n    }\n    bool _3894 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3900;\n    if (_3894)\n    {\n        _3900 = _5616 > 0.0;\n    }\n    else\n    {\n        _3900 = _3894;\n    }\n    if (_3900)\n    {\n        float _3907;\n        if (_3837)\n        {\n            _3907 = 1000000000.0;\n        }\n        else\n        {\n            _3907 = _3834._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3834.direction;\n        float param_18 = _3907;\n        float _3925 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5617 *= _3925;\n        _5615 *= _3925;\n    }\n    float _3938 = _5616;\n    float _3939 = _3938 * _3808;\n    _5616 = _3939;\n    vec3 _3943 = _5615;\n    vec3 _3944 = _3943 * _3808;\n    _5615 = _3944;\n    return LightSample(_3834.direction, _3944, _3939, _5617, _3834._distance, _3834.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3059 = int(fa_shadows[25].x + 0.5);\n    float _3069 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3074 = _3059 > 0;\n    bool _3083;\n    if (_3074)\n    {\n        int param = _3059 - 1;\n        _3083 = _3069 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3083 = _3074;\n    }\n    if (_3083)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3089 = _3059 > 1;\n        bool _3096;\n        if (_3089)\n        {\n            _3096 = _3069 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3096 = _3089;\n        }\n        if (_3096)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3102 = _3059 > 2;\n        bool _3109;\n        if (_3102)\n        {\n            _3109 = _3069 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3109 = _3102;\n        }\n        if (_3109)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3115 = _3059 > 3;\n        bool _3122;\n        if (_3115)\n        {\n            _3122 = _3069 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3122 = _3115;\n        }\n        if (_3122)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5436 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5436 = -_5436;\n    }\n    vec3 _5009 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5436, fa_world_tangent, fa_uv, fa_vertex_color, _5009, gl_FrontFacing);\n    Surface _5017 = fa_standard_surface(param_1);\n    vec3 _5467 = _5017.albedo;\n    float _5468 = _5017.alpha;\n    vec3 _5469 = _5017.normal;\n    float _5470 = _5017.metallic;\n    float _5471 = _5017.roughness;\n    float _5472 = _5017.occlusion;\n    vec3 _5473 = _5017.emission;\n    float _5474 = _5017.clearcoat;\n    float _5475 = _5017.clearcoat_roughness;\n    vec3 _5476 = _5017.sheen_color;\n    float _5477 = _5017.sheen_roughness;\n    float _5478 = _5017.anisotropy;\n    float _5479 = _5017.anisotropy_rotation;\n    float _5480 = _5017.specular;\n    float _5481 = _5017.ior;\n    vec3 _5482 = _5017.specular_color;\n    float _5483 = _5017.transmission;\n    float _5484 = _5017.thickness;\n    vec3 _5485 = _5017.attenuation_color;\n    float _5486 = _5017.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5436, fa_world_tangent, fa_uv, fa_vertex_color, _5009, gl_FrontFacing);\n    Surface param_3 = _5017;\n    surface(param_2, param_3);\n    _5467 = param_3.albedo;\n    _5468 = param_3.alpha;\n    _5469 = param_3.normal;\n    _5470 = param_3.metallic;\n    _5471 = param_3.roughness;\n    _5472 = param_3.occlusion;\n    _5473 = param_3.emission;\n    _5474 = param_3.clearcoat;\n    _5475 = param_3.clearcoat_roughness;\n    _5476 = param_3.sheen_color;\n    _5477 = param_3.sheen_roughness;\n    _5478 = param_3.anisotropy;\n    _5479 = param_3.anisotropy_rotation;\n    _5480 = param_3.specular;\n    _5481 = param_3.ior;\n    _5482 = param_3.specular_color;\n    _5483 = param_3.transmission;\n    _5484 = param_3.thickness;\n    _5485 = param_3.attenuation_color;\n    _5486 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5436;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5467 = param_6;\n    _5469 = param_7;\n    fa_lod_dither();\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5467;\n    }\n    else\n    {\n        vec3 _5057 = _5469;\n        vec3 _5058 = normalize(_5057);\n        _5469 = _5058;\n        vec3 param_8 = _5058;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _5467) * _5472;\n        int _5077 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5077; ln++)\n        {\n            int param_9 = ln;\n            int _5090 = fa_cl_light(param_9);\n            int param_10 = _5090;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5090;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5436;\n            LightSample _5106 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5436, fa_world_tangent, fa_uv, fa_vertex_color, _5009, gl_FrontFacing);\n            Surface param_15 = Surface(_5467, _5468, _5469, _5470, _5471, _5472, _5473, _5474, _5475, _5476, _5477, _5478, _5479, _5480, _5481, _5482, _5483, _5484, _5485, _5486);\n            LightSample param_16 = _5106;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5121 = result;\n    vec3 _5122 = _5121 + _5473;\n    result = _5122;\n    vec3 param_17 = _5122;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5131 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5138;\n    if (!_5131)\n    {\n        _5138 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5138 = _5131;\n    }\n    if (_5138)\n    {\n        vec3 _5147 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5153 = dot(_5147, fa_mesh_fs_params[9].xyz);\n        bool _5157 = fa_mesh_fs_params[9].w > 0.5;\n        float _5158;\n        if (_5157)\n        {\n            _5158 = _5153;\n        }\n        else\n        {\n            _5158 = length(_5147);\n        }\n        float _5170 = _5158 - fa_mesh_fs_params[8].x;\n        if (_5170 > 0.0)\n        {\n            float _5179 = fa_mesh_fs_params[7].w * _5170;\n            float tau = _5179 * _5179;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5195;\n                if (_5157)\n                {\n                    _5195 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5153);\n                }\n                else\n                {\n                    _5195 = fa_mesh_fs_params[0].y;\n                }\n                float _5216 = mix(_5195, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5158, 0.0, 1.0));\n                float _5220 = fa_world_pos.y - _5216;\n                float _5225 = _5216 - fa_mesh_fs_params[8].z;\n                float _5230 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5233 = _5225 <= 0.0;\n                bool _5234 = !_5233;\n                bool _5240;\n                if (_5234)\n                {\n                    _5240 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5240 = _5233;\n                }\n                float _5241;\n                if (_5240)\n                {\n                    _5241 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5241 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5225, 80.0));\n                }\n                bool _5268;\n                if (_5234)\n                {\n                    _5268 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5268 = _5233;\n                }\n                float _5269;\n                if (_5268)\n                {\n                    _5269 = fa_mesh_fs_params[8].y * _5225;\n                }\n                else\n                {\n                    _5269 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5225, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5294 = _5230 <= 0.0;\n                bool _5301;\n                if (!_5294)\n                {\n                    _5301 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5301 = _5294;\n                }\n                float _5302;\n                if (_5301)\n                {\n                    _5302 = fa_mesh_fs_params[8].y * _5230;\n                }\n                else\n                {\n                    _5302 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5230, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5329;\n                if (abs(_5220) < 0.001000000047497451305389404296875)\n                {\n                    _5329 = _5241;\n                }\n                else\n                {\n                    _5329 = (_5302 - _5269) / _5220;\n                }\n                tau += (_5170 * max(_5329, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5468);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_366",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2100",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1382 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1389;\n    if (!_1382)\n    {\n        _1389 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1389 = _1382;\n    }\n    bool _1397;\n    if (!_1389)\n    {\n        _1397 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1397 = _1389;\n    }\n    bool _1404;\n    if (!_1397)\n    {\n        _1404 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1404 = _1397;\n    }\n    bool _1411;\n    if (!_1404)\n    {\n        _1411 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1411 = _1404;\n    }\n    if (_1411)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1421 = vec4(world_pos, 1.0);\n    float _1427 = dot(fa_mesh_fs_params[16], _1421);\n    if (!(_1427 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1449 = vec2(dot(fa_mesh_fs_params[14], _1421), dot(fa_mesh_fs_params[15], _1421)) / vec2(_1427);\n    int _1453 = int(fa_mesh_fs_params[18].x);\n    int _1457 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1457) + clamp(int(floor(((_1449.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1457 - 1)) * _1453)) + clamp(int(floor(((_1449.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1453 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1533 = fa_cluster_texel(param);\n    return ivec2(int(_1533.x), int(_1533.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3782 = fa_cluster_lookup(param);\n    fa_cl_slot = _3782.x;\n    fa_cl_local = _3782.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3987 = fa_linear_to_srgb(param);\n        c = _3987;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3995 = fa_srgb_to_linear(param_1);\n            c = _3995;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _298;\n    if (i.front_facing)\n    {\n        _298 = i.world_normal;\n    }\n    else\n    {\n        _298 = -i.world_normal;\n    }\n    vec3 _322 = normalize(i.world_tangent.xyz - (_298 * dot(_298, i.world_tangent.xyz)));\n    vec3 _349 = normalize(((_322 * m.x) + ((cross(_298, _322) * i.world_tangent.w) * m.y)) + (_298 * m.z));\n    vec3 _352;\n    if (i.front_facing)\n    {\n        _352 = _349;\n    }\n    else\n    {\n        _352 = -_349;\n    }\n    return _352;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4026 = fa_tex_fix(param_2, param_3);\n    vec4 _5798 = base_t;\n    _5798.x = _4026.x;\n    _5798.y = _4026.y;\n    _5798.z = _4026.z;\n    base_t = _5798;\n    vec4 _4040 = (_5798 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5635 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4072 = fa_tex_fix(param_6, param_7);\n        vec3 _4075 = (_4072 * 2.0) - vec3(1.0);\n        vec2 _4080 = _4075.xy * fa_mesh_fs_params[6].x;\n        vec3 _5806 = _4075;\n        _5806.x = _4080.x;\n        _5806.y = _4080.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5806;\n        _5635 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4108 = fa_tex_fix(param_12, param_13);\n    vec4 _5809 = mrt;\n    _5809.x = _4108.x;\n    _5809.y = _4108.y;\n    _5809.z = _4108.z;\n    mrt = _5809;\n    vec4 _4136 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4136.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4147 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4177 = fa_tex_fix(param_20, param_21);\n    float _5640 = fa_mesh_fs_params[20].x;\n    float _5641 = fa_mesh_fs_params[20].y;\n    float _5644 = fa_mesh_fs_params[20].z;\n    float _5643 = fa_mesh_fs_params[21].w;\n    float _5646 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5640 *= _4147.y;\n            _5641 *= _4147.z;\n            _5643 *= _4136.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5644 *= mrt.x;\n            _5646 *= mrt.w;\n        }\n    }\n    return Surface(_4040.xyz, _4040.w, _5635, clamp(fa_mesh_fs_params[5].x * _4108.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4108.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4147.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4177), _5640, _5641, fa_mesh_fs_params[21].xyz, _5643, _5644, fa_mesh_fs_params[20].w, _5646, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1613 = rect.zw - rect.xy;\n    vec2 _1617 = _1613 * atlas;\n    vec2 _1621 = ddx * _1617;\n    vec2 _1625 = ddy * _1617;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1613), clamp(0.5 * log2(max(max(dot(_1621, _1621), dot(_1625, _1625)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1658 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1665;\n    if (!_1658)\n    {\n        _1665 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1665 = _1658;\n    }\n    if (_1665)\n    {\n        return;\n    }\n    vec3 _1671 = dFdx(world_pos);\n    vec3 _1674 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1678 = fa_cluster_texel(param);\n    int _1682 = int(_1678.w);\n    if (_1682 < 1)\n    {\n        return;\n    }\n    int _1692 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1692;\n    vec4 _1696 = fa_light_texel(param_1);\n    vec2 _1699 = _1696.yz;\n    int _1703 = int(_1696.w);\n    int param_2 = _1692 + 1;\n    vec4 _1708 = fa_light_texel(param_2);\n    float _1709 = _1708.x;\n    int _1715 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1719 = int(_1678.z);\n    vec3 _1984;\n    for (int k = 0; k < _1682; k++)\n    {\n        int _1732 = _1719 + k;\n        int param_3 = _1703 + (_1732 >> 2);\n        int _1749 = (_1692 + 2) + (int(fa_light_texel(param_3)[_1732 & 3]) * 7);\n        int param_4 = _1749 + 6;\n        vec4 _1754 = fa_light_texel(param_4);\n        if (((int(_1754.w + 0.5) >> _1715) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1749;\n        vec4 _1769 = fa_light_texel(param_5);\n        int param_6 = _1749 + 1;\n        vec4 _1774 = fa_light_texel(param_6);\n        int param_7 = _1749 + 2;\n        vec4 _1779 = fa_light_texel(param_7);\n        vec3 _1782 = _1769.xyz;\n        float _1787 = dot(_1782, world_pos) + _1769.w;\n        vec3 _1789 = _1774.xyz;\n        float _1794 = dot(_1789, world_pos) + _1774.w;\n        vec3 _1796 = _1779.xyz;\n        float _1801 = dot(_1796, world_pos) + _1779.w;\n        bool _1806 = abs(_1787) > 0.5;\n        bool _1814;\n        if (!_1806)\n        {\n            _1814 = abs(_1794) > 0.5;\n        }\n        else\n        {\n            _1814 = _1806;\n        }\n        bool _1822;\n        if (!_1814)\n        {\n            _1822 = abs(_1801) > 0.5;\n        }\n        else\n        {\n            _1822 = _1814;\n        }\n        if (_1822)\n        {\n            continue;\n        }\n        float _1837 = clamp(dot(geo_normal, normalize(_1796)) * _1754.z, 0.0, 1.0);\n        if (_1837 <= 0.0)\n        {\n            continue;\n        }\n        float _1857 = (clamp((0.5 - abs(_1801)) * 10.0, 0.0, 1.0) * _1837) * _1754.x;\n        vec2 _1865 = vec2(_1787 + 0.5, 0.5 - _1794);\n        vec2 _1875 = vec2(dot(_1782, _1671), dot(_1789, _1671));\n        vec2 _1885 = vec2(dot(_1782, _1674), dot(_1789, _1674));\n        int param_8 = _1749 + 5;\n        vec4 _1890 = fa_light_texel(param_8);\n        int param_9 = _1749 + 3;\n        vec4 _1895 = fa_light_texel(param_9);\n        int param_10 = _1749 + 4;\n        vec4 _1900 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1890.xyz;\n        bool _1910 = _1895.z > _1895.x;\n        if (_1910)\n        {\n            vec4 param_11 = _1895;\n            vec2 param_12 = _1865;\n            vec2 param_13 = _1699;\n            vec2 param_14 = _1875;\n            vec2 param_15 = _1885;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1709 > 0.5) && (_1709 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1936 = fa_dc_to_linear(param_16);\n                vec4 _5723 = tx;\n                _5723.x = _1936.x;\n                _5723.y = _1936.y;\n                _5723.z = _1936.z;\n                tx = _5723;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1857 * tex_a) * _1890.w, 0.0, 1.0)));\n        if (_1900.z > _1900.x)\n        {\n            vec4 param_17 = _1900;\n            vec2 param_18 = _1865;\n            vec2 param_19 = _1699;\n            vec2 param_20 = _1875;\n            vec2 param_21 = _1885;\n            vec4 _1980 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1709 > 1.5)\n            {\n                vec3 param_22 = _1980.xyz;\n                vec3 _1990 = fa_dc_to_srgb(param_22);\n                _1984 = _1990;\n            }\n            else\n            {\n                _1984 = _1980.xyz;\n            }\n            vec3 _1999 = (_1984 * 2.0) - vec3(1.0);\n            vec2 _2004 = _1999.xy * _1754.y;\n            vec3 _2026 = (normalize(_1782) * _2004.x) + (normalize(_1789) * _2004.y);\n            vec3 _2029 = normalize(normal);\n            normal = normalize(mix(_2029, normalize((_2029 * max(_1999.z, 0.0500000007450580596923828125)) + (_2026 - (_2029 * dot(_2029, _2026)))), vec3(clamp(_1857 * (_1910 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _388 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _391;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _391 = _388 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _391 = _388 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_391)\n        {\n            discard;\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3236 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3236;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3346 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3352 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3346 > 0.0005000000237487256526947021484375)\n    {\n        if (_3352)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3346;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3346;\n        }\n    }\n    bool _3404 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3404)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3435 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3435)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3352 || _3404) || _3435)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3256 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3259 = _3256.x;\n    float _3261 = _3256.z;\n    vec2 e = vec2(_3259, _3261);\n    if (_3256.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3261)) * ((_3259 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3259)) * ((_3261 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _4291 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _4296 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _4301 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _4306 = fa_light_texel(param_3);\n    bool _4309 = _4306.z < 0.5;\n    bool _4317;\n    if (!_4309)\n    {\n        _4317 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _4317 = _4309;\n    }\n    if (_4317)\n    {\n        return vec3(0.0);\n    }\n    float _4324 = max(_4291.w, 9.9999997473787516355514526367188e-05);\n    vec3 _4327 = _4296.xyz;\n    vec3 _4331 = _4291.xyz;\n    vec3 _4335 = (fa_world_pos - _4331) / vec3(_4324);\n    vec3 _4344 = min(_4335 + vec3(0.5), (_4327 - vec3(0.5)) - _4335);\n    float _4353 = min(_4344.x, min(_4344.y, _4344.z));\n    if (!(_4353 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _4368 = _4327 - vec3(1.0);\n    vec3 _4369 = clamp(_4335, vec3(0.0), _4368);\n    vec3 _4377 = min(floor(_4369), max(_4327 - vec3(2.0), vec3(0.0)));\n    vec3 _4381 = _4369 - _4377;\n    vec3 _4393 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _4324));\n    int _4398 = int(_4301.y + 0.5);\n    float _4403 = 0.3257350027561187744140625 * n.y;\n    float _4407 = 0.3257350027561187744140625 * n.z;\n    float _4411 = 0.3257350027561187744140625 * n.x;\n    float _4418 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _4425 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _4434 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _4441 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _4454 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _4461 = 8 + int(_4306.w);\n    float _4488;\n    float _4501;\n    float _4515;\n    for (int k = 0; k < _4461; k++)\n    {\n        float _4474 = float(k & 1);\n        float _4478 = float((k >> 1) & 1);\n        float _4482 = float((k >> 2) & 1);\n        if (_4474 > 0.5)\n        {\n            _4488 = _4381.x;\n        }\n        else\n        {\n            _4488 = 1.0 - _4381.x;\n        }\n        if (_4478 > 0.5)\n        {\n            _4501 = _4381.y;\n        }\n        else\n        {\n            _4501 = 1.0 - _4381.y;\n        }\n        if (_4482 > 0.5)\n        {\n            _4515 = _4381.z;\n        }\n        else\n        {\n            _4515 = 1.0 - _4381.z;\n        }\n        float _4525 = (_4488 * _4501) * _4515;\n        if (!(_4525 > 0.0))\n        {\n            continue;\n        }\n        vec3 _4538 = min(_4377 + vec3(_4474, _4478, _4482), _4368);\n        int _4558 = int(((_4301.x + _4538.x) + (_4296.x * (_4538.y + (_4296.y * _4538.z)))) + 0.5);\n        vec2 _4573 = vec2(float(_4558 % _4398) * 10.0, 1024.0 + (float(_4558 / _4398) * 11.0));\n        vec2 param_4 = _4573 + vec2(9.5, 10.5);\n        vec4 _4581 = fa_gi_fetch(param_4);\n        bool _4584 = _4581.y < 0.5;\n        bool _4593;\n        if (!_4584)\n        {\n            _4593 = _4581.x > _4306.y;\n        }\n        else\n        {\n            _4593 = _4584;\n        }\n        if (_4593)\n        {\n            continue;\n        }\n        vec3 _4605 = _4393 - (_4331 + (_4538 * _4324));\n        float _4608 = length(_4605);\n        vec3 _4614 = _4605 / vec3(max(_4608, 9.9999997473787516355514526367188e-05));\n        float _4624 = max(9.9999997473787516355514526367188e-05, (dot(-_4614, n) + 1.0) * 0.5);\n        float w = _4525 * (_4624 * _4624);\n        vec3 param_5 = _4614;\n        vec2 param_6 = (_4573 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _4644 = fa_gi_fetch(param_6);\n        float _4651 = _4608 / max(_4301.z, 9.9999997473787516355514526367188e-05);\n        float _4654 = _4644.x;\n        if (_4651 > _4654)\n        {\n            float _4667 = max(_4644.y - (_4654 * _4654), 0.0);\n            float _4672 = _4651 - _4654;\n            float _4681 = _4667 / max(_4667 + (_4672 * _4672), 9.9999999600419720025001879548654e-13);\n            w *= ((_4681 * _4681) * _4681);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _4573 + vec2(0.5, 10.5);\n        vec2 param_8 = _4573 + vec2(1.5, 10.5);\n        vec2 param_9 = _4573 + vec2(2.5, 10.5);\n        vec2 param_10 = _4573 + vec2(3.5, 10.5);\n        vec2 param_11 = _4573 + vec2(4.5, 10.5);\n        vec2 param_12 = _4573 + vec2(5.5, 10.5);\n        vec2 param_13 = _4573 + vec2(6.5, 10.5);\n        vec2 param_14 = _4573 + vec2(7.5, 10.5);\n        vec2 param_15 = _4573 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _4403)) + (fa_gi_fetch(param_9).xyz * _4407)) + (fa_gi_fetch(param_10).xyz * _4411)) + (fa_gi_fetch(param_11).xyz * _4418)) + (fa_gi_fetch(param_12).xyz * _4425)) + (fa_gi_fetch(param_13).xyz * _4434)) + (fa_gi_fetch(param_14).xyz * _4441)) + (fa_gi_fetch(param_15).xyz * _4454)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_4353 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _4808;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _4808 = _4306.x;\n    }\n    else\n    {\n        _4808 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_4301.w * _4808);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _4832 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _4837 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _4842 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _4842) && (k < 8); k++)\n    {\n        int param = _4837 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _4832;\n        vec3 _4867 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _4872 = param_3 * left;\n        acc += (_4867 * _4872);\n        left -= _4872;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _4901 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _4901;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3752;\n    if (fa_lm.z > 0.5)\n    {\n        _3752 = 0.0;\n    }\n    else\n    {\n        _3752 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _3763 = _3752 < 1.0;\n    bool _3769;\n    if (_3763)\n    {\n        int param = li;\n        _3769 = fa_light_baked(param);\n    }\n    else\n    {\n        _3769 = _3763;\n    }\n    return _3769 ? _3752 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _632 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _645 = (c - (ru * hx)) - p;\n        vec3 _651 = ru * (2.0 * hx);\n        float _657 = max(dot(_651, _651), 9.9999999392252902907785028219223e-09);\n        float _661 = dot(_645, _651);\n        float t = clamp((-_661) / _657, 0.0, 1.0);\n        if (_632)\n        {\n            float _676 = dot(r, _651);\n            float _682 = _657 - (_676 * _676);\n            if (abs(_682) > (9.9999997473787516355514526367188e-06 * _657))\n            {\n                t = clamp(((dot(r, _645) * _676) - _661) / _682, 0.0, 1.0);\n            }\n        }\n        return (p + _645) + (_651 * t);\n    }\n    vec3 q = p;\n    float _714 = dot(r, axis);\n    bool _722;\n    if (_632)\n    {\n        _722 = abs(_714) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _722 = _632;\n    }\n    if (_722)\n    {\n        float _732 = dot(c - p, axis) / _714;\n        if (_732 > 0.0)\n        {\n            q = p + (r * _732);\n        }\n    }\n    vec3 _745 = q - c;\n    vec2 xy = vec2(dot(_745, ru), dot(_745, uu));\n    if (shape > 0.5)\n    {\n        float _760 = length(xy);\n        if (_760 > hx)\n        {\n            xy *= (hx / _760);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _552 = dot(d, right);\n    float _556 = dot(d, up);\n    float _567;\n    if (((_552 * _552) + (_556 * _556)) > 1.0000000133514319600180897396058e-10)\n    {\n        _567 = atan(_556, _552) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _567 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_567 - floor(_567)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _408 = abs(d);\n    float _410 = _408.x;\n    float _412 = _408.y;\n    bool _413 = _410 >= _412;\n    bool _421;\n    if (_413)\n    {\n        _421 = _410 >= _408.z;\n    }\n    else\n    {\n        _421 = _413;\n    }\n    int _422;\n    if (_421)\n    {\n        _422 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _436;\n        if (_412 >= _408.z)\n        {\n            _436 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _436 = (d.z > 0.0) ? 4 : 5;\n        }\n        _422 = _436;\n    }\n    return _422;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _798 = fa_light_base(param);\n    bool _802 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _798;\n    vec4 _806 = fa_light_texel(param_1);\n    int param_2 = _798 + 1;\n    vec4 _811 = fa_light_texel(param_2);\n    float _814 = _811.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _826 = _802 && (_814 > 2.5);\n    fa_light_is_area = _826;\n    bool _828 = _814 < 0.5;\n    vec3 l;\n    if (_828)\n    {\n        l = normalize(_806.xyz);\n        if (_802)\n        {\n            int param_3 = _798 + 6;\n            vec4 _842 = fa_light_texel(param_3);\n            if (_842.z > 0.5)\n            {\n                int param_4 = _798 + 4;\n                vec4 _852 = fa_light_texel(param_4);\n                int param_5 = _798 + 5;\n                vec4 _857 = fa_light_texel(param_5);\n                vec2 param_6 = _842.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _852.xyz) * _852.w, (-dot(world_pos, _857.xyz)) * _857.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _887 = _806.xyz;\n        vec3 _889 = _887 - world_pos;\n        vec3 to_light = _889;\n        float _892 = length(_889);\n        float reach = _892;\n        bool front = true;\n        if (_826)\n        {\n            int param_8 = _798 + 7;\n            reach = max(_892 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _798 + 4;\n            vec4 _916 = fa_light_texel(param_9);\n            int param_10 = _798 + 5;\n            vec4 _921 = fa_light_texel(param_10);\n            int param_11 = _798 + 6;\n            vec4 _926 = fa_light_texel(param_11);\n            float _927 = _926.w;\n            int param_12 = _798 + 2;\n            vec3 _934 = normalize(fa_light_texel(param_12).xyz);\n            bool _936 = _927 > 1.5;\n            bool _944;\n            if (!_936)\n            {\n                _944 = dot(_934, to_light) < 0.0;\n            }\n            else\n            {\n                _944 = _936;\n            }\n            front = _944;\n            vec3 r = vec3(0.0);\n            vec3 _953 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _957 = dot(n, n) > 0.5;\n            bool _965;\n            if (_957)\n            {\n                _965 = dot(_953, _953) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _965 = _957;\n            }\n            if (_965)\n            {\n                r = reflect(-normalize(_953), normalize(n));\n            }\n            vec3 param_13 = _887;\n            vec3 param_14 = _934;\n            vec3 param_15 = _916.xyz;\n            vec3 param_16 = _921.xyz;\n            float param_17 = _916.w;\n            float param_18 = _921.w;\n            float param_19 = _927;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1001 = length(to_light);\n        dist = _1001;\n        l = to_light / vec3(max(_1001, 9.9999997473787516355514526367188e-05));\n        float _1015 = reach / max(_806.w, 0.001000000047497451305389404296875);\n        float _1021 = clamp(1.0 - (_1015 * _1015), 0.0, 1.0);\n        float _1023;\n        if (front)\n        {\n            _1023 = _1021 * _1021;\n        }\n        else\n        {\n            _1023 = 0.0;\n        }\n        atten = _1023;\n        bool _1034 = _814 < 2.5;\n        if ((_814 > 1.5) && _1034)\n        {\n            int param_22 = _798 + 2;\n            vec4 _1042 = fa_light_texel(param_22);\n            float _1052 = _1042.w;\n            int param_23 = _798 + 3;\n            vec4 _1057 = fa_light_texel(param_23);\n            float _1058 = _1057.x;\n            float cos_inner = _1058;\n            if (_1058 > 1.5)\n            {\n                cos_inner = mix(_1052, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1052, cos_inner, dot(-l, normalize(_1042.xyz)));\n        }\n        if (_802 && (_814 < 1.5))\n        {\n            int param_24 = _798 + 6;\n            vec4 _1082 = fa_light_texel(param_24);\n            if (_1082.z > 0.5)\n            {\n                vec3 _1090 = -to_light;\n                int param_25 = _798 + 4;\n                int param_26 = _798 + 5;\n                vec3 _1104 = fa_light_texel(param_25).xyz;\n                vec3 _1108 = fa_light_texel(param_26).xyz;\n                vec3 _1117 = vec3(dot(_1090, _1104), dot(_1090, _1108), dot(_1090, cross(_1104, _1108)));\n                vec3 param_27 = _1117;\n                int _1121 = fa_cube_face(param_27);\n                int param_28 = _1121;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1148 = vec2(dot(_1117, cross(param_29, param_30)), dot(_1117, param_30)) / vec2(max(dot(_1117, param_29), 9.9999997473787516355514526367188e-05));\n                int _1152 = _1121 / 3;\n                vec2 param_31 = _1082.xy + (vec2(float(_1121 - (_1152 * 3)), float(_1152)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1148.x), 0.5 - (0.5 * _1148.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _798 + 7;\n            vec4 _1182 = fa_light_texel(param_33);\n            if (_1182.z > 0.5)\n            {\n                int param_34 = _798 + 2;\n                int param_35 = _798 + 4;\n                int param_36 = _798 + 5;\n                vec2 param_37 = _1182.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_802 && _1034)\n            {\n                int param_42 = _798 + 6;\n                vec4 _1229 = fa_light_texel(param_42);\n                int param_43 = _798 + 7;\n                vec4 _1234 = fa_light_texel(param_43);\n                bool _1237 = _1229.z > 0.5;\n                bool _1244;\n                if (!_1237)\n                {\n                    _1244 = _1234.z > 0.5;\n                }\n                else\n                {\n                    _1244 = _1237;\n                }\n                if (_1244)\n                {\n                    int param_44 = _798 + 2;\n                    vec4 _1251 = fa_light_texel(param_44);\n                    vec3 _1255 = normalize(_1251.xyz);\n                    int param_45 = _798 + 4;\n                    vec4 _1260 = fa_light_texel(param_45);\n                    int param_46 = _798 + 5;\n                    vec4 _1265 = fa_light_texel(param_46);\n                    if (_1237)\n                    {\n                        vec3 _1273 = -to_light;\n                        float _1280 = _1251.w;\n                        float _1296 = 0.5 / max(dot(_1273, _1255) * (sqrt(max(1.0 - (_1280 * _1280), 0.0)) / max(_1280, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1229.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1273, _1260.xyz) * _1296), 0.5 - (dot(_1273, _1265.xyz) * _1296));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1234.z > 0.5)\n                    {\n                        vec2 param_49 = _1234.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1255;\n                        vec3 param_52 = _1260.xyz;\n                        vec3 param_53 = _1265.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5589 = _811.xyz * atten;\n    if (_802)\n    {\n        _5589 *= fa_light_tint;\n    }\n    int _1364;\n    if (_828)\n    {\n        _1364 = 0;\n    }\n    else\n    {\n        _1364 = ((_814 > 1.5) && (_814 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5589, atten, 1.0, dist, _1364);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2147 = fa_shadow_depth(param, param_1);\n    float _2151;\n    if (conv.x < 0.5)\n    {\n        _2151 = _2147;\n    }\n    else\n    {\n        _2151 = (conv.y * conv.z) / (conv.z - (_2147 * (conv.z - conv.y)));\n    }\n    return _2151;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2197 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2203 = vec2(cos(_2197), sin(_2197));\n    vec2 dir = _2203;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2212;\n        if (k < 0.0)\n        {\n            _2212 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2212 = k;\n        }\n        float _2231 = clamp((_2212 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2250 = sqrt((float(i) + 0.5) * 0.0625) * _2231;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2250));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2264 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2264 < (zr - (_2250 * plane)))\n            {\n                sum += _2264;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2292 = sum / cnt;\n        float _2302;\n        if (k < 0.0)\n        {\n            _2302 = (-k) / max(_2292, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2302 = k;\n        }\n        radius = clamp(((max(zr - _2292, 0.0) * unit) * _2302) / texel_m, 1.5, 16.0);\n        dir = _2203;\n    }\n    float lit = 0.0;\n    int _2328 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2328; i_1++)\n    {\n        float _2347 = sqrt((float(i_1) + 0.5) / float(_2328)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2347));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2347 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2328);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2552 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2559;\n    if (!_2552)\n    {\n        _2559 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2559 = _2552;\n    }\n    if (_2559)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2572 = fa_light_texel(param);\n    float _2573 = _2572.x;\n    if (_2573 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2582 = int(_2573 + 0.5);\n    int param_1 = _2582;\n    vec4 _2586 = fa_light_texel(param_1);\n    int param_2 = _2582 + 1;\n    vec4 _2591 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2594 = _2586.y;\n    if (_2594 > 0.0)\n    {\n        float _2611 = 1.0 - smoothstep(0.75 * _2594, _2594, length(world - fa_shadows[27].xyz));\n        fade = _2611;\n        if (_2611 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2586.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2635 = (_2582 + 2) + (face * 6);\n    int param_4 = _2635;\n    int param_5 = _2635 + 1;\n    int param_6 = _2635 + 3;\n    vec4 _2649 = fa_light_texel(param_6);\n    int param_7 = _2635 + 4;\n    vec4 _2654 = fa_light_texel(param_7);\n    int param_8 = _2635 + 5;\n    vec4 _2659 = fa_light_texel(param_8);\n    float _2671 = _2659.x * max(dot(_2649, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2676 = clamp(dot(n, l), 0.0, 1.0);\n    float _2699 = clamp(dot(n, _2649.xyz), -1.0, 1.0);\n    float _2718 = min(sqrt(1.0 - (_2699 * _2699)) / max(abs(dot(n, world - lpos)) / max(dot(_2649, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2721 = _2591.y;\n    float _2723;\n    if (_2721 > 0.0)\n    {\n        _2723 = _2721;\n    }\n    else\n    {\n        _2723 = 1.5 * _2671;\n    }\n    vec4 _2743 = vec4(world + (n * (_2723 * sqrt(1.0 - (_2676 * _2676)))), 1.0);\n    float _2747 = dot(_2649, _2743);\n    float _2750 = _2659.y;\n    if (_2747 < _2750)\n    {\n        return 1.0;\n    }\n    vec2 _2765 = vec2(dot(fa_light_texel(param_4), _2743), dot(fa_light_texel(param_5), _2743)) / vec2(_2747);\n    float _2767 = _2765.x;\n    bool _2770 = _2767 < _2654.x;\n    bool _2779;\n    if (!_2770)\n    {\n        _2779 = _2767 > _2654.z;\n    }\n    else\n    {\n        _2779 = _2770;\n    }\n    bool _2788;\n    if (!_2779)\n    {\n        _2788 = _2765.y < _2654.y;\n    }\n    else\n    {\n        _2788 = _2779;\n    }\n    bool _2797;\n    if (!_2788)\n    {\n        _2797 = _2765.y > _2654.w;\n    }\n    else\n    {\n        _2797 = _2788;\n    }\n    if (_2797)\n    {\n        return 1.0;\n    }\n    float _2803 = _2591.x;\n    float _2805;\n    if (_2803 > 0.0)\n    {\n        _2805 = _2803;\n    }\n    else\n    {\n        _2805 = 1.5 * _2671;\n    }\n    vec2 param_9 = _2765;\n    vec4 param_10 = _2654;\n    float param_11 = _2747 - (_2805 * (1.0 + (0.5 * _2718)));\n    float param_12 = _2671;\n    float param_13 = 1.0;\n    float param_14 = _2659.z * 0.25;\n    float param_15 = (_2671 * min(_2718, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2750, _2659.z);\n    int param_17 = int(_2586.z + 0.5);\n    float param_18 = _2586.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2090;\n    if (i == 0)\n    {\n        _2090 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2106;\n        if (i == 1)\n        {\n            _2106 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2114;\n            if (i == 2)\n            {\n                _2114 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2114 = fa_shadows[24].w;\n            }\n            _2106 = _2114;\n        }\n        _2090 = _2106;\n    }\n    return _2090;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2393 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2398 = clamp(dot(n, l), 0.0, 1.0);\n    float _2404 = sqrt(1.0 - (_2398 * _2398));\n    float _2412 = min(_2404 / max(_2398, 0.20000000298023223876953125), 4.0);\n    float _2417;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2417 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2417 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2442 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2417 * _2404)), 1.0);\n    float _2449 = _2442.x;\n    bool _2452 = _2449 < fa_shadows[ci * 1 + 16].x;\n    bool _2461;\n    if (!_2452)\n    {\n        _2461 = _2449 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2461 = _2452;\n    }\n    bool _2470;\n    if (!_2461)\n    {\n        _2470 = _2442.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2470 = _2461;\n    }\n    bool _2479;\n    if (!_2470)\n    {\n        _2479 = _2442.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2479 = _2470;\n    }\n    bool _2486;\n    if (!_2479)\n    {\n        _2486 = _2442.z > 1.0;\n    }\n    else\n    {\n        _2486 = _2479;\n    }\n    if (_2486)\n    {\n        return -1.0;\n    }\n    float _2494;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2494 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2494 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2442.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2442.z - ((_2494 * (1.0 + (0.5 * _2412))) / _2393);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2393;\n    float param_5 = _2393 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2412, 3.0)) * 0.5) / _2393;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2872 = int(fa_shadows[25].x + 0.5);\n    if (_2872 < 1)\n    {\n        return 1.0;\n    }\n    float _2887 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2872 - 1;\n    if (_2887 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2899 = _2872 > 1;\n    bool _2906;\n    if (_2899)\n    {\n        _2906 = _2887 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2906 = _2899;\n    }\n    if (_2906)\n    {\n        ci = 1;\n    }\n    bool _2910 = _2872 > 2;\n    bool _2917;\n    if (_2910)\n    {\n        _2917 = _2887 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2917 = _2910;\n    }\n    if (_2917)\n    {\n        ci = 2;\n    }\n    bool _2921 = _2872 > 3;\n    bool _2928;\n    if (_2921)\n    {\n        _2928 = _2887 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2928 = _2921;\n    }\n    if (_2928)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2939 = min(_2872, 4);\n    float _2980;\n    for (int c = ci; c < _2939; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2959 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _2959;\n            break;\n        }\n        if (_2959 < 0.0)\n        {\n            continue;\n        }\n        s = _2959;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _2980 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _2980 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _2999 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2980, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2887 - (fa_shadow_split_at(param_7) - _2999)) / _2999, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3031;\n        if ((ci + 1) < _2872)\n        {\n            _3031 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3031 = 1.0;\n        }\n        s = mix(s, _3031, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3486 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3493;\n    if (!_3486)\n    {\n        _3493 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3493 = _3486;\n    }\n    if (_3493)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3506 = fa_light_texel(param);\n    float _3507 = _3506.y;\n    float len = _3507;\n    if (_3507 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3519 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3529 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3519);\n    if (_3529 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3535 = len;\n    float _3538 = min(_3535, 0.89999997615814208984375 * dist);\n    len = _3538;\n    float _3544 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3519);\n    float _3549 = _3544 + (0.5 * _3538);\n    vec3 _3555 = world + (gn * _3544);\n    float _3557 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3622;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3573 = (float(k) + _3557) * 0.083333335816860198974609375;\n        vec3 _3581 = _3555 + (l * (_3573 * len));\n        vec4 _3587 = vec4(_3581, 1.0);\n        float _3593 = dot(fa_mesh_fs_params[28], _3587);\n        if (_3593 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3613 = vec2(dot(fa_mesh_fs_params[26], _3587), dot(fa_mesh_fs_params[27], _3587)) / vec2(_3593);\n        float _3617 = _3613.x * 0.5;\n        float _3618 = _3617 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3622 = (_3613.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3622 = 0.5 - (_3613.y * 0.5);\n        }\n        bool _3638 = _3618 < 0.0;\n        bool _3645;\n        if (!_3638)\n        {\n            _3645 = _3618 >= 1.0;\n        }\n        else\n        {\n            _3645 = _3638;\n        }\n        bool _3652;\n        if (!_3645)\n        {\n            _3652 = _3622 < 0.0;\n        }\n        else\n        {\n            _3652 = _3645;\n        }\n        bool _3659;\n        if (!_3652)\n        {\n            _3659 = _3622 >= 1.0;\n        }\n        else\n        {\n            _3659 = _3652;\n        }\n        if (_3659)\n        {\n            break;\n        }\n        vec4 _3686 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3618, _3622) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_3686.w < 0.5)\n        {\n            continue;\n        }\n        float _3705 = (dot(fa_mesh_fs_params[29].xyz, _3581) + fa_mesh_fs_params[29].w) - _3686.x;\n        if ((_3705 > _3544) && (_3705 < _3549))\n        {\n            occ = max(occ, (1.0 - (_3573 * _3573)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3618, 0.5 - _3617), min(_3622, 1.0 - _3622))));\n        }\n    }\n    return 1.0 - (occ * _3529);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3808 = fa_baked_keep(param);\n    if (_3808 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3834 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5615 = _3834.color;\n    float _5616 = _3834.attenuation;\n    float _5617 = _3834.shadow;\n    bool _3837 = _3834.type == 0;\n    if (_3837 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3834.direction;\n        float _3848 = fa_shadow_factor(param_5, param_6);\n        _5617 = _3848;\n        _5615 *= _3848;\n    }\n    else\n    {\n        bool _3859 = _3834.type != 0;\n        bool _3865;\n        if (_3859)\n        {\n            _3865 = _5616 > 0.0;\n        }\n        else\n        {\n            _3865 = _3859;\n        }\n        if (_3865)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3834.direction;\n            float _3884 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5617 = _3884;\n            _5615 *= _3884;\n        }\n    }\n    bool _3894 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3900;\n    if (_3894)\n    {\n        _3900 = _5616 > 0.0;\n    }\n    else\n    {\n        _3900 = _3894;\n    }\n    if (_3900)\n    {\n        float _3907;\n        if (_3837)\n        {\n            _3907 = 1000000000.0;\n        }\n        else\n        {\n            _3907 = _3834._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3834.direction;\n        float param_18 = _3907;\n        float _3925 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5617 *= _3925;\n        _5615 *= _3925;\n    }\n    float _3938 = _5616;\n    float _3939 = _3938 * _3808;\n    _5616 = _3939;\n    vec3 _3943 = _5615;\n    vec3 _3944 = _3943 * _3808;\n    _5615 = _3944;\n    return LightSample(_3834.direction, _3944, _3939, _5617, _3834._distance, _3834.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3059 = int(fa_shadows[25].x + 0.5);\n    float _3069 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3074 = _3059 > 0;\n    bool _3083;\n    if (_3074)\n    {\n        int param = _3059 - 1;\n        _3083 = _3069 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3083 = _3074;\n    }\n    if (_3083)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3089 = _3059 > 1;\n        bool _3096;\n        if (_3089)\n        {\n            _3096 = _3069 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3096 = _3089;\n        }\n        if (_3096)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3102 = _3059 > 2;\n        bool _3109;\n        if (_3102)\n        {\n            _3109 = _3069 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3109 = _3102;\n        }\n        if (_3109)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3115 = _3059 > 3;\n        bool _3122;\n        if (_3115)\n        {\n            _3122 = _3069 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3122 = _3115;\n        }\n        if (_3122)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5436 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5436 = -_5436;\n    }\n    vec3 _5009 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5436, fa_world_tangent, fa_uv, fa_vertex_color, _5009, gl_FrontFacing);\n    Surface _5017 = fa_standard_surface(param_1);\n    vec3 _5467 = _5017.albedo;\n    float _5468 = _5017.alpha;\n    vec3 _5469 = _5017.normal;\n    float _5470 = _5017.metallic;\n    float _5471 = _5017.roughness;\n    float _5472 = _5017.occlusion;\n    vec3 _5473 = _5017.emission;\n    float _5474 = _5017.clearcoat;\n    float _5475 = _5017.clearcoat_roughness;\n    vec3 _5476 = _5017.sheen_color;\n    float _5477 = _5017.sheen_roughness;\n    float _5478 = _5017.anisotropy;\n    float _5479 = _5017.anisotropy_rotation;\n    float _5480 = _5017.specular;\n    float _5481 = _5017.ior;\n    vec3 _5482 = _5017.specular_color;\n    float _5483 = _5017.transmission;\n    float _5484 = _5017.thickness;\n    vec3 _5485 = _5017.attenuation_color;\n    float _5486 = _5017.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5436, fa_world_tangent, fa_uv, fa_vertex_color, _5009, gl_FrontFacing);\n    Surface param_3 = _5017;\n    surface(param_2, param_3);\n    _5467 = param_3.albedo;\n    _5468 = param_3.alpha;\n    _5469 = param_3.normal;\n    _5470 = param_3.metallic;\n    _5471 = param_3.roughness;\n    _5472 = param_3.occlusion;\n    _5473 = param_3.emission;\n    _5474 = param_3.clearcoat;\n    _5475 = param_3.clearcoat_roughness;\n    _5476 = param_3.sheen_color;\n    _5477 = param_3.sheen_roughness;\n    _5478 = param_3.anisotropy;\n    _5479 = param_3.anisotropy_rotation;\n    _5480 = param_3.specular;\n    _5481 = param_3.ior;\n    _5482 = param_3.specular_color;\n    _5483 = param_3.transmission;\n    _5484 = param_3.thickness;\n    _5485 = param_3.attenuation_color;\n    _5486 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5436;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5467 = param_6;\n    _5469 = param_7;\n    fa_lod_dither();\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5467;\n    }\n    else\n    {\n        vec3 _5057 = _5469;\n        vec3 _5058 = normalize(_5057);\n        _5469 = _5058;\n        vec3 param_8 = _5058;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _5467) * _5472;\n        int _5077 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _5077; ln++)\n        {\n            int param_9 = ln;\n            int _5090 = fa_cl_light(param_9);\n            int param_10 = _5090;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _5090;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _5436;\n            LightSample _5106 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _5436, fa_world_tangent, fa_uv, fa_vertex_color, _5009, gl_FrontFacing);\n            Surface param_15 = Surface(_5467, _5468, _5469, _5470, _5471, _5472, _5473, _5474, _5475, _5476, _5477, _5478, _5479, _5480, _5481, _5482, _5483, _5484, _5485, _5486);\n            LightSample param_16 = _5106;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _5121 = result;\n    vec3 _5122 = _5121 + _5473;\n    result = _5122;\n    vec3 param_17 = _5122;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _5131 = fa_mesh_fs_params[7].w > 0.0;\n    bool _5138;\n    if (!_5131)\n    {\n        _5138 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _5138 = _5131;\n    }\n    if (_5138)\n    {\n        vec3 _5147 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _5153 = dot(_5147, fa_mesh_fs_params[9].xyz);\n        bool _5157 = fa_mesh_fs_params[9].w > 0.5;\n        float _5158;\n        if (_5157)\n        {\n            _5158 = _5153;\n        }\n        else\n        {\n            _5158 = length(_5147);\n        }\n        float _5170 = _5158 - fa_mesh_fs_params[8].x;\n        if (_5170 > 0.0)\n        {\n            float _5179 = fa_mesh_fs_params[7].w * _5170;\n            float tau = _5179 * _5179;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _5195;\n                if (_5157)\n                {\n                    _5195 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _5153);\n                }\n                else\n                {\n                    _5195 = fa_mesh_fs_params[0].y;\n                }\n                float _5216 = mix(_5195, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _5158, 0.0, 1.0));\n                float _5220 = fa_world_pos.y - _5216;\n                float _5225 = _5216 - fa_mesh_fs_params[8].z;\n                float _5230 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5233 = _5225 <= 0.0;\n                bool _5234 = !_5233;\n                bool _5240;\n                if (_5234)\n                {\n                    _5240 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5240 = _5233;\n                }\n                float _5241;\n                if (_5240)\n                {\n                    _5241 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5241 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5225, 80.0));\n                }\n                bool _5268;\n                if (_5234)\n                {\n                    _5268 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5268 = _5233;\n                }\n                float _5269;\n                if (_5268)\n                {\n                    _5269 = fa_mesh_fs_params[8].y * _5225;\n                }\n                else\n                {\n                    _5269 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5225, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5294 = _5230 <= 0.0;\n                bool _5301;\n                if (!_5294)\n                {\n                    _5301 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5301 = _5294;\n                }\n                float _5302;\n                if (_5301)\n                {\n                    _5302 = fa_mesh_fs_params[8].y * _5230;\n                }\n                else\n                {\n                    _5302 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5230, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5329;\n                if (abs(_5220) < 0.001000000047497451305389404296875)\n                {\n                    _5329 = _5241;\n                }\n                else\n                {\n                    _5329 = (_5302 - _5269) / _5220;\n                }\n                tau += (_5170 * max(_5329, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5468);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_366",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
            "inst_name": "_2100",
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
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
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
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _267 = fa_tex_fix(param_2, param_3);\n    vec4 _868 = base_t;\n    _868.x = _267.x;\n    _868.y = _267.y;\n    _868.z = _267.z;\n    base_t = _868;\n    vec4 _283 = (_868 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _823 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _317 = fa_tex_fix(param_6, param_7);\n        vec3 _321 = (_317 * 2.0) - vec3(1.0);\n        vec2 _326 = _321.xy * fa_mesh_fs_params[6].x;\n        vec3 _876 = _321;\n        _876.x = _326.x;\n        _876.y = _326.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _876;\n        _823 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _355 = fa_tex_fix(param_12, param_13);\n    vec4 _879 = mrt;\n    _879.x = _355.x;\n    _879.y = _355.y;\n    _879.z = _355.z;\n    mrt = _879;\n    vec4 _385 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _427 = fa_tex_fix(param_20, param_21);\n    float _828 = fa_mesh_fs_params[20].x;\n    float _829 = fa_mesh_fs_params[20].y;\n    float _832 = fa_mesh_fs_params[20].z;\n    float _831 = fa_mesh_fs_params[21].w;\n    float _834 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _828 *= _397.y;\n            _829 *= _397.z;\n            _831 *= _385.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _832 *= mrt.x;\n            _834 *= mrt.w;\n        }\n    }\n    return Surface(_283.xyz, _283.w, _823, clamp(fa_mesh_fs_params[5].x * _355.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _355.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_397.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _427), _828, _829, fa_mesh_fs_params[21].xyz, _831, _832, fa_mesh_fs_params[20].w, _834, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _718 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _718 = -_718;\n    }\n    vec3 _579 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface _584 = fa_standard_surface(param);\n    vec3 _742 = _584.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _742 = param_2.normal;\n    fa_lod_dither();\n    vec3 _595 = normalize(_742);\n    vec3 _610 = normalize(vec3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    vec2 e = _610.xy / vec2((abs(_610.x) + abs(_610.y)) + abs(_622));\n    if (_622 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _267 = fa_tex_fix(param_2, param_3);\n    vec4 _868 = base_t;\n    _868.x = _267.x;\n    _868.y = _267.y;\n    _868.z = _267.z;\n    base_t = _868;\n    vec4 _283 = (_868 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _823 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _317 = fa_tex_fix(param_6, param_7);\n        vec3 _321 = (_317 * 2.0) - vec3(1.0);\n        vec2 _326 = _321.xy * fa_mesh_fs_params[6].x;\n        vec3 _876 = _321;\n        _876.x = _326.x;\n        _876.y = _326.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _876;\n        _823 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _355 = fa_tex_fix(param_12, param_13);\n    vec4 _879 = mrt;\n    _879.x = _355.x;\n    _879.y = _355.y;\n    _879.z = _355.z;\n    mrt = _879;\n    vec4 _385 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _427 = fa_tex_fix(param_20, param_21);\n    float _828 = fa_mesh_fs_params[20].x;\n    float _829 = fa_mesh_fs_params[20].y;\n    float _832 = fa_mesh_fs_params[20].z;\n    float _831 = fa_mesh_fs_params[21].w;\n    float _834 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _828 *= _397.y;\n            _829 *= _397.z;\n            _831 *= _385.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _832 *= mrt.x;\n            _834 *= mrt.w;\n        }\n    }\n    return Surface(_283.xyz, _283.w, _823, clamp(fa_mesh_fs_params[5].x * _355.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _355.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_397.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _427), _828, _829, fa_mesh_fs_params[21].xyz, _831, _832, fa_mesh_fs_params[20].w, _834, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _718 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _718 = -_718;\n    }\n    vec3 _579 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface _584 = fa_standard_surface(param);\n    vec3 _742 = _584.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _742 = param_2.normal;\n    fa_lod_dither();\n    vec3 _595 = normalize(_742);\n    vec3 _610 = normalize(vec3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    vec2 e = _610.xy / vec2((abs(_610.x) + abs(_610.y)) + abs(_622));\n    if (_622 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_129",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
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
