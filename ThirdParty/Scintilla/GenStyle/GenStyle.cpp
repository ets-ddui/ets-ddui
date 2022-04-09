/*
    Copyright (c) 2021-2031 Steven Shi

    ETS_DDUI For Delphi，让漂亮界面做起来更简单。

    本UI库是开源自由软件，您可以遵照 MIT 协议，修改和发布此程序。
    发布此库的目的是希望其有用，但不做任何保证。
    如果将本库用于商业项目，由于本库中的Bug，而引起的任何风险及损失，本作者不承担任何责任。

    开源地址: https://github.com/ets-ddui/ets-ddui
              https://gitee.com/ets-ddui/ets-ddui
    开源协议: The MIT License (MIT)
    作者邮箱: xinghun87@163.com
    官方博客：https://blog.csdn.net/xinghun61
*/
#include <stdio.h>
#include <tchar.h>
#include <stdarg.h>
#include <map>
#include <string>
#include <vector>
#include <list>
#include <set>

static bool IsValid(std::string &p_sLanguage, std::string &p_sLexer)
{

    static const struct {
        char m_sLanguage[32];
        char m_sLexer[32];
    } c_stValid[] = {
        {"*",       "asm"},
        {"*",       "bash"},
        {"*",       "batch"},
        {"*",       "cmake"},
        {"*",       "coffeescript"},
        {"*",       "conf"},
        {"Ch",      "cpp"},
        {"Flash",   "cpp"},
        {"Pike",    "cpp"},
        {"Swift",   "cpp"},
        {"SilkTest","cpp"},
        {"*",       "cpp"},
        {"*",       "css"},
        {"*",       "hypertext"},
        {"*",       "lua"},
        {"*",       "makefile"},
        {"*",       "markdown"},
        {"*",       "nsis"},
        {"*",       "pascal"},
        {"GAWK",    "perl"},
        {"*",       "perl"},
        {"*",       "powershell"},
        {"*",       "props"},
        {"*",       "python"},
        {"*",       "sql"},
        {"*",       "vb"},
        {"*",       "vbscript"},
        {"*",       "xml"}
    };

    for (int i = 0; i < sizeof(c_stValid) / sizeof(c_stValid[0]); ++i)
    {
        if (0 == _stricmp(c_stValid[i].m_sLexer, p_sLexer.c_str()))
        {
            if (0 == _stricmp(c_stValid[i].m_sLanguage, "*"))
            {
                return true;
            }

            if (0 == _stricmp(c_stValid[i].m_sLanguage, p_sLanguage.c_str()))
            {
                return false;
            }
        }
    }

    return false;
}

class CPropSetFile
{
public:
    bool LoadFromFile(const std::string &p_sPropFile)
    {
        FILE *fp = fopen(p_sPropFile.c_str(), "rb");
        if (nullptr == fp)
        {
            return false;
        }

        fseek(fp, 0, SEEK_END);
        int iSize = ftell(fp);
        fseek(fp, 0, SEEK_SET);

        std::string sData;
        sData.resize(iSize);
        int iRead = fread(const_cast<char *>(sData.c_str()), sizeof(char), iSize, fp);
        if (iRead != iSize)
        {
            //如果数据没读全，依然执行，但输出提示信息
            sData.resize(iRead);
            fprintf(stderr, "文件内容未读取完整，实际读取%d，预期读取%d\n", iRead, iSize);
        }

        fclose(fp);

        return LoadFromStream(sData);
    }

    bool LoadFromStream(const std::string &p_sData)
    {
        bool bContinue = false, bIfTrue = true;
        std::string sLine;
        std::string::size_type iBegin = 0, iEnd = 0, iLen = p_sData.size();
        while (iBegin < iLen)
        {
            iEnd = p_sData.find_first_of("\r\n", iBegin);
            if (iEnd == p_sData.npos)
            {
                iEnd = iLen;
            }

            if (iEnd > iBegin && '\\' == p_sData[iEnd - 1])
            {
                bContinue = true;
                sLine.append(p_sData.substr(iBegin, iEnd - iBegin - 1));
            }
            else
            {
                bContinue = false;
                sLine.append(p_sData.substr(iBegin, iEnd - iBegin));
            }

            if (iEnd + 1 < iLen && '\r' == p_sData[iEnd] && '\n' == p_sData[iEnd + 1])
            {
                iBegin = iEnd + 2;
            }
            else
            {
                iBegin = iEnd + 1;
            }

            if (bContinue && iBegin < iLen)
            {
                continue;
            }

            if (sLine.empty())
            {
                continue;
            }

            bIfTrue = DealLine(sLine, bIfTrue);
            sLine.erase();
        }

        return true;
    }

    void GenStyle() const
    {
        const char c_sFilter[] = "filter.";

        int iLoop = 0;
        std::list<std::string> lstLanguages, lstStyles;
        std::vector<std::string> vValue;
        std::string sKey, sAlias, sLexer, sLanguage, sExtend, sKeyword, sStyle, sVariable;
        std::map<int, std::string> mapKeyword;
        std::set<std::string> setLexer, setVariable;
        for (auto it = m_mapProp.lower_bound(c_sFilter); 0 == strncmp(it->first.c_str(), c_sFilter, sizeof(c_sFilter) - 1); ++it)
        {
            //1.0 取languages配置信息
            //1.1 取lexer和language
            SplitString(vValue, it->first, '.');
            if (2 != vValue.size())
            {
                fprintf(stderr, "(1000)%s\n", it->first.c_str());
                continue;;
            }

            sAlias = vValue[1];

            SplitString(vValue, it->second, '|');
            if (2 > vValue.size())
            {
                fprintf(stderr, "(1001)%s\n", it->second.c_str());
                continue;
            }

            sLanguage = vValue[0];
            sExtend = ExtendValue(vValue[1]);

            SplitString(vValue, sLanguage, '(');
            if (0 == vValue.size())
            {
                fprintf(stderr, "(1002)%s\n", sLanguage.c_str());
                continue;
            }

            sLanguage = Trim(vValue[0]);

            if (sAlias == "cobol")
            {
                sAlias = "COBOL";
                sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
            }
            else if (sAlias == "pascal")
            {
                sKey = Format("lexer.$(file.patterns.%s.all)", sAlias.c_str());
            }
            else if (sAlias == "properties")
            {
                switch(iLoop)
                {
                case 0:
                    sAlias = "props";
                    sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
                    ++iLoop;
                    --it;

                    break;
                case 1:
                    sAlias = "make";
                    sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
                    sLanguage = "Makefile";
                    sExtend = ExtendValue(GetValue("file.patterns.make"));
                    iLoop = 0;

                    break;
                default:
                    fprintf(stderr, "(1003)无效的循环变量(%d)%s\n", iLoop, sAlias.c_str());
                    continue;
                }
            }
            else if (sAlias == "python")
            {
                sAlias = "py";
                sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
            }
            else if (sAlias == "ruby")
            {
                sAlias = "rb";
                sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
            }
            else if (sAlias == "scriptol")
            {
                sAlias = "sol";
                sKey = Format("lexer.*.%s", sAlias.c_str());
            }
            else if (sAlias == "tacl")
            {
                sAlias = "TACL";
                sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
            }
            else if (sAlias == "tal")
            {
                sAlias = "TAL";
                sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
            }
            else if (sAlias == "web")
            {
                switch(iLoop)
                {
                case 0:
                    sAlias = "html";
                    sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
                    sLanguage = "Html";
                    sExtend = ExtendValue(GetValue("file.patterns.web"));
                    ++iLoop;
                    --it;

                    break;
                case 1:
                    sAlias = "xml";
                    sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
                    sLanguage = "Xml";
                    sExtend = ExtendValue(GetValue("file.patterns.xml"));
                    iLoop = 0;

                    break;
                default:
                    fprintf(stderr, "(1003)无效的循环变量(%d)%s\n", iLoop, sAlias.c_str());
                    continue;
                }
            }
            else if (sAlias == "php")
            {
                sAlias = "html";
                sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
            }
            else if (sAlias == "vb")
            {
                switch(iLoop)
                {
                case 0:
                    sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
                    sExtend = ExtendValue(GetValue("file.patterns.vb"));
                    ++iLoop;
                    --it;

                    break;
                case 1:
                    sAlias = "wscript";
                    sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
                    sLanguage = "VBScript";
                    sExtend = ExtendValue(GetValue("file.patterns.wscript"));
                    iLoop = 0;

                    break;
                default:
                    fprintf(stderr, "(1003)无效的循环变量(%d)%s\n", iLoop, sAlias.c_str());
                    continue;
                }
            }
            else
            {
                sKey = Format("lexer.$(file.patterns.%s)", sAlias.c_str());
                if (!Exists(sKey))
                {
                    sKey = Format("lexer.*.%s", sAlias.c_str());
                }
            }

            if (!Exists(sKey))
            {
                fprintf(stderr, "(1004)%s %s\n", sAlias.c_str(), sKey.c_str());
                continue;
            }

            sLexer = GetValue(sKey);

            if (!IsValid(sLanguage, sLexer))
            {
                continue;
            }

            //1.2 取文件扩展名清单
            SplitString(vValue, sExtend, ';');
            sExtend.erase();
            for (auto it = vValue.begin(); it != vValue.end(); ++it)
            {
                if (0 != strncmp(it->c_str(), "*.", 2))
                {
                    continue;
                }

                sExtend.append(Format("\"%s\", ", it->c_str() + 2));
            }
            if (2 < sExtend.size())
            {
                sExtend.erase(sExtend.size() - 2);
            }

            lstLanguages.push_back(Format(
                "        \"%s\": {\n"
                "            \"file_extension\": [%s],\n"
                "            \"lexer\": \"%s\",\n",
                sLanguage.c_str(),
                sExtend.c_str(),
                sLexer.c_str()));

            //1.3 取keywords
            mapKeyword.clear();
            sKey = Format("keywords.$(file.patterns.%s)", sAlias.c_str());
            sKeyword = Trim(ExtendValue(GetValue(sKey)));
            if (!sKeyword.empty())
            {
                mapKeyword[0] = sKeyword;
            }
            for (int iKeyword = 1; iKeyword <= 8; ++iKeyword)
            {
                sKey = Format("keywords%d.$(file.patterns.%s)", iKeyword, sAlias.c_str());
                sKeyword = Trim(ExtendValue(GetValue(sKey)));
                if (!sKeyword.empty())
                {
                    mapKeyword[iKeyword] = sKeyword;
                }
            }

            lstLanguages.push_back("            \"keywords\": {\n");
            for (auto it = mapKeyword.begin(); it != mapKeyword.end();)
            {
                lstLanguages.push_back(Format("                \"%d\": \"%s\"", it->first, it->second.c_str()));

                ++it;
                if (it == mapKeyword.end())
                {
                    lstLanguages.push_back("\n");
                }
                else
                {
                    lstLanguages.push_back(",\n");
                }
            }
            lstLanguages.push_back("            }\n");
            lstLanguages.push_back("        },\n");

            //2.0 取lexers配置信息
            std::string sStyleLexer;
            for (int iLexer = 0; iLexer < 2; ++iLexer)
            {
                if (0 == iLexer)
                {
                    sStyleLexer = "*";
                }
                else if (1 == iLexer)
                {
                    sStyleLexer = sLexer;
                }
                else
                {
                    break;
                }

                if (setLexer.find(sStyleLexer) != setLexer.end())
                {
                    continue;
                }

                setLexer.insert(sStyleLexer);
                lstStyles.push_back(Format("        \"%s\": {\n", sStyleLexer.c_str()));
                lstStyles.push_back("            \"style\": {\n");

                bool bEraseComma = false;
                for (int iStyle = 0; iStyle <= 255; ++iStyle)
                {
                    sStyle = GetValue(Format("style.%s.%d", sStyleLexer.c_str(), iStyle));
                    if (sStyle.empty())
                    {
                        continue;
                    }

                    bEraseComma = true;
                    lstStyles.push_back(Format("                \"%d\": \"%s\",\n", iStyle, sStyle.c_str()));

                    std::string::size_type iEnd = 0;
                    while (true)
                    {
                        static const char c_sStyle[] = "style.";
                        sVariable = GetVariable(iEnd, sStyle, iEnd);
                        if (0 == strncmp(sVariable.c_str(), c_sStyle, sizeof(c_sStyle) - 1))
                        {
                            continue;
                        }
                        else if (iEnd == std::string::npos)
                        {
                            break;
                        }

                        setVariable.insert(sVariable);
                    }
                }

                if (bEraseComma)
                {
                    lstStyles.back().pop_back();
                    lstStyles.back().pop_back();
                    lstStyles.back().push_back('\n');
                }

                lstStyles.push_back("            }\n        },\n");
            }
        }

        if (!lstLanguages.empty())
        {
            lstLanguages.back().pop_back();
            lstLanguages.back().pop_back();
            lstLanguages.back().push_back('\n');
        }

        if (!lstStyles.empty())
        {
            lstStyles.back().pop_back();
            lstStyles.back().pop_back();
            lstStyles.back().push_back('\n');
        }

        printf("{\n    \"languages\": {\n");
        for (auto it = lstLanguages.begin(); it != lstLanguages.end(); ++it)
        {
            printf("%s", it->c_str());
        }
        printf("    },\n    \"lexers\": {\n");
        for (auto it = lstStyles.begin(); it != lstStyles.end(); ++it)
        {
            printf("%s", it->c_str());
        }
        printf("    },\n");

        for (auto it = setVariable.begin(); it != setVariable.end(); ++it)
        {
            printf("    \"%s\": \"%s\" = \"%s\",\n", it->c_str(), GetValue(*it).c_str(), ExtendValue(GetValue(*it)).c_str());
        }
    }

private:
    std::map<std::string, std::string> m_mapProp;

    bool DealLine(std::string &p_sLine, bool p_bIfTrue)
    {
        if (' ' != p_sLine[0] && '\t' != p_sLine[0])
        {
            p_bIfTrue = true;
        }

        if (0 == strncmp(p_sLine.c_str(), "if ", 3))
        {
            p_bIfTrue = 0 == strcmp(p_sLine.c_str() + 3, "PLAT_WIN");
        }
        else if (p_bIfTrue) //原逻辑有对import的处理，代码跟踪没有任何处理，直接忽略
        {
            std::string::size_type iPos = p_sLine.find_first_not_of(" \t");
            if (iPos == p_sLine.npos)
            {
                return p_bIfTrue;
            }

            if ('#' == p_sLine[iPos]) //原逻辑，“#”是当命令处理的
            {
                return p_bIfTrue;
            }

            const char *sKey = &p_sLine[iPos];
            const char *sValue = "1";

            iPos = p_sLine.find_first_of('=', iPos);
            if (iPos != p_sLine.npos)
            {
                p_sLine[iPos] = '\0';
                sValue = &p_sLine[iPos + 1];
            }

            m_mapProp.insert(std::make_pair(sKey, sValue));
        }

        return p_bIfTrue;
    }

    bool Exists(const std::string &p_sKey) const
    {
        return m_mapProp.find(p_sKey) != m_mapProp.end();
    }

    std::string ExtendValue(const std::string &p_sValue) const
    {
        std::string sResult, sVariable;
        std::string::size_type iLastEnd = 0, iEnd = 0;
        while (true)
        {
            sVariable = GetVariable(iEnd, p_sValue, iLastEnd);
            if (iEnd == std::string::npos)
            {
                sResult.append(p_sValue.substr(iLastEnd));
                return sResult;
            }

            sResult.append(p_sValue.substr(iLastEnd, iEnd - (sVariable.size() + 2) - iLastEnd));
            sResult.append(ExtendValue(GetValue(sVariable)));

            iLastEnd = iEnd + 1;
        }
    }

    std::string GetValue(const std::string &p_sKey) const
    {
        auto it = m_mapProp.find(p_sKey);
        if (it == m_mapProp.end())
        {
            return "";
        }

        return it->second;
    }

    //通过检查p_iEnd是否等于npos，可判断是否找到变量
    std::string GetVariable(std::string::size_type &p_iEnd,
        const std::string &p_sValue, std::string::size_type p_iBegin) const
    {
        p_iBegin = p_iEnd = p_sValue.find("$(", p_iBegin);
        if (p_iBegin == std::string::npos)
        {
            return "";
        }

        p_iEnd = p_sValue.find(")", p_iBegin + 2);
        if (p_iEnd == std::string::npos)
        {
            return "";
        }

        return p_sValue.substr(p_iBegin + 2, p_iEnd - (p_iBegin + 2));
    }

    void SplitString(std::vector<std::string>& p_vResult, const std::string& p_sDelimitText, const char p_cDelimiter) const
    {
        std::string::size_type nBeginPos = 0, nEndPos = 0;
        p_vResult.clear();

        if(p_sDelimitText.size() == 0)
            return;

        nEndPos = p_sDelimitText.find_first_of(p_cDelimiter, nBeginPos);
        while(nEndPos != std::string::npos)
        {
            p_vResult.push_back(p_sDelimitText.substr(nBeginPos, nEndPos - nBeginPos));
            nBeginPos = nEndPos + 1;
            nEndPos = p_sDelimitText.find_first_of(p_cDelimiter, nBeginPos);
        }
        p_vResult.push_back(p_sDelimitText.substr(nBeginPos));
    }

    std::string &Trim(std::string &p_str) const
    {
        std::string::size_type pos = p_str.find_last_not_of(" \t");
        if(pos == std::string::npos)
        {
            p_str.erase(p_str.begin(), p_str.end());
            return p_str;
        }

        p_str.erase(pos + 1);
        pos = p_str.find_first_not_of(" \t");
        if(pos != std::string::npos)
        {
            p_str.erase(0, pos);
        }

        return p_str;
    }

    int Format(std::string & p_sResult, const char * p_sFormat, const va_list & p_Arguments) const
    {
        va_list vArguments = p_Arguments;
        int nSize = _vscprintf(p_sFormat, p_Arguments);

        if(0 > nSize)
        {
            return -1;
        }

        nSize += sizeof(char); //_vscprintf返回的值不包含最后的空终止符
        std::vector<char> vResult;
        vResult.resize(nSize);
        int nRetCode = vsnprintf(&vResult[0], nSize, p_sFormat, vArguments);
        if(0 > nRetCode)
        {
            return -1;
        }
        p_sResult = &vResult[0];

        return 0;
    }

    std::string Format(const char * p_sFormat, ...) const
    {
        va_list vArg;
        va_start(vArg, p_sFormat);

        std::string sResult;
        if (0 < Format(sResult, p_sFormat, vArg))
            throw "Format Error";

        return sResult;
    }

};

int _tmain(int p_iArgc, _TCHAR* p_sArgv[])
{
    if (2 != p_iArgc)
    {
        fprintf(stderr, "使用方法：\n    GenStyle.exe Embedded.properties\n");
        return 0;
    }

    CPropSetFile psf;
    if (!psf.LoadFromFile(p_sArgv[1]))
    {
        fprintf(stderr, "文件(%s)不存在\n", p_sArgv[1]);
        return 1;
    }

    psf.GenStyle();

    return 0;
}
