//          Copyright Ferdinand Majerech 2010 - 2012.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)


/// Credits dialog.
module ice.credits;


import std.algorithm;
import std.conv;
import std.range;

import dgamevfs._;

import gui2.buttonwidget;
import gui2.guisystem;
import gui2.rootwidget;
import ice.campaign;
import ice.guiswapper;
import util.yaml;


/// Credits dialog.
class Credits: SwappableGUI
{
private:
    // YAML source of the credits.
    static immutable credits_ = 
        "ICE team:\n"
        "  - name: Ferdinand Majerech\n"
        "  - name: Dávid Horváth\n"
        "  - name: Libor Mališ\n"
        "  - name: Tomáš Nguyen\n"
        "Music: \n"
        "  - name: Osmic\n"
        "    link: http://opengameart.org/users/osmic\n"
        "  - name: Alexandr Zhelanov\n"
        "    link: http://opengameart.org/users/alexandr-zhelanov\n"
        "  - name: FoxSynergy\n"
        "    link: http://opengameart.org/users/foxsynergy\n"
        "Libraries used by ICE:\n"
        "  - name: Derelict\n"
        "  - name: SDL\n"
        "  - name: SDL-Mixer\n"
        "  - name: FreeType\n";

    // Root widget of the credits GUI.
    RootWidget creditsGUI_;

    // YAML nodes with credits data; 
    //
    // Multiple nodes can be used to e.g. add credits for a campaign, etc.
    YAMLNode[] creditsData_;

    // True when the credits are first shown after winning a campaign.
    bool wonCampaign_;

    // Reference to the GUI system; to build widgets.
    GUISystem guiSystem_;

    // Game data directory.
    VFSDir gameDir_;

public:
    /// Construct a Credits dialog.
    /// 
    /// Params: guiSystem  = A reference to the GUI system (to load widgets with).
    ///         gameDir    = Game data directory.
    ///
    /// Throws: YAMLException on a YAML parsing error.
    ///         VFSException on a filesystem error.
    ///         GUIInitException on a GUI style loading error.
    this(GUISystem guiSystem, VFSDir gameDir)
    {
        creditsData_ ~= loadYAML(credits_);
        guiSystem_ = guiSystem;
        gameDir_   = gameDir;
        generateCredits();
        super(creditsGUI_);
    }

    /// Called when the player wins a campaign.
    ///
    /// Params:  data = Data describing the campaign victory.
    void wonCampaign(CampaignWinData data)
    {
        wonCampaign_ = true;
        creditsData_ ~= data.campaignCredits;
        generateCredits();
    }

private:
    /// Called when the "close" button is clicked.
    void atClose()
    {
        // Remove any campaign credits.
        creditsData_ = creditsData_[0 .. 1];
        swapGUI_("ice");
    }

    /// Generate credits widgets.
    ///
    /// Throws: GUIInitException on failure.
    ///         YAMLException on a YAML parsing error.
    ///         VFSException on a filesystem error.
    void generateCredits()
    {
        auto styleFile = gameDir_.file("gui/infoStyle.yaml");
        auto styleYAML = loadYAML(styleFile);
        auto stylesheet = Stylesheet(styleYAML, "gui/infoStyle.yaml");
        auto builder = WidgetBuilder(guiSystem_, &stylesheet);

        // Credits generation parameters.

        // Heights of widgets and gaps between them.
        const subSectionGap       = 6;
        const subSectionHeader    = 18;
        const subSectionHeaderGap = 5;
        const creditName          = 14;
        const creditNameGap       = 1;
        const creditLink          = 12;
        const creditGap           = 4;

        const headerHeightStr     = to!string(subSectionHeader);
        const nameHeightStr       = to!string(creditName);
        const linkHeightStr       = to!string(creditLink);

        // Y offset of the current subsection.
        uint yOffset = 48;
        // Y offset within current subsection.
        uint subYOffset  = 0;

        // Determine height of a credits subsection.
        uint subSectionHeight(ref YAMLNode subSection)
        {
            uint height = subSectionHeader + subSectionHeaderGap;
            foreach(ref YAMLNode credit; subSection)
            {
                if(credit.containsKey("name"))
                {
                    height += creditName;
                    height += creditNameGap;
                }
                if(credit.containsKey("link"))
                {
                    height += creditLink;
                }
                height += creditGap;
            }
            height += subSectionGap;
            return height;
        }

        // Generate a single credits item.
        void buildCreditsItem(ref WidgetBuilder b, ref YAMLNode credit)
        {
            if(credit.containsKey("name"))
            {
                auto subYOffsetStr = to!string(subYOffset);
                const name = credit["name"].as!string;
                b.buildWidget!"label"((ref WidgetBuilder b)
                {
                    b.layout("{x: pLeft, y: 'pTop + " ~ subYOffsetStr ~ "'," ~ 
                             " w: pWidth, h: " ~ nameHeightStr ~ "}");
                    b.widgetParams("{text: '" ~ name ~ "'}");
                });
                subYOffset += creditName;
                subYOffset += creditNameGap;
            }
            if(credit.containsKey("link"))
            {
                auto subYOffsetStr = to!string(subYOffset);
                subYOffset += creditLink;
                const link = credit["link"].as!string;
                b.buildWidget!"label"((ref WidgetBuilder b)
                {
                    b.styleClass = "link";
                    b.layout("{x: pLeft, y: 'pTop + " ~ subYOffsetStr ~ "'," ~ 
                             " w: pWidth, h: " ~ linkHeightStr ~ "}");
                    b.widgetParams("{text: '" ~ link ~ "'}");
                });
            }

            subYOffset += creditGap;
        }

        // Generate a subsection of the credits.
        void buildSubSection
            (ref WidgetBuilder b, const string subSectionName, ref YAMLNode subSection)
        {
            subYOffset       = 0;
            const height     = subSectionHeight(subSection);
            const heightStr  = to!string(height);
            const yOffsetStr = to!string(yOffset);
            // (Invisible) container of the subsection.
            b.buildWidget!"container"((ref WidgetBuilder b)
            {
                b.styleClass = "creditsSubSection";
                auto subYOffsetStr = to!string(subYOffset);
                b.layout("{x: 'pLeft + 16', y: 'pTop + " ~ yOffsetStr ~ "'," ~
                         " w: 'pWidth - 32', h: " ~ heightStr ~ "}");
                // Subsection header.
                b.buildWidget!"label"((ref WidgetBuilder b)
                {
                    b.styleClass = "sectionHeader";
                    b.layout("{x: pLeft, y: 'pTop + " ~ subYOffsetStr ~ "'," ~ 
                             " w: pWidth, h: " ~ headerHeightStr ~ "}");
                    b.widgetParams("{text: '" ~ subSectionName ~ "'}");
                });
                subYOffset += subSectionHeader + subSectionHeaderGap;

                // Credits items themselves.
                foreach(ref YAMLNode credit; subSection)
                {
                    buildCreditsItem(b, credit);
                }

            });
            yOffset += height;
        }

        // Root credits widget (main container).
        builder.buildWidget!"root"((ref WidgetBuilder b)
        {
            b.layoutManager("boxManual");
            b.layout("{x: 'pLeft + 96', y: 'pTop + 16'," ~ 
                     " w: 'pWidth - 192', h: 'pHeight - 32'}");

            // Close button.
            b.buildWidget!"button"((ref WidgetBuilder b)
            {
                b.name = "close";
                b.layout("{x: 'pLeft + pWidth / 2 - 72', y: 'pBottom - 32'," ~
                        " w: 144, h: 24}");
                b.widgetParams("{text: Close}");
            });

            // "Credits"/"The End" (after winning a campaign) label.
            b.buildWidget!"label"((ref WidgetBuilder b)
            {
                b.styleClass = "header";
                b.layout("{x: 'pLeft + pWidth / 2 - 64', y: 'pTop + 8'," ~ 
                         " w: 128, h: 24}");
                b.widgetParams(wonCampaign_ ? "{text: The End.}" : "{text: Credits}");
            });

            // Credits themselves.
            foreach(ref section; creditsData_.retro)
            {
                foreach(string subSectionName, ref YAMLNode subSection; section)
                {
                    buildSubSection(b, subSectionName, subSection);
                }
            }
        });


        creditsGUI_ = cast(RootWidget)builder.builtWidgets.back;
        creditsGUI_.close!ButtonWidget.connect(&atClose);
        rootWidget = creditsGUI_;
    }
}
