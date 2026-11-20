{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "559609183f39d15a98638319a0abdbf558e86e30a9c2dcc930141d2b969fc0f0",
  "slang": "glsl430",
  "params": [
    "base"
  ],
  "textures": [],
  "full": true,
  "shadow": "none",
  "prepass": false,
  "passes": [
    {
      "name": "main",
      "cull": "back",
      "depthTest": true,
      "depthWrite": true,
      "blend": "none",
      "program": "mesh",
      "programSkin": "mesh_skin"
    }
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _61 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_61 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _61) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _109 = fa_world_position(param);\n    v_pos = _109;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _109;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_109, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_mesh_fs_params[14];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _100 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_100)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _118 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _120 = length(_118);\n        dist = _120;\n        l = _118 / vec3(max(_120, 9.9999997473787516355514526367188e-05));\n        float _136 = _120 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _142 = clamp(1.0 - (_136 * _136), 0.0, 1.0);\n        atten = _142 * _142;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _194;\n    if (_100)\n    {\n        _194 = 0;\n    }\n    else\n    {\n        _194 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _194);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _246;\n    if (i == 0)\n    {\n        _246 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _263;\n        if (i == 1)\n        {\n            _263 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _272;\n            if (i == 2)\n            {\n                _272 = fa_shadows[24].z;\n            }\n            else\n            {\n                _272 = fa_shadows[24].w;\n            }\n            _263 = _272;\n        }\n        _246 = _263;\n    }\n    return _246;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _234 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_234), sin(_234)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _317 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _322 = clamp(dot(n, l), 0.0, 1.0);\n    float _328 = sqrt(1.0 - (_322 * _322));\n    float _336 = min(_328 / max(_322, 0.20000000298023223876953125), 4.0);\n    float _341;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _341 = fa_shadows[26].y;\n    }\n    else\n    {\n        _341 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _366 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_341 * _328)), 1.0);\n    float _373 = _366.x;\n    bool _376 = _373 < fa_shadows[ci * 1 + 16].x;\n    bool _385;\n    if (!_376)\n    {\n        _385 = _373 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _385 = _376;\n    }\n    bool _394;\n    if (!_385)\n    {\n        _394 = _366.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _394 = _385;\n    }\n    bool _403;\n    if (!_394)\n    {\n        _403 = _366.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _403 = _394;\n    }\n    bool _410;\n    if (!_403)\n    {\n        _410 = _366.z > 1.0;\n    }\n    else\n    {\n        _410 = _403;\n    }\n    if (_410)\n    {\n        return -1.0;\n    }\n    float _419;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _419 = fa_shadows[26].x;\n    }\n    else\n    {\n        _419 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _438 = _366.z - ((_419 * (1.0 + (0.5 * _336))) / _317);\n    float _447 = ((fa_shadows[ci * 1 + 20].x * min(_336, 3.0)) * 0.5) / _317;\n    int _456 = int(fa_shadows[25].z + 0.5);\n    if (_456 == 1)\n    {\n        vec2 param = _366.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _467 = fa_shadow_depth(param, param_1);\n        return float(_438 <= _467);\n    }\n    float _474 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _477 = _456 == 2;\n    if (_477)\n    {\n        float _491 = clamp(((fa_shadows[25].w * _317) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _474;\n            vec2 _511 = fa_shadow_vogel(param_2, param_3, param_4) * _491;\n            vec2 param_5 = _366.xy + (_511 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _522 = fa_shadow_depth(param_5, param_6);\n            if (_522 < (_438 - (length(_511) * _447)))\n            {\n                sum += _522;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_438 - (sum / cnt), 0.0) * _317) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _566 = _477 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _566; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _566;\n        float param_9 = _474;\n        vec2 _585 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _366.xy + (_585 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _596 = fa_shadow_depth(param_10, param_11);\n        lit += float((_438 - (length(_585) * _447)) <= _596);\n    }\n    return lit / float(_566);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _629 = int(fa_shadows[25].x + 0.5);\n    if (_629 < 1)\n    {\n        return 1.0;\n    }\n    float _646 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _629 - 1;\n    if (_646 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _658 = _629 > 1;\n    bool _665;\n    if (_658)\n    {\n        _665 = _646 > fa_shadows[24].x;\n    }\n    else\n    {\n        _665 = _658;\n    }\n    if (_665)\n    {\n        ci = 1;\n    }\n    bool _669 = _629 > 2;\n    bool _676;\n    if (_669)\n    {\n        _676 = _646 > fa_shadows[24].y;\n    }\n    else\n    {\n        _676 = _669;\n    }\n    if (_676)\n    {\n        ci = 2;\n    }\n    bool _680 = _629 > 3;\n    bool _687;\n    if (_680)\n    {\n        _687 = _646 > fa_shadows[24].z;\n    }\n    else\n    {\n        _687 = _680;\n    }\n    if (_687)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _629)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _713 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _713;\n        if (_713 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _738;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _738 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _738 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _757 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _738, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _768 = clamp((_646 - (fa_shadow_split_at(param_7) - _757)) / _757, 0.0, 1.0);\n        if (_768 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _629)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _789 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _789;\n                if (_789 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _768);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _829 = fa_light_sample(param, param_1);\n    vec3 _1188 = _829.direction;\n    vec3 _1183 = _829.color;\n    float _1190 = _829.attenuation;\n    float _1185 = _829.shadow;\n    int _1193 = _829.type;\n    if ((_1193 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _1188;\n        float _845 = fa_shadow(param_2, param_3, param_4);\n        _1185 = _845;\n        _1183 = fa_lights[li * 1 + 32].xyz * (_1190 * _845);\n    }\n    return LightSample(_1188, _1183, _1190, _1185, _829._distance, _1193);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _863 = fa_mesh_fs_params[7].w > 0.0;\n    bool _871;\n    if (!_863)\n    {\n        _871 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _871 = _863;\n    }\n    if (_871)\n    {\n        vec3 _879 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _886 = dot(_879, fa_mesh_fs_params[9].xyz);\n        bool _890 = fa_mesh_fs_params[9].w > 0.5;\n        float _891;\n        if (_890)\n        {\n            _891 = _886;\n        }\n        else\n        {\n            _891 = length(_879);\n        }\n        float _903 = _891 - fa_mesh_fs_params[8].x;\n        if (_903 > 0.0)\n        {\n            float _912 = fa_mesh_fs_params[7].w * _903;\n            float tau = _912 * _912;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _928;\n                if (_890)\n                {\n                    _928 = world_pos.y - (fa_mesh_fs_params[9].y * _886);\n                }\n                else\n                {\n                    _928 = fa_mesh_fs_params[0].y;\n                }\n                float _949 = mix(_928, world_pos.y, clamp(fa_mesh_fs_params[8].x / _891, 0.0, 1.0));\n                float _953 = world_pos.y - _949;\n                float _958 = _949 - fa_mesh_fs_params[8].z;\n                float _963 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _966 = _958 <= 0.0;\n                bool _967 = !_966;\n                bool _973;\n                if (_967)\n                {\n                    _973 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _973 = _966;\n                }\n                float _974;\n                if (_973)\n                {\n                    _974 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _974 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _958, 80.0));\n                }\n                bool _1001;\n                if (_967)\n                {\n                    _1001 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1001 = _966;\n                }\n                float _1002;\n                if (_1001)\n                {\n                    _1002 = fa_mesh_fs_params[8].y * _958;\n                }\n                else\n                {\n                    _1002 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _958, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1027 = _963 <= 0.0;\n                bool _1034;\n                if (!_1027)\n                {\n                    _1034 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1034 = _1027;\n                }\n                float _1035;\n                if (_1034)\n                {\n                    _1035 = fa_mesh_fs_params[8].y * _963;\n                }\n                else\n                {\n                    _1035 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _963, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1062;\n                if (abs(_953) < 0.001000000047497451305389404296875)\n                {\n                    _1062 = _974;\n                }\n                else\n                {\n                    _1062 = (_1035 - _1002) / _953;\n                }\n                tau += (_903 * max(_1062, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _1100 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _1100;\n        vec4 param_3 = v_shadow;\n        LightSample _1132 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _1132.color) * max(dot(_1100, _1132.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _1155 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_1155, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "inst_name": "_129",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_86",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_256",
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
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_618",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1107",
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
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
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
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nuniform vec4 fa_skin[192];\nuniform vec4 fa_mesh_vs_params[10];\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 0) out vec3 v_pos;\nlayout(location = 1) out vec3 v_normal;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 2) out vec4 v_shadow;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 4) in vec4 fa_color;\nmat4 fa_model;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _61 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_61 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_61 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_61 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec3 fa_world_position(vec3 p)\n{\n    return (fa_model * vec4(p, 1.0)).xyz;\n}\n\nvec3 fa_world_direction(vec3 n)\n{\n    vec3 _185 = cross(fa_model[1].xyz, fa_model[2].xyz);\n    return normalize((((_185 * n.x) + (cross(fa_model[2].xyz, fa_model[0].xyz) * n.y)) + (cross(fa_model[0].xyz, fa_model[1].xyz) * n.z)) * ((dot(fa_model[0].xyz, _185) < 0.0) ? (-1.0) : 1.0));\n}\n\nvec4 fa_shadow_coord(vec3 world)\n{\n    return vec4(world, 1.0);\n}\n\nvoid fa_user_main()\n{\n    vec3 param = fa_position;\n    vec3 _227 = fa_world_position(param);\n    v_pos = _227;\n    vec3 param_1 = fa_normal;\n    v_normal = fa_world_direction(param_1);\n    vec3 param_2 = _227;\n    v_shadow = fa_shadow_coord(param_2);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_227, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_model = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    fa_user_main();\n}\n\n",
      "fs": "#version 430\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nuniform vec4 fa_lights[96];\nuniform vec4 fa_shadows[29];\nuniform vec4 fa_mesh_fs_params[14];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_full_shadow_tex_fa_full_shadow_smp;\n\nlayout(location = 1) in vec3 v_normal;\nlayout(location = 0) in vec3 v_pos;\nlayout(location = 2) in vec4 v_shadow;\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid fa_inst_load()\n{\n}\n\nint fa_light_count()\n{\n    return min(int(fa_mesh_fs_params[10].x), 32);\n}\n\nLightSample fa_light_sample(int li, vec3 world_pos)\n{\n    float atten = 1.0;\n    float dist = 0.0;\n    bool _100 = fa_lights[li * 1 + 32].w < 0.5;\n    vec3 l;\n    if (_100)\n    {\n        l = normalize(fa_lights[li * 1 + 0].xyz);\n    }\n    else\n    {\n        vec3 _118 = fa_lights[li * 1 + 0].xyz - world_pos;\n        float _120 = length(_118);\n        dist = _120;\n        l = _118 / vec3(max(_120, 9.9999997473787516355514526367188e-05));\n        float _136 = _120 / max(fa_lights[li * 1 + 0].w, 0.001000000047497451305389404296875);\n        float _142 = clamp(1.0 - (_136 * _136), 0.0, 1.0);\n        atten = _142 * _142;\n        if (fa_lights[li * 1 + 32].w > 1.5)\n        {\n            atten *= smoothstep(fa_lights[li * 1 + 64].w, mix(fa_lights[li * 1 + 64].w, 1.0, 0.25), dot(-l, normalize(fa_lights[li * 1 + 64].xyz)));\n        }\n    }\n    int _194;\n    if (_100)\n    {\n        _194 = 0;\n    }\n    else\n    {\n        _194 = (fa_lights[li * 1 + 32].w > 1.5) ? 2 : 1;\n    }\n    return LightSample(l, fa_lights[li * 1 + 32].xyz * atten, atten, 1.0, dist, _194);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _246;\n    if (i == 0)\n    {\n        _246 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _263;\n        if (i == 1)\n        {\n            _263 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _272;\n            if (i == 2)\n            {\n                _272 = fa_shadows[24].z;\n            }\n            else\n            {\n                _272 = fa_shadows[24].w;\n            }\n            _263 = _272;\n        }\n        _246 = _263;\n    }\n    return _246;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_full_shadow_tex_fa_full_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _234 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_234), sin(_234)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _317 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _322 = clamp(dot(n, l), 0.0, 1.0);\n    float _328 = sqrt(1.0 - (_322 * _322));\n    float _336 = min(_328 / max(_322, 0.20000000298023223876953125), 4.0);\n    float _341;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _341 = fa_shadows[26].y;\n    }\n    else\n    {\n        _341 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _366 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_341 * _328)), 1.0);\n    float _373 = _366.x;\n    bool _376 = _373 < fa_shadows[ci * 1 + 16].x;\n    bool _385;\n    if (!_376)\n    {\n        _385 = _373 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _385 = _376;\n    }\n    bool _394;\n    if (!_385)\n    {\n        _394 = _366.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _394 = _385;\n    }\n    bool _403;\n    if (!_394)\n    {\n        _403 = _366.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _403 = _394;\n    }\n    bool _410;\n    if (!_403)\n    {\n        _410 = _366.z > 1.0;\n    }\n    else\n    {\n        _410 = _403;\n    }\n    if (_410)\n    {\n        return -1.0;\n    }\n    float _419;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _419 = fa_shadows[26].x;\n    }\n    else\n    {\n        _419 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    float _438 = _366.z - ((_419 * (1.0 + (0.5 * _336))) / _317);\n    float _447 = ((fa_shadows[ci * 1 + 20].x * min(_336, 3.0)) * 0.5) / _317;\n    int _456 = int(fa_shadows[25].z + 0.5);\n    if (_456 == 1)\n    {\n        vec2 param = _366.xy;\n        vec4 param_1 = fa_shadows[ci * 1 + 16];\n        float _467 = fa_shadow_depth(param, param_1);\n        return float(_438 <= _467);\n    }\n    float _474 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    bool _477 = _456 == 2;\n    if (_477)\n    {\n        float _491 = clamp(((fa_shadows[25].w * _317) * 0.25) / fa_shadows[ci * 1 + 20].x, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_2 = i;\n            int param_3 = 16;\n            float param_4 = _474;\n            vec2 _511 = fa_shadow_vogel(param_2, param_3, param_4) * _491;\n            vec2 param_5 = _366.xy + (_511 * fa_shadows[26].zw);\n            vec4 param_6 = fa_shadows[ci * 1 + 16];\n            float _522 = fa_shadow_depth(param_5, param_6);\n            if (_522 < (_438 - (length(_511) * _447)))\n            {\n                sum += _522;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        radius = clamp(((max(_438 - (sum / cnt), 0.0) * _317) * fa_shadows[25].w) / fa_shadows[ci * 1 + 20].x, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _566 = _477 ? 24 : 16;\n    for (int i_1 = 0; i_1 < _566; i_1++)\n    {\n        int param_7 = i_1;\n        int param_8 = _566;\n        float param_9 = _474;\n        vec2 _585 = fa_shadow_vogel(param_7, param_8, param_9) * radius;\n        vec2 param_10 = _366.xy + (_585 * fa_shadows[26].zw);\n        vec4 param_11 = fa_shadows[ci * 1 + 16];\n        float _596 = fa_shadow_depth(param_10, param_11);\n        lit += float((_438 - (length(_585) * _447)) <= _596);\n    }\n    return lit / float(_566);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _629 = int(fa_shadows[25].x + 0.5);\n    if (_629 < 1)\n    {\n        return 1.0;\n    }\n    float _646 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _629 - 1;\n    if (_646 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _658 = _629 > 1;\n    bool _665;\n    if (_658)\n    {\n        _665 = _646 > fa_shadows[24].x;\n    }\n    else\n    {\n        _665 = _658;\n    }\n    if (_665)\n    {\n        ci = 1;\n    }\n    bool _669 = _629 > 2;\n    bool _676;\n    if (_669)\n    {\n        _676 = _646 > fa_shadows[24].y;\n    }\n    else\n    {\n        _676 = _669;\n    }\n    if (_676)\n    {\n        ci = 2;\n    }\n    bool _680 = _629 > 3;\n    bool _687;\n    if (_680)\n    {\n        _687 = _646 > fa_shadows[24].z;\n    }\n    else\n    {\n        _687 = _680;\n    }\n    if (_687)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _629)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _713 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _713;\n        if (_713 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _738;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _738 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _738 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _757 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _738, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _768 = clamp((_646 - (fa_shadow_split_at(param_7) - _757)) / _757, 0.0, 1.0);\n        if (_768 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _629)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _789 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _789;\n                if (_789 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _768);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow(vec4 coord, vec3 n, vec3 l)\n{\n    vec3 param = coord.xyz / vec3(coord.w);\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nLightSample fa_light(int li, vec3 world_pos, vec3 gn, vec4 coord)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    LightSample _829 = fa_light_sample(param, param_1);\n    vec3 _1188 = _829.direction;\n    vec3 _1183 = _829.color;\n    float _1190 = _829.attenuation;\n    float _1185 = _829.shadow;\n    int _1193 = _829.type;\n    if ((_1193 == 0) && (li == 0))\n    {\n        vec4 param_2 = coord;\n        vec3 param_3 = gn;\n        vec3 param_4 = _1188;\n        float _845 = fa_shadow(param_2, param_3, param_4);\n        _1185 = _845;\n        _1183 = fa_lights[li * 1 + 32].xyz * (_1190 * _845);\n    }\n    return LightSample(_1188, _1183, _1190, _1185, _829._distance, _1193);\n}\n\nvec3 fa_apply_fog(inout vec3 result, vec3 world_pos)\n{\n    bool _863 = fa_mesh_fs_params[7].w > 0.0;\n    bool _871;\n    if (!_863)\n    {\n        _871 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _871 = _863;\n    }\n    if (_871)\n    {\n        vec3 _879 = world_pos - fa_mesh_fs_params[0].xyz;\n        float _886 = dot(_879, fa_mesh_fs_params[9].xyz);\n        bool _890 = fa_mesh_fs_params[9].w > 0.5;\n        float _891;\n        if (_890)\n        {\n            _891 = _886;\n        }\n        else\n        {\n            _891 = length(_879);\n        }\n        float _903 = _891 - fa_mesh_fs_params[8].x;\n        if (_903 > 0.0)\n        {\n            float _912 = fa_mesh_fs_params[7].w * _903;\n            float tau = _912 * _912;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _928;\n                if (_890)\n                {\n                    _928 = world_pos.y - (fa_mesh_fs_params[9].y * _886);\n                }\n                else\n                {\n                    _928 = fa_mesh_fs_params[0].y;\n                }\n                float _949 = mix(_928, world_pos.y, clamp(fa_mesh_fs_params[8].x / _891, 0.0, 1.0));\n                float _953 = world_pos.y - _949;\n                float _958 = _949 - fa_mesh_fs_params[8].z;\n                float _963 = world_pos.y - fa_mesh_fs_params[8].z;\n                bool _966 = _958 <= 0.0;\n                bool _967 = !_966;\n                bool _973;\n                if (_967)\n                {\n                    _973 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _973 = _966;\n                }\n                float _974;\n                if (_973)\n                {\n                    _974 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _974 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _958, 80.0));\n                }\n                bool _1001;\n                if (_967)\n                {\n                    _1001 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1001 = _966;\n                }\n                float _1002;\n                if (_1001)\n                {\n                    _1002 = fa_mesh_fs_params[8].y * _958;\n                }\n                else\n                {\n                    _1002 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _958, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _1027 = _963 <= 0.0;\n                bool _1034;\n                if (!_1027)\n                {\n                    _1034 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _1034 = _1027;\n                }\n                float _1035;\n                if (_1034)\n                {\n                    _1035 = fa_mesh_fs_params[8].y * _963;\n                }\n                else\n                {\n                    _1035 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _963, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _1062;\n                if (abs(_953) < 0.001000000047497451305389404296875)\n                {\n                    _1062 = _974;\n                }\n                else\n                {\n                    _1062 = (_1035 - _1002) / _953;\n                }\n                tau += (_903 * max(_1062, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    return result;\n}\n\nvoid fa_user_main()\n{\n    vec3 _1100 = normalize(v_normal);\n    vec3 lit = fa_mesh_fs_params[1].xyz * fa_material[0].xyz;\n    for (int i = 0; i < fa_light_count(); i++)\n    {\n        int param = i;\n        vec3 param_1 = v_pos;\n        vec3 param_2 = _1100;\n        vec4 param_3 = v_shadow;\n        LightSample _1132 = fa_light(param, param_1, param_2, param_3);\n        lit += ((fa_material[0].xyz * _1132.color) * max(dot(_1100, _1132.direction), 0.0));\n    }\n    vec3 param_4 = lit;\n    vec3 param_5 = v_pos;\n    vec3 _1155 = fa_apply_fog(param_4, param_5);\n    fa_frag_color = vec4(_1155, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    fa_user_main();\n}\n\n",
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
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_71",
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
            "slot": 0,
            "stage": "vertex",
            "size": 160,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_247",
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
            "slot": 2,
            "stage": "fragment",
            "size": 1536,
            "struct_name": "fa_lights",
            "inst_name": "_86",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 96,
                "offset": 0,
                "glsl_name": "fa_lights"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 464,
            "struct_name": "fa_shadows",
            "inst_name": "_256",
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
            "slot": 1,
            "stage": "fragment",
            "size": 224,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_618",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 14,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_1107",
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
              "slot": 1,
              "stage": "fragment",
              "name": "fa_full_shadow_tex",
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
            "name": "fa_full_shadow_smp",
            "sampler_type": "nonfiltering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_full_shadow_tex_fa_full_shadow_smp",
            "view_name": "fa_full_shadow_tex",
            "sampler_name": "fa_full_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_full_shadow_tex_fa_full_shadow_smp"
          }
        ]
      }
    }
  }
}
